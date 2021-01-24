//
//  Website.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 23.01.21.
//

import Foundation

public struct Website: Encodable {
	let url: URL
	let title: String?
	var tags: String?
	var archive: Int = 0
	var starred: Int = 0

	public init(url: URL, title: String?) {
		self.url = url
		self.title = title
	}

	public var allTags: [String] {
		get { tags?.split(separator: ",").map(String.init) ?? [] }
		set { tags = newValue.joined(separator: ",") }
	}

	public var isArchived: Bool {
		get { archive == 1 }
		set { archive = newValue ? 1 : 0 }
	}

	public var isStarred: Bool {
		get { starred == 1 }
		set { starred = newValue ? 1 : 0 }
	}
}
