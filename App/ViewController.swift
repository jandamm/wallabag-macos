//
//  ViewController.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 22.01.21.
//

import Cocoa
import SafariServices.SFSafariApplication
import SafariServices.SFSafariExtensionManager
import Wallabag
import UI

let appName = "Wallabag"
let bundleIndentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] ?? "de.jandamm.pri.wallabag"
let extensionBundleIdentifier = "\(bundleIndentifier).SafariQuickSave"

class ViewController: NSViewController {

	@IBOutlet private var authLabel: NSTextField!
	@IBOutlet private var serverTextField: TextField!
	@IBOutlet private var clientIdTextField: TextField!
	@IBOutlet private var clientSecretTextField: TextField!
	@IBOutlet private var usernameTextField: TextField!
	@IBOutlet private var passwordTextField: SecureTextField!

	@IBOutlet private var appNameLabel: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.appNameLabel.stringValue = "\(appName)'s extension is currently unknown."
		self.authLabel.stringValue = AuthLabel.checking

		let credentials = API.Credentials.current
		self.serverTextField.stringValue = credentials?.server.absoluteString ?? "https://app.wallabag.it"
		self.clientIdTextField.stringValue = credentials?.clientId ?? ""
		self.clientSecretTextField.stringValue = credentials?.clientSecret ?? ""
		self.usernameTextField.stringValue = credentials?.username ?? ""

		API.refreshTokenIfNeeded { success in
			DispatchQueue.main.async {
				self.setAuthResponse(success)
			}
		}

		SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
			guard let state = state, error == nil else { return }

			DispatchQueue.main.async {
				self.appNameLabel.stringValue = state.isEnabled
					? "\(appName)'s extension is currently on."
					: "\(appName)'s extension is currently off. You can turn it on in Safari Extensions preferences."
			}
		}
	}

	@IBAction private func validateCredentials(_ sender: NSButton?) {
		authLabel.stringValue = AuthLabel.checking
		guard
			let credentials = API.Credentials(
				server: serverTextField.stringValue,
				clientId: clientIdTextField.stringValue,
				clientSecret: clientSecretTextField.stringValue,
				username: usernameTextField.stringValue
			),
			!passwordTextField.stringValue.isEmpty else {
			authLabel.stringValue = AuthLabel.error
			return
		}
		API.authenticate(credentials: credentials, password: passwordTextField.stringValue) { success in
			DispatchQueue.main.async {
				self.setAuthResponse(success)
				if success {
					self.passwordTextField.stringValue = ""
				}
			}
		}
	}
	
	@IBAction private func openSafariExtensionPreferences(_ sender: NSButton?) {
		SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
			guard error == nil else { return }

			DispatchQueue.main.async {
				NSApplication.shared.terminate(nil)
			}
		}
	}

	private func setAuthResponse(_ success: Bool) {
		self.authLabel.stringValue = success
			? AuthLabel.valid
			: AuthLabel.userInput
	}
}

private enum AuthLabel {
	static let valid = "You have valid credentials."
	static let userInput = "Please enter your credentials."
	static let error = "Please check your input and try again."
	static let checking = "Checking credentials."
}
