//
//  Telemetry.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 26.03.24.
//

import Foundation
import TelemetryClient

public extension API {
	enum Telemetry {}
}

public extension API.Telemetry {
	private static let config: TelemetryManagerConfiguration = {
		let config = TelemetryManagerConfiguration(appID: appID)
		config.sendNewSessionBeganSignal = false
		return config
	}()
	// TelemetryDeck completely anonymizes the user string.
	// This is just to allow aggregation about how many users use the extension and to which extent.
	private static var user: String? {
		guard let credentials = API.oAuth?.credentials else { return nil }
		return credentials.server.absoluteString + credentials.username
	}

	static func savedWebsite() { send("savedWebsite") }

	static func launchedApp() { send("applicationDidLaunch") }
	static func authenticate(success: Bool) { send("authenticate", info: ["success": String(describing: success)]) }

	static func tipTapped(product: String, initialTip: Bool) { send("tipTapped", info: ["product": product, "intialTip": String(String(describing: initialTip))]) }
	static func tipSuccessful(product: String, initialTip: Bool) { send("tipSuccessful", info: ["product": product, "intialTip": String(String(describing: initialTip))]) }

	private static func send(_ signal: String, info: [String: String]? = nil) {
		#if DEBUG
		print("Telemetry", signal, info ?? [:])
		#else
		guard !appID.isEmpty else {
			assertionFailure("No appID for TelemetryDeck set.")
			return
		}
		initialize()
		TelemetryDeck.signal(
			signal,
			parameters: info ?? [:],
			customUserID: user
		)
		#endif
	}

	private static var cachedSessionID: StoredSessionID?
	/// SessionID newly generated every day.
	private static var sessionID: UUID {
		guard let cachedSessionID, Calendar.current.isDateInToday(cachedSessionID.date) else {
			let new = StoredSessionID.current
			cachedSessionID = new
			return new.uuid
		}
		return cachedSessionID.uuid
	}

	private static func initialize() {
		config.sessionID = sessionID // Make sure to always use my sessionID
		guard !TelemetryManager.isInitialized else { return }
		config.sendNewSessionBeganSignal = false
		TelemetryDeck.initialize(config: config)
	}
}

private struct StoredSessionID: Codable {
	let date: Date
	let uuid: UUID

	static var current: Self {
		guard let data = defaults.data(forKey: "sessionID"),
					let stored = try? Internal.decoder.decode(Self.self, from: data),
					Calendar.current.isDateInToday(stored.date) else {
			let new = Self(date: Date(), uuid: UUID())
			if let data = try? Internal.encoder.encode(new) {
				defaults.set(data, forKey: "sessionID")
			}
			return new
		}
		return stored
	}
}
