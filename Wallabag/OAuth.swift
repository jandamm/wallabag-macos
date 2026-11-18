import Foundation

// Make the struct public
public struct OAuth: Codable {
    public typealias Credentials = API.Credentials
    static let key: String = "oauth"

    // Make properties public
    public let credentials: Credentials
    public let token: Token
    public let date: Date

    // From upstream: error type used by API auth-failure paths.
    public enum Error: Swift.Error {
        case noAuth
        case http(Swift.Error)
    }

    // We need a public initializer
    public init(credentials: Credentials, token: Token, date: Date) {
        self.credentials = credentials
        self.token = token
        self.date = date
    }

    // Make method public
    public func request(for pathComponent: String) -> URLRequest {
        var request = URLRequest(url: credentials.server.appendingPathComponent(pathComponent))
        request.addValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // Make nested struct and its properties public
    public struct Token: Codable {
        public let access_token: String
        public let expires_in: TimeInterval
        public let token_type: String
        public let refresh_token: String
    }

    // Make property public
    public var isExpired: Bool {
        date.addingTimeInterval(token.expires_in) < Date()
    }

    // Make nested struct public
    public struct Request: Encodable {
        // Make properties public
        public let grant_type: GrantType
        public let client_id: String
        public let client_secret: String
        public let username: String?
        public let password: String?
        public let refresh_token: String?

        // Make initializers public
        public init(credentials: Credentials, password: String) {
            self.grant_type = .password
            self.client_id = credentials.clientId
            self.client_secret = credentials.clientSecret
            self.username = credentials.username
            self.password = password
            self.refresh_token = nil
        }

        public init(oAuth: OAuth) {
            self.grant_type = .refresh_token
            self.client_id = oAuth.credentials.clientId
            self.client_secret = oAuth.credentials.clientSecret
            self.refresh_token = oAuth.token.refresh_token
            self.username = nil
            self.password = nil
        }

        // Make enum public
        public enum GrantType: String, Encodable {
            case password, refresh_token
        }
    }
}
