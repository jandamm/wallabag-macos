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

private let freeToUse = "This App is free to use. But in order to keep it in the AppStore I need to pay a yearly fee."
class ViewController: NSViewController {

	@IBOutlet private var tipStackView: NSStackView!
	@IBOutlet private var tipLabel: NSTextField!
	@IBOutlet private var tipButton: NSButton!

	@IBOutlet private var thankYouView: NSView!

	@IBOutlet private var authLabel: NSTextField!
	@IBOutlet private var serverTextField: TextField!
	@IBOutlet private var clientIdTextField: TextField!
	@IBOutlet private var clientSecretTextField: TextField!
	@IBOutlet private var usernameTextField: TextField!
	@IBOutlet private var passwordTextField: SecureTextField!
	@IBOutlet private var validateCredentialsButton: NSButton!

	@IBOutlet private var appNameLabel: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		if #available(macOS 12.0, *) {
			Task {
				tipStackView.isHidden = (await Tip.fetch()).isEmpty
			}

			setTippingState()
		} else {
			tipStackView.isHidden = true
		}

		validateCredentialsButton.becomeFirstResponder()

		self.appNameLabel.stringValue = "\(AppCredentials.appName)'s extension is currently unknown."
		self.authLabel.stringValue = AuthLabel.checking

		let credentials = API.Credentials.current
		self.serverTextField.stringValue = credentials?.server.absoluteString ?? "https://app.wallabag.it"
		self.clientIdTextField.stringValue = credentials?.clientId ?? "14354_5qrutno26p8ogkwgwkow800040owwwwkg4oc4ko0s8cws0s88s"
		self.clientSecretTextField.stringValue = credentials?.clientSecret ?? "2umird08j0ys80wkw8kokoc8gc08wk8skcccsoo40g4oowssws"
		self.usernameTextField.stringValue = credentials?.username ?? "jandam"
		self.passwordTextField.stringValue = "clod7PSUP-lirn9tooy"

		API.refreshTokenIfNeeded { success in
			DispatchQueue.main.async {
				self.setAuthResponse(success)
			}
		}

		SFSafariExtensionManager.getStateOfSafariExtension(
			withIdentifier: AppCredentials.safariBundleIdentifier
		) { (state, error) in
			guard let state = state, error == nil else { return }

			DispatchQueue.main.async {
				self.appNameLabel.stringValue = state.isEnabled
					? "\(AppCredentials.appName)'s extension is currently on."
					: "\(AppCredentials.appName)'s extension is currently off. You can turn it on in Safari Extensions preferences."
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
		SFSafariApplication.showPreferencesForExtension(
			withIdentifier: AppCredentials.safariBundleIdentifier
		) { error in
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

	@available(macOS 12.0, *)
	private func setTippingState() {
			if !Tip.previousTips.isEmpty {
				thankYouView.isHidden = false
				tipLabel.stringValue = freeToUse
				tipButton.title = "Tip again"
			} else {
				tipLabel.stringValue = "\(freeToUse)\nIt would be nice if you consider giving a tip."
				tipButton.title = "Give a Tip"
			}
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if #available(macOS 12.0, *) {
			guard let tip = segue.destinationController as? TipViewController else { return }
			tip.onSuccess = { [weak self] in
				self?.setTippingState()
			}
		}
	}
}

private enum AuthLabel {
	static let valid = "You have valid credentials."
	static let userInput = "Please enter your credentials."
	static let error = "Please check your input and try again."
	static let checking = "Checking credentials."
}
