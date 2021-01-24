//
//  Credentials.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 23.01.21.
//

import Foundation

extension API {
	public struct Credentials: Codable {
		public let server: URL
		public let clientId: String
		public let clientSecret: String
		public let username: String

		public init?(
			server: String,
			clientId: String,
			clientSecret: String,
			username: String
		) {
			self.server = URL(string: server)!
			self.clientId = clientId
			self.clientSecret = clientSecret
			self.username = username
		}
	}
}

public extension API.Credentials {
	static var current: API.Credentials? {
		API.oAuth?.credentials
	}
}
