//
//  Statistics.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 26.03.24.
//

import Foundation

public extension API {
	enum Statistics {}
}

public extension API.Statistics {
	private static var rawValue: [String: Int] {
		get { defaults.dictionary(forKey: "statisticsRaw") as? [String: Int] ?? [:] }
		set { defaults.set(newValue, forKey: "statisticsRaw") }
	}

	static func savedWebsite() {
		rawValue[dateKey, default: 0] += 1
	}

	private static var dateKey: String {
		Internal.simpleDateFormatter.string(from: Date())
	}
}
