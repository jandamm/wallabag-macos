//
//  Telemetry.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 26.03.24.
//

import Foundation
import StoreKit

public extension API {
	enum AppStoreReview {}
}

public extension API.AppStoreReview {
	/// Number of days to wait for the next request for an AppStore Review
	private static let requestIntervalDays: Int = 28

	/// Requests when the last review request was not within the last `requestIntervalDays`.
	static func request() {
		guard lastReviewRequest.timeIntervalSinceNow < -(TimeInterval(requestIntervalDays) * 24 * 3600) else { return }

		SKStoreReviewController.requestReview()
		lastReviewRequest = Date()
	}

	private static var lastReviewRequest: Date {
		get {
			guard let raw = defaults.string(forKey: "lastReviewRequest"),
						let date = Internal.simpleDateFormatter.date(from: raw)
			else {
				return Date(timeIntervalSince1970: 0) // Never
			}
			return date
		}
		set {
			defaults.set(
				Internal.simpleDateFormatter.string(from: newValue),
				forKey: "lastReviewRequest"
			)
		}
	}
}
