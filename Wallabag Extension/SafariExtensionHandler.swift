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
		// This method will be called when your toolbar item is clicked.
		NSLog("The extension's toolbar item was clicked")
		getWebsite(of: window) { website in
			guard let website = website else { return }
			API.save(website: website) { success in
				print(success)
			}
		}
	}

	override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
		// This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
		getWebsite(of: window) {
			validationHandler($0 != nil, "")
		}
	}

	override func popoverViewController() -> SFSafariExtensionViewController {
		return SafariExtensionViewController.shared
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
