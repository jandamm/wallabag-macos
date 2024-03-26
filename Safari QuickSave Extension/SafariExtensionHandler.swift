//
//  SafariExtensionHandler.swift
//  Wallabag Extension
//
//  Created by Jan Dammshäuser on 22.01.21.
//

import SafariServices
import Wallabag

class SafariExtensionHandler: SFSafariExtensionHandler {
	override func toolbarItemClicked(in window: SFSafariWindow) {
		getWebsite(of: window) { website in
			guard let website = website else { return }
			window.getToolbarItem { item in
				item?.setBadgeText("...")
				item?.setEnabled(false)
				API.save(website: website) { result in
					item?.setEnabled(true)
					switch result {
					case .success:
						API.AppStoreReview.request()

						API.Telemetry.savedWebsite()

						item?.setBadgeText(
							API.Settings.showSuccessMessage
							? "Ok"
							: nil
						)
					case .failure(.oAuth):
						API.openApp()
					case let .failure(.http(statusCode)):
						item?.setBadgeText("E\(statusCode)")
					case .failure(.unknown):
						item?.setBadgeText("Error")
					}

					DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
						item?.setBadgeText(nil)
					}
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
