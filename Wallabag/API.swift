import AppKit
import Foundation
import KeychainAccess

private let teamIdentifier = "6N9Z26P656"
private let bundleIdentifier = "de.jandamm.pri.wallabag"
let defaults = UserDefaults(suiteName: "group.\(bundleIdentifier)")!
let keychain = Keychain(
	service: "\(bundleIdentifier).SharedKeychain",
	accessGroup: "\(teamIdentifier).\(bundleIdentifier).SharedKeychain"
)
.synchronizable(true)

public enum API {}

let session = URLSession.shared
let decoder = JSONDecoder()
let encoder = JSONEncoder()

public extension API {
	enum Error: Swift.Error {
		case oAuth, http(statusCode: Int), unknown
	}

	static func authenticate(credentials: Credentials, password: String, completion: @escaping (Bool) -> Void) {
		getOAuth(request: OAuth.Request(credentials: credentials, password: password), credentials: credentials) {
			completion($0 != nil)
		}
	}

	static func save(website: Website, completion: @escaping (Result<Void, Error>) -> Void) {
		getRefreshToken { oAuth in
			guard let oAuth = oAuth else {
				completion(.failure(.oAuth))
				return
			}

			do {
				var request = oAuth.request(for: "api/entries.json")
				request.httpMethod = "POST"
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")

				request.httpBody = try encoder.encode(website)

				session.dataTask(with: request) { _, response, _ in
					switch (response as? HTTPURLResponse)?.statusCode {
					case let statusCode? where (200 ..< 300).contains(statusCode):
						completion(.success(()))
					case let statusCode?:
						completion(.failure(.http(statusCode: statusCode)))
					case .none:
						completion(.failure(.unknown))
					}
				}.resume()
			} catch {
				completion(.failure(.unknown))
			}
		}
	}

	static func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
		getRefreshToken { completion($0 != nil) }
	}

	static func openApp() {
		NSWorkspace.shared.open(URL(string: "wallabag://")!)
	}
}

extension API {
	// TODO: Improve logic and add caching?
	static var oAuth: OAuth? {
		get {
			(try? keychain.getData(OAuth.key, ignoringAttributeSynchronizable: false))
				.flatMap { try? decoder.decode(OAuth.self, from: $0) }
		}
		set {
			if let data = try? newValue.map(encoder.encode) {
				try? keychain.set(data, key: OAuth.key, ignoringAttributeSynchronizable: false)
			} else {
				try? keychain.remove(OAuth.key, ignoringAttributeSynchronizable: false)
			}
		}
	}

	static func getRefreshToken(completion: @escaping (OAuth?) -> Void) {
		guard let auth = oAuth, auth.isExpired else {
			completion(oAuth)
			return
		}
		getOAuth(request: .init(oAuth: auth), credentials: auth.credentials, completion: completion)
	}

	private static func getOAuth(request oAuthRequest: OAuth.Request, credentials: Credentials, completion: @escaping (OAuth?) -> Void) {
		do {
			var request = URLRequest(url: credentials.server.appendingPathComponent("oauth/v2/token"))
			request.httpMethod = "POST"
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try encoder.encode(oAuthRequest)

			session.dataTask(with: request) { data, _, _ in
				oAuth = data
					.flatMap { try? decoder.decode(OAuth.Token.self, from: $0) }
					.map { OAuth(credentials: credentials, token: $0, date: Date()) }
				completion(oAuth)
			}.resume()
		} catch {
			completion(nil)
		}
	}
}
