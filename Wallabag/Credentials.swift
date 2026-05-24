import Foundation

public extension API {
    // Make the struct public
    struct Credentials: Codable {
        // Make all properties public
        public let server: URL
        public let clientId: String
        public let clientSecret: String
        public let username: String
        
        // Make the initializer public
        public init?(
            server: String,
            clientId: String,
            clientSecret: String,
            username: String
        ) {
            // This logic removes any trailing slashes from the server URL
            var processedServer = server
            while processedServer.last == "/" {
                processedServer = String(processedServer.dropLast())
            }
            
            guard
                let serverURL = URL(string: processedServer),
                !clientId.isEmpty,
                !clientSecret.isEmpty,
                !username.isEmpty
            else {
                return nil
            }
            self.server = serverURL
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
