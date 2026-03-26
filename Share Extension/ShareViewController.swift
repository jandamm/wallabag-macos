//
//  ShareViewController.swift
//  Share Extension
//
//  Created by Jan Dammshäuser on 26.03.26.
//

import Cocoa
import Wallabag

class ShareViewController: NSViewController {
	override func loadView() {
		let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
		self.view = view

		let progressIndicator = NSProgressIndicator()
		let statusLabel = NSTextField(labelWithString: "Saving link...")

		progressIndicator.style = .spinning
		progressIndicator.translatesAutoresizingMaskIntoConstraints = false
		progressIndicator.isDisplayedWhenStopped = false

		statusLabel.translatesAutoresizingMaskIntoConstraints = false
		statusLabel.alignment = .center
		statusLabel.textColor = .secondaryLabelColor

		view.addSubview(progressIndicator)
		view.addSubview(statusLabel)

		NSLayoutConstraint.activate([
			progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),

			statusLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 12),
			statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
		])

		progressIndicator.startAnimation(nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
		      let provider = item.attachments?.first,
		      provider.hasItemConformingToTypeIdentifier("public.url")
		else {
			fail(message: "Could not get URL from extension item.")
			return
		}

		_ = provider.loadObject(ofClass: URL.self) { [weak self] url, error in
			guard let url else {
				if let error = error {
					self?.fail(error)
				} else {
					self?.fail(message: "Could not read URL from extension item.")
				}
				return
			}
			API.save(website: .init(url: url)) { result in
				switch result {
				case .success:
					self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
				case let .failure(.oAuth(error)):
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						API.openApp()
					}
					fallthrough
				case let .failure(error as any Error):
					self?.fail(error)
				}
			}
		}
	}

	private func fail(message: String) {
		fail(
			NSError(
				domain: "de.jandamm.error",
				code: 1234,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		)
	}

	private func fail(_ error: Error) {
		DispatchQueue.main.async { [self] in
			presentError(error)
			extensionContext?.cancelRequest(withError: error)
		}
	}
}
