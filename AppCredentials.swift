enum AppCredentials {
	static let appName = "Wallamac"
	static let bundleIdentifier = "de.jandamm.wallabagmac"
	static let safariBundleIdentifier = "de.jandamm.wallabagmac.safari"
	static let teamIdentifier = "7TCLF98BX7"

	static var userDefaultsGroup: String { "group.\(bundleIdentifier)" }
	static var keychainService: String { "\(bundleIdentifier).SharedKeychain" }
	static var keychainAccessGroup: String { "\(teamIdentifier).\(bundleIdentifier).SharedKeychain" }
}
