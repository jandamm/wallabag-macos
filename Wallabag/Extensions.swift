//
//  Extensions.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 05.11.24.
//

public extension Result {
	var value: Success? {
		switch self {
		case let .success(value): value
		case .failure: nil
		}
	}

	var isSuccess: Bool {
		value != nil
	}
}
