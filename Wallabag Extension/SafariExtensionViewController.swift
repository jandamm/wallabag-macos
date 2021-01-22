//
//  SafariExtensionViewController.swift
//  Wallabag Extension
//
//  Created by Jan Dammshäuser on 22.01.21.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
