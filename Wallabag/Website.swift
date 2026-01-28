//
//  Website.swift
//  WallabagAPI
//
//  Created by Jan Dammshäuser on 23.01.21.
//

import Foundation

public struct Website: Encodable {
	public let url: URL
	public let title: String?
	var tags: String?
	public var archive: Archive = .unread
	public var starred: Starred = .unstarred

	public init(url: URL) {
		self.init(url: url, title: nil)
	}

	public init(url: URL, title: String?) {
		self.url = url
		self.title = title
	}

	public var allTags: [String] {
		get { tags?.split(separator: ",").map(String.init) ?? [] }
		set { tags = newValue.joined(separator: ",") }
	}

	public enum Archive: Int, Encodable {
		case unread, archive
	}

	public enum Starred: Int, Encodable {
		case unstarred, starred
	}
}
