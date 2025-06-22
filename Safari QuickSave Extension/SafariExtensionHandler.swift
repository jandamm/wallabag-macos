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

    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
        // For "Save Page", we still handle it in Swift.
        if command == "save-current-page" {
            handleSaveCurrentPage(in: page)
            return
        }
        
        // For BOTH "Save Link" and "Save All Links", we will now use the same architecture:
        // get credentials and pass the command to JavaScript to handle everything.
        
        // 1. Get the current authentication details.
        guard let oAuth = API.oAuth, !oAuth.isExpired else {
            print("Wallabag Error: Not authenticated.")
            // You could add a JS alert here if you wanted.
            return
        }
        
        // 2. Package the credentials to send to the script.
        let credentials = [
            "token": oAuth.token.access_token,
            "serverURL": oAuth.credentials.server.absoluteString
        ]
        
        // 3. Send the appropriate command to the script with the credentials.
        if command == "save-linked-url" {
            page.dispatchMessageToScript(withName: "saveLinkViaJavaScript", userInfo: credentials)
        } else if command == "save-all-links" {
            page.dispatchMessageToScript(withName: "saveAllLinksViaJavaScript", userInfo: credentials)
        }
    }

    // This function is now completely empty, as JavaScript handles all responses.
    // We are no longer relying on the broken JS-to-Swift communication channel.
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]? = nil) { }
    
    // MARK: - Handlers & Helpers (only for "Save Page" now)

    private func handleSaveCurrentPage(in page: SFSafariPage) {
        getWebsite(of: page) { website in
            guard let website = website else { return }
            self.save(website: website)
        }
    }

    private func save(website: Website) {
        updateToolbarBadge(with: "...")
        API.save(website: website) { result in
            self.handleSaveResponse(result: result)
        }
    }

    private func handleSaveResponse(result: Result<Void, API.Error>) {
        switch result {
        case .success:
            updateToolbarBadge(with: "Ok", autoClear: true)
        case .failure:
            updateToolbarBadge(with: "Error", autoClear: true)
        }
    }
    
    // MARK: - Boilerplate
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                guard let page = page else { return }
                self.handleSaveCurrentPage(in: page)
            }
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "");
    }
    
    private func updateToolbarBadge(with text: String?, autoClear: Bool = false) {
        SFSafariApplication.getActiveWindow { window in
            window?.getToolbarItem { item in
                item?.setBadgeText(text)
                if autoClear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { item?.setBadgeText(nil) } }
            }
        }
    }

    private func getWebsite(of page: SFSafariPage, callback: @escaping (Website?) -> Void) {
        page.getPropertiesWithCompletionHandler { properties in
            callback(properties?.url.map { Website(url: $0, title: properties?.title) })
        }
    }
}

