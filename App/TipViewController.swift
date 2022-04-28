//
//  TipViewController.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 27.04.22.
//

import Cocoa
import StoreKit

@available(macOS 12.0, *)
final class TipViewController: NSViewController {
	@IBOutlet private var tip1Button: TipButton!
	@IBOutlet private var tip2Button: TipButton!
	@IBOutlet private var tip3Button: TipButton!

	private lazy var buttons: [TipButton] = [tip1Button, tip2Button, tip3Button]

	var onSuccess: () -> Void = {}

	override func viewDidLoad() {
		super.viewDidLoad()

		buttons.forEach { $0.isHidden = true }

		Task {
			zip(
				buttons,
				await Tip.getProducts()
			).forEach { button, product in
				button.tip = product
			}
		}
	}

	@IBAction private func purchaseTip(_ button: TipButton) {
		guard let tip = button.tip else { return }
		Tip.purchase(tip) { [weak self] in
			self?.view.window?.close()
			self?.onSuccess()
		}
	}
}

@available(macOS 12.0, *)
final class TipButton: NSButton {
	fileprivate var tip: Product! {
		didSet {
			isHidden = false
			title = "\(tip.displayName) - \(tip.displayPrice)"
		}
	}
}
