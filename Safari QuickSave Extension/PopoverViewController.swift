import SafariServices
import Wallabag

class PopoverViewController: SFSafariExtensionViewController {

	// This makes sure we use the same instance of the popover every time.
	static let shared = PopoverViewController()

	// This function runs once when the popover is created.
	override func viewDidLoad() {
		super.viewDidLoad()

		// Create our buttons
		let saveButton = NSButton(title: "Save Current Page", target: self, action: #selector(saveCurrentPageClicked))
		saveButton.bezelStyle = .rounded

		let settingsButton = NSButton(title: "Settings...", target: self, action: #selector(settingsClicked))
		settingsButton.bezelStyle = .rounded

		// Use a stack view to automatically arrange the buttons vertically
		let stackView = NSStackView(views: [saveButton, settingsButton])
		stackView.orientation = .vertical
		stackView.spacing = 10
		stackView.translatesAutoresizingMaskIntoConstraints = false // Important for programmatic layout

		// Add the stack view to the popover's main view
		self.view.addSubview(stackView)

		// Set up constraints to center the stack view with padding
		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
			stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
			stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
			stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20)
		])
	}

	// This is the action for the "Save Current Page" button
	@objc func saveCurrentPageClicked() {
		// We get the active page and tell our main handler to save it.
		SFSafariApplication.getActiveWindow { window in
			window?.getActiveTab { tab in
				tab?.getActivePage { page in
					guard let page = page else { return }
					SafariExtensionHandler.shared.handleSaveCurrentPage(in: page)
					self.dismiss(nil) // Close the popover
				}
			}
		}
	}

	// This is the action for the "Settings..." button
	@objc func settingsClicked() {
		API.openApp()
		self.dismiss(nil) // Close the popover
	}
}
