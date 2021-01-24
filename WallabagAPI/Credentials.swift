//
//  Credentials.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 23.01.21.
//

import Foundation

public struct Credentials: Codable {
	let server: String
	let clientId: String
	let clientSecret: String
	let username: String

	public init(
		server: String,
		clientId: String,
		clientSecret: String,
		username: String
	) {
		self.server = server
		self.clientId = clientId
		self.clientSecret = clientSecret
		self.username = username
	}
}
