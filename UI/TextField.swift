import Foundation
import Cocoa

public final class TextField: NSTextField {
	public override func performKeyEquivalent(with event: NSEvent) -> Bool {
		NSTextField.performKeyEquivalent(with: event, in: self)
			|| super.performKeyEquivalent(with: event)
	}
}

public final class SecureTextField: NSSecureTextField {
	public override func performKeyEquivalent(with event: NSEvent) -> Bool {
		NSTextField.performKeyEquivalent(with: event, in: self)
			|| super.performKeyEquivalent(with: event)
	}
}

private extension NSTextField {
	static func performKeyEquivalent(with event: NSEvent, in textField: NSTextField) -> Bool {
		guard event.type == .keyDown else { return false }

		switch (event.modifierFlags.deviceIndendent, event.charactersIgnoringModifiers) {
		case (.command, "x"):
			return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: textField)
		case (.command, "c"):
			return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: textField)
		case (.command, "v"):
			return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: textField)
		case (.command, "z"):
			return NSApp.sendAction(Selector(("undo:")), to: nil, from: textField)
		case (.command, "a"):
			return NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: textField)
		case (.commandShift, "Z"):
			return NSApp.sendAction(Selector(("redo:")), to: nil, from: textField)
		default:
			return false
		}
	}
}

private extension NSEvent.ModifierFlags {
	static var commandShift: NSEvent.ModifierFlags {
		NSEvent.ModifierFlags.command.union(.shift)
	}

	var deviceIndendent: NSEvent.ModifierFlags {
		intersection(.deviceIndependentFlagsMask)
	}
}
