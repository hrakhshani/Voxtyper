import AppKit
import Carbon.HIToolbox

class PasteService {
    func paste(text: String) {
        // Ensure we have accessibility permission
        guard Self.ensureAccessibilityPermission() else {
            print("[PasteService] No accessibility permission — text copied to clipboard only.")
            copyToClipboard(text)
            return
        }

        copyToClipboard(text)

        // Small delay to let the pasteboard sync before simulating keypress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Type text character-by-character using CGEvents.
    /// Unlike paste(), this doesn't touch the clipboard, so it's safe for streaming deltas.
    func type(text: String) {
        guard Self.ensureAccessibilityPermission() else {
            print("[PasteService] No accessibility permission — cannot type.")
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        for char in text.utf16 {
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { continue }

            var unicodeChar = char
            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)

            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    func simulateBackspace() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: false) else { return }
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    func simulateEnter() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: false) else {
            print("[PasteService] Failed to create CGEvent for Enter")
            return
        }

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Simulates Cmd+C to copy the currently-selected text from the foreground app,
    /// then returns the clipboard contents. Returns nil if nothing was copied (no selection)
    /// or if accessibility permission is missing.
    func captureSelection() -> String? {
        guard Self.ensureAccessibilityPermission() else {
            print("[PasteService] No accessibility permission — cannot capture selection.")
            return nil
        }

        let pasteboard = NSPasteboard.general
        let beforeChange = pasteboard.changeCount

        simulateCopy()

        // Give the foreground app a moment to respond to Cmd+C and update the pasteboard.
        Thread.sleep(forTimeInterval: 0.15)

        guard pasteboard.changeCount > beforeChange else { return nil }
        let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (text?.isEmpty ?? true) ? nil : text
    }

    private func simulateCopy() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false) else {
            print("[PasteService] Failed to create CGEvent for Copy")
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            print("[PasteService] Failed to create CGEvent")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Prompt for accessibility permission if not already granted.
    /// Returns true if permission is granted.
    @discardableResult
    static func ensureAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
