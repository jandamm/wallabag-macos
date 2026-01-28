//
//  SafariExtensionHandler.swift
//  Wallabag Extension
//
//  Created by Jan Dammshäuser on 22.01.21.
//  Context menu by CrispStrobe on 22.06.25.
//

import SafariServices
import Wallabag

class SafariExtensionHandler: SFSafariExtensionHandler {

	// Create a shared instance so the popover can access its methods
	static let shared = SafariExtensionHandler()

	// Call the popover (clicking on the extension Icon shall show settings option)
	override func popoverViewController() -> SFSafariExtensionViewController {
		return PopoverViewController.shared
	}


	override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
		switch command {
		case "save-current-page": // For "Save Page", the existing logic already handles feedback.
			handleSaveCurrentPage(in: page)
		case "save-linked-url":
			sendWithCallback(to: page, name: "getLinkedURL") { raw in
				guard let rawURL = (raw as? [String: String])?["url"], let url = URL(string: rawURL) else { return }
				self.save(website: Website(url: url))
			}
		case "save-all-links":
			sendWithCallback(to: page, name: "showLinkSelectorUI") { raw in
				guard let rawURLs = (raw as? [String: [String]])?["urls"] else { return }
				let urls = rawURLs.compactMap(URL.init(string:))
				self.save(websites: urls.map(Website.init))
			}
		default:
			print("Not implemented")
		}
	}

	override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]? = nil) {
		//updateToolbarBadge(with: pendingCallbacks[messageName] == nil ? "no cb" : "has")
		guard let callback = Self.pendingCallbacks.removeValue(forKey: messageName) else { return }
		callback(userInfo)
	}

	private static var pendingCallbacks: [String: (Any?) -> Void] = [:]

	// Usage in JS:
	// safari.extension.dispatchMessage(event.message.callbackId, {
	//   ...
	// });
	private func sendWithCallback(to page: SFSafariPage, name: String, userInfo: [String: Any] = [:], callback: @escaping (Any?) -> Void) {
		let callbackId = UUID().uuidString
		Self.pendingCallbacks[callbackId] = callback

		var info = userInfo
		info["callbackId"] = callbackId

		page.dispatchMessageToScript(withName: name, userInfo: info)
	}

	func handleSaveCurrentPage(in page: SFSafariPage) {
		getWebsite(of: page) { website in
			guard let website = website else { return }
			self.save(website: website)
		}
	}

	func save(website: Website) {
		save(websites: [website])
	}

	func save(websites: [Website]) {
		guard !websites.isEmpty else { return }

		let group = DispatchGroup()
		var remaining = websites.count
		var errors = 0
		var result: Result<Void, API.Error>?

		updateToolbarBadge(with: remaining == 1 ? "..." : "\(remaining)")

		for website in websites {
			group.enter()
			API.save(website: website) { res in
				remaining -= 1
				if remaining > 0 {
					self.updateToolbarBadge(with: "\(remaining)")
				}

				if result == nil || result?.isSuccess == true {
					result = res // Prefer Errors over success
				}
				if result?.isSuccess == false {
					errors += 1
				}
				group.leave()
			}
		}

		group.notify(queue: .main) {
			guard let result else { return }
			self.handleSaveResponse(result: result, errorCount: errors)
		}
	}

	func handleSaveResponse(result: Result<Void, API.Error>, errorCount: Int) {
		switch result {
		case .success:
			updateToolbarBadge(with: "Ok", autoClear: true)
		case .failure(.oAuth):
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
				API.openApp()
			}
			fallthrough
		case .failure:
			updateToolbarBadge(with: errorCount > 1 ? "E: #\(errorCount)" : "Error", autoClear: true)
		}
	}

	override func toolbarItemClicked(in window: SFSafariWindow) {
		window.getActiveTab { tab in
			tab?.getActivePage { page in
				guard let page = page else { return }; self.handleSaveCurrentPage(in: page)
			}
		}
	}

	override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
		validationHandler(true, "");
	}

	func updateToolbarBadge(with text: String?, autoClear: Bool = false) {
		SFSafariApplication.getActiveWindow { window in
			window?.getToolbarItem { item in
				item?.setBadgeText(text)
				if autoClear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { item?.setBadgeText(nil) } }
			}
		}
	}

	func getWebsite(of page: SFSafariPage, callback: @escaping (Website?) -> Void) {
		page.getPropertiesWithCompletionHandler { properties in
			callback(properties?.url.map { Website(url: $0, title: properties?.title) })
		}
	}
}

