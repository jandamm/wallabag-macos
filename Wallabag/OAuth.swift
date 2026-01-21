//
//  Token.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 24.01.21.
//

import Foundation

struct OAuth: Codable  {
	typealias Credentials = API.Credentials
	static let key: String = "oauth"
	let credentials: Credentials
	let token: Token
	let date: Date

	enum Error: Swift.Error {
		case noAuth
		case http(Swift.Error)
	}

	func request(for pathComponent: String) -> URLRequest {
		var request = URLRequest(url: credentials.server.appendingPathComponent(pathComponent))
		request.addValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
		return request
	}

	struct Token: Codable {
		let access_token: String
		let expires_in: TimeInterval
		let token_type: String
		let refresh_token: String
	}

	var isExpired: Bool {
		date.addingTimeInterval(token.expires_in) < Date()
	}

	struct Request: Encodable {
		let grant_type: GrantType
		let client_id: String
		let client_secret: String
		let username: String?
		let password: String?
		let refresh_token: String?

		init(credentials: Credentials, password: String) {
			grant_type = .password
			client_id = credentials.clientId
			client_secret = credentials.clientSecret
			username = credentials.username
			self.password = password

			refresh_token = nil
		}

		init(oAuth: OAuth) {
			grant_type = .refresh_token
			client_id = oAuth.credentials.clientId
			client_secret = oAuth.credentials.clientSecret
			refresh_token = oAuth.token.refresh_token

			username = nil
			password = nil
		}

		enum GrantType: String, Encodable {
			case password, refresh_token
		}
	}
}
