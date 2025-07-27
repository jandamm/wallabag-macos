import AppKit
import Foundation
import KeychainAccess

let defaults = UserDefaults(suiteName: AppCredentials.userDefaultsGroup)!
let keychain = Keychain(
	service: AppCredentials.keychainService,
	accessGroup: AppCredentials.keychainAccessGroup
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

	static func authenticate(credentials: Credentials, password: String, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
		getOAuth(request: OAuth.Request(credentials: credentials, password: password), credentials: credentials) {
			completion($0.map { _ in () })
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

	static var jsCredentials: [String: String]? {
		guard let oAuth, !oAuth.isExpired else { return nil }
		return [
			"token": oAuth.token.access_token,
			"serverURL": oAuth.credentials.server.absoluteString
		]
	}
}

extension API {
	// TODO: Improve logic and add caching?
	static var oAuth: OAuth? {
		get {
			(try? keychain.getData(OAuth.key))
				.flatMap { try? decoder.decode(OAuth.self, from: $0) }
		}
		set {
			if let data = try? newValue.map(encoder.encode) {
				try? keychain.set(data, key: OAuth.key)
			} else {
				try? keychain.remove(OAuth.key)
			}
		}
	}

	static func getRefreshToken(completion: @escaping (OAuth?) -> Void) {
		guard let auth = oAuth, auth.isExpired else {
			completion(oAuth)
			return
		}
		getOAuth(request: .init(oAuth: auth), credentials: auth.credentials) { completion($0.value) }
	}

	private static func getOAuth(request oAuthRequest: OAuth.Request, credentials: Credentials, completion: @escaping (Result<OAuth, Swift.Error>) -> Void) {
		do {
			var request = URLRequest(url: credentials.server.appendingPathComponent("oauth/v2/token"))
			request.httpMethod = "POST"
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try encoder.encode(oAuthRequest)

			session.dataTask(with: request) { data, _, error in
				do {
					guard let data else {
						throw error ?? NSError(domain: "unknown", code: -1)
					}
					let newAuth = OAuth(
						credentials: credentials,
						token: try decoder.decode(OAuth.Token.self, from: data),
						date: Date()
					)
					oAuth = newAuth
					completion(.success(newAuth))
				} catch {
					oAuth = nil
					completion(.failure(error))
				}
			}.resume()
		} catch {
			completion(.failure(error))
		}
	}
}
