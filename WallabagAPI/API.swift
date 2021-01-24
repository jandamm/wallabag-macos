//
//  API.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 23.01.21.
//

import Foundation
import KeychainAccess

private let appGroup = "group.de.jandamm.ent.wallabag"
let defaults = UserDefaults(suiteName: appGroup)!
let keychain = Keychain(service: "it.wallabag", accessGroup: appGroup)

public enum API {}

let session = URLSession.shared
let decoder = JSONDecoder()
let encoder = JSONEncoder()

public extension API {
	static func authenticate(credentials: Credentials, password: String, completion: @escaping (Bool) -> Void) {
		getOAuth(request: OAuth.Request(credentials: credentials, password: password), credentials: credentials) {
			completion($0 != nil)
		}
	}

	static func save(website: Website, completion: @escaping (Bool) -> Void) {
		refreshTokenIfNeeded { oAuth in
			guard
				let oAuth = oAuth,
				let url = URL(string: "\(oAuth.credentials.server)/api/entries.json")
			else {
				completion(false)
				return
			}
			
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			oAuth.authorize(request: &request)
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try! encoder.encode(website)

			session.dataTask(with: request) { _, response, _ in
				completion((response as? HTTPURLResponse)?.statusCode == 200)
			}.resume()
		}
	}

	static func openApp() {
		// open main app
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

	static func refreshTokenIfNeeded(completion: @escaping (OAuth?) -> Void) {
		guard let auth = oAuth, auth.isExpired else {
			completion(oAuth)
			return
		}
		getOAuth(request: auth.request(), credentials: auth.credentials, completion: completion)
	}

	private static func getOAuth(request oAuthRequest: OAuth.Request, credentials: Credentials, completion: @escaping (OAuth?) -> Void) {
		guard let url = URL(string: "\(credentials.server)/oauth/v2/token") else {
			completion(nil)
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try! encoder.encode(oAuthRequest)

		session.dataTask(with: request) { data, response, error in
			oAuth = data
				.flatMap { try? decoder.decode(OAuth.Token.self, from: $0) }
				.map { OAuth(credentials: credentials, token: $0, date: Date()) }
			completion(oAuth)
		}.resume()
	}
}
