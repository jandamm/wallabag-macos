//
//  ViewController.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 22.01.21.
//

import Cocoa
import LocalAuthentication
import SafariServices.SFSafariApplication
import SafariServices.SFSafariExtensionManager
import SwiftUI
import Wallabag
import UI

let defaults = UserDefaults(suiteName: AppCredentials.userDefaultsGroup)!

class ViewController: NSViewController {

	@IBOutlet private var mainStackView: NSStackView!

	@IBOutlet private var authLabel: NSTextField!
	@IBOutlet private var serverTextField: UI.TextField!
	@IBOutlet private var clientIdTextField: UI.TextField!
	@IBOutlet private var clientSecretTextField: UI.SecureTextField!
	@IBOutlet private var usernameTextField: UI.TextField!
	@IBOutlet private var passwordTextField: SecureTextField!
	@IBOutlet private var validateCredentialsButton: NSButton!

	@IBOutlet private var useWebsiteContentSwitch: NSSwitch!

	@IBOutlet private var appNameLabel: NSTextField!

	// Status indicators added programmatically as a NEW arranged subview right
	// after the Validate button. The existing button/stack layout from the
	// storyboard is left exactly as-is.
	private let statusSpinner = NSProgressIndicator()
	private let statusIcon = NSImageView()
	private let revealButton = NSButton()

	// Client-secret reveal state. We keep a reference to the original
	// NSSecureTextFieldCell so the reveal/hide cycle restores the storyboard-
	// configured cell unmodified (bezel/font/colors/placeholder).
	private var originalSecretCell: NSTextFieldCell?
	private var revealed = false

	override func viewDidLoad() {
		super.viewDidLoad()

		API.Telemetry.launchedApp()

		if #available(macOS 12.0, *) {
			mainStackView.insertArrangedSubview(
				NSHostingView(rootView: TipView()),
				at: 0
			)
		}

		validateCredentialsButton.becomeFirstResponder()

		self.appNameLabel.stringValue = "\(AppCredentials.appName)'s extension is currently unknown."
		self.authLabel.stringValue = AuthLabel.checking

		let credentials = API.Credentials.current
		self.serverTextField.stringValue = credentials?.server.absoluteString ?? ""
		self.clientIdTextField.stringValue = credentials?.clientId ?? ""
		self.clientSecretTextField.stringValue = credentials?.clientSecret ?? ""
		self.usernameTextField.stringValue = credentials?.username ?? ""
		self.passwordTextField.stringValue = ""

		originalSecretCell = clientSecretTextField.cell as? NSTextFieldCell

		setupStatusIndicators()
		setupRevealButton()
		refreshRevealButtonVisibility()

		self.useWebsiteContentSwitch.state = defaults.bool(forKey: "getContentFromPage") ? .on : .off

