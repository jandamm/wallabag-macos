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

        // For "Save Page", the existing logic already handles feedback.
        if command == "save-current-page" {
            handleSaveCurrentPage(in: page)
            return
        }
        
        // For the other two commands, we first need to get the user's credentials.
        guard let oAuth = API.oAuth, !oAuth.isExpired else {
            print("Wallabag Error: Not authenticated.")
            updateToolbarBadge(with: "Login", autoClear: true) // Provide feedback if not logged in
            return
        }
        
        let credentials = [
            "token": oAuth.token.access_token,
            "serverURL": oAuth.credentials.server.absoluteString
        ]
        
        // Now we handle each command and add the feedback.
        if command == "save-linked-url" {
            // Show "..." to indicate the action has started.
            updateToolbarBadge(with: "...")
            page.dispatchMessageToScript(withName: "saveLinkViaJavaScript", userInfo: credentials)
            
            // Since we don't get a response from JS, we optimistically
            // show "Ok" after a short delay, assuming it will succeed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateToolbarBadge(with: "Ok", autoClear: true)
            }
            
        } else if command == "save-all-links" {
            // Show a message to indicate the process is starting.
            // The final confirmation will come from the JavaScript alert.
            updateToolbarBadge(with: "Busy…", autoClear: true)
            page.dispatchMessageToScript(withName: "showLinkSelectorUI", userInfo: credentials)
        }
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]? = nil) { }
    
    func handleSaveCurrentPage(in page: SFSafariPage) {
        getWebsite(of: page) { website in
            guard let website = website else { return }
            self.save(website: website)
        }
    }

    func save(website: Website) {
        updateToolbarBadge(with: "...")
        API.save(website: website) { result in
            self.handleSaveResponse(result: result)
        }
    }

    func handleSaveResponse(result: Result<Void, API.Error>) {
        switch result {
        case .success:
            updateToolbarBadge(with: "Ok", autoClear: true)
        case .failure:
            updateToolbarBadge(with: "Error", autoClear: true)
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

