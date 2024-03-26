//
//  Helper.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 26.03.24.
//

import Foundation

enum Internal {}

extension Internal {
	/// Formats a date as yyyyMMdd
	static let simpleDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd"
		return formatter
	}()
}

