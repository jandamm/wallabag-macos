import Foundation

public extension API {
	struct Credentials: Codable {
		public let server: URL
		public let clientId: String
		public let clientSecret: String
		public let username: String
	}
}

public extension API.Credentials {
	init?(
		server: String,
		clientId: String,
		clientSecret: String,
		username: String
	) {
		guard
			let server = URL(string: server.removingTrailing("/")),
			!clientId.isEmpty,
			!clientSecret.isEmpty,
			!username.isEmpty
		else {
			return nil
		}
		self.server = server
		self.clientId = clientId
		self.clientSecret = clientSecret
		self.username = username
	}

	static var current: API.Credentials? {
		API.oAuth?.credentials
	}
}

private extension String {
	func removingTrailing(_ character: Character) -> String {
		String(
			drop { $0 == character }
		)
	}
}