		API.refreshTokenIfNeeded(clearAuthOnError: false) { result in
			DispatchQueue.main.async {
				self.respondToAuthResponse(result)
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

	@IBAction private func toggleContentFromWebsite(_ sender: NSSwitch) {
		defaults.set(sender.state == .on ? true : false, forKey: "getContentFromPage")
	}

	@IBAction private func validateCredentials(_ sender: NSButton?) {
		authLabel.stringValue = AuthLabel.checking
		showStatusChecking()

		guard let credentials = API.Credentials(
			server: serverTextField.stringValue,
			clientId: clientIdTextField.stringValue,
			clientSecret: clientSecretTextField.stringValue,
			username: usernameTextField.stringValue
		) else {
			authLabel.stringValue = AuthLabel.error
			showStatusInvalid()
			return
		}

		// If the user didn't type a password but a saved OAuth exists for the
		// same credentials, verify by refreshing the token instead of failing.
		// No password is read or stored -- this only uses the existing
		// refresh_token in the keychain.
		if passwordTextField.stringValue.isEmpty {
			if let saved = API.Credentials.current,
			   saved.server == credentials.server,
			   saved.clientId == credentials.clientId,
			   saved.clientSecret == credentials.clientSecret,
			   saved.username == credentials.username {
				API.refreshTokenIfNeeded(clearAuthOnError: false) { result in
					API.Telemetry.authenticate(success: result.isSuccess)
					DispatchQueue.main.async {
						self.respondToAuthResponse(result)
					}
				}
			} else {
				authLabel.stringValue = AuthLabel.userInput
				showStatusInvalid()
			}
			return
		}

		API.authenticate(credentials: credentials, password: passwordTextField.stringValue) { result in
			let success = result.isSuccess
			API.Telemetry.authenticate(success: success)
			DispatchQueue.main.async {
				self.respondToAuthResponse(result)
				if success {
					self.passwordTextField.stringValue = ""
					self.refreshRevealButtonVisibility()
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

	private func respondToAuthResponse(_ result: Result<Void, Error>) {
		self.authLabel.stringValue = result.isSuccess
			? AuthLabel.valid
			: AuthLabel.userInput
		if result.isSuccess {
			showStatusValid()
		} else {
			showStatusInvalid()
		}
		guard case let .failure(error) = result else {
			return
		}
		presentError(error)
	}

	// MARK: - Status indicators

	private func setupStatusIndicators() {
		statusSpinner.style = .spinning
		statusSpinner.controlSize = .small
		statusSpinner.isDisplayedWhenStopped = false
		statusSpinner.translatesAutoresizingMaskIntoConstraints = false

		statusIcon.imageScaling = .scaleProportionallyUpOrDown
		statusIcon.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			statusIcon.widthAnchor.constraint(equalToConstant: 18),
			statusIcon.heightAnchor.constraint(equalToConstant: 18),
		])

		let row = NSStackView(views: [statusSpinner, statusIcon])
		row.orientation = .horizontal
		row.alignment = .centerY
		row.spacing = 8
		row.translatesAutoresizingMaskIntoConstraints = false

		// Insert as a NEW arranged subview right after the Validate button.
		// No wrapping, no removal of the existing button.
		guard let parent = validateCredentialsButton.superview as? NSStackView else { return }
		let idx = parent.arrangedSubviews.firstIndex(of: validateCredentialsButton) ?? (parent.arrangedSubviews.count - 1)
		parent.insertArrangedSubview(row, at: idx + 1)
	}

	private func showStatusChecking() {
		statusIcon.image = nil
		statusSpinner.startAnimation(nil)
	}

	private func showStatusValid() {
		statusSpinner.stopAnimation(nil)
		statusIcon.contentTintColor = .systemGreen
		statusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Valid credentials")
	}

	private func showStatusInvalid() {
		statusSpinner.stopAnimation(nil)
		statusIcon.contentTintColor = .systemRed
		statusIcon.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Invalid credentials")
	}

	// MARK: - Reveal saved client secret in place

	private func setupRevealButton() {
		revealButton.title = "Reveal Client Secret"
		revealButton.bezelStyle = .rounded
		revealButton.target = self
		revealButton.action = #selector(toggleReveal)
		revealButton.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.addArrangedSubview(revealButton)
	}

	private func refreshRevealButtonVisibility() {
		let hasSecret = !clientSecretTextField.stringValue.isEmpty
		revealButton.isHidden = !hasSecret
		revealButton.title = revealed ? "Hide Client Secret" : "Reveal Client Secret"
	}

	@objc private func toggleReveal() {
		if revealed {
			restoreSecureCell()
			revealed = false
			refreshRevealButtonVisibility()
			return
		}

		let context = LAContext()
		context.localizedFallbackTitle = "Use Password"
		var err: NSError?
		let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
			? .deviceOwnerAuthenticationWithBiometrics
			: .deviceOwnerAuthentication

		context.evaluatePolicy(policy, localizedReason: "Reveal the saved Wallabag client secret") { success, _ in
			DispatchQueue.main.async {
				guard success else { return }
				self.installPlainCell()
				self.revealed = true
				self.refreshRevealButtonVisibility()
			}
		}
	}

	private func installPlainCell() {
		guard let secure = originalSecretCell else { return }
		clientSecretTextField.cell = makePlainCellMirroring(secure, value: clientSecretTextField.stringValue)
	}

	private func restoreSecureCell() {
		guard let secure = originalSecretCell else { return }
		let value = clientSecretTextField.stringValue
		clientSecretTextField.cell = secure
		clientSecretTextField.stringValue = value
	}

	/// Builds an NSTextFieldCell that mirrors every relevant property of the
	/// supplied secure cell, so the field looks identical in revealed mode
	/// (same bezel, font, colors, placeholder).
	private func makePlainCellMirroring(_ secure: NSTextFieldCell, value: String) -> NSTextFieldCell {
		let cell = NSTextFieldCell(textCell: value)
		cell.placeholderString = secure.placeholderString
		cell.isEditable = secure.isEditable
		cell.isSelectable = secure.isSelectable
		cell.isBezeled = secure.isBezeled
		cell.bezelStyle = secure.bezelStyle
		cell.isBordered = secure.isBordered
		cell.drawsBackground = secure.drawsBackground
		cell.backgroundColor = secure.backgroundColor
		cell.textColor = secure.textColor
		cell.alignment = secure.alignment
		cell.lineBreakMode = secure.lineBreakMode
		cell.usesSingleLineMode = secure.usesSingleLineMode
		cell.isScrollable = secure.isScrollable
		cell.font = secure.font
		cell.focusRingType = secure.focusRingType
		cell.sendsActionOnEndEditing = secure.sendsActionOnEndEditing
		cell.controlSize = secure.controlSize
		return cell
	}
}

private enum AuthLabel {
	static let valid = "You have valid credentials."
	static let userInput = "Please enter your credentials."
	static let error = "Please check your input and try again."
	static let checking = "Checking credentials."
}
