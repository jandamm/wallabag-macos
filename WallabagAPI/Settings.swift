//
//  Settings.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 24.01.21.
//

import Foundation

public extension API {
	enum Settings {}
}

public extension API.Settings {
	static var showSuccessMessage: Bool {
		get { defaults.bool(forKey: "showSuccessMessage") }
		set { defaults.setValue(newValue, forKey: "showSuccessMessage") }
	}
}
