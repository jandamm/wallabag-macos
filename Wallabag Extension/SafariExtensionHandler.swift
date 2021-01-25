//
//  SafariExtensionHandler.swift
//  Wallabag Extension
//
//  Created by Jan Dammshäuser on 22.01.21.
//

import SafariServices
import WallabagAPI

class SafariExtensionHandler: SFSafariExtensionHandler {
	override func toolbarItemClicked(in window: SFSafariWindow) {
		getWebsite(of: window) { website in
			guard let website = website else { return }
			API.save(website: website) { result in
				switch result {
				case .success:
					break
				case .failure(.oAuth):
					API.openApp()
				case let .failure(.http(statusCode)):
					print("Error, statusCode: \(statusCode)")
				case .failure(.unknown):
					print("Error.")
				}
			}
		}
	}

	override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
		getWebsite(of: window) {
			validationHandler($0 != nil, "")
		}
	}
}

private func getWebsite(of window: SFSafariWindow, callback: @escaping (Website?) -> Void) {
	window.getActiveTab {
		$0?.getActivePage {
			$0?.getPropertiesWithCompletionHandler { properties in
				callback(
					properties?.url.map { Website(url: $0, title: properties?.title) }
				)
			}
		}
	}
}
