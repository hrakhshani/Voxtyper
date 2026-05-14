import AppKit
import Carbon.HIToolbox

class PasteService {
    /// True when the process is running inside the macOS App Sandbox.
    /// Cross-app CGEvent posting (⌘V, ⌘C, key synthesis into other apps) is
    /// blocked by the sandbox even with Accessibility granted, so we degrade
    /// to clipboard-only behavior in that case.
    static let isSandboxed: Bool = {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }()

    func paste(text: String) {
        copyToClipboard(text)

        if Self.isSandboxed {
            print("[PasteService] Sandboxed — text copied to clipboard, user must press ⌘V.")
            return
        }

        guard Self.ensureAccessibilityPermission() else {
            print("[PasteService] No accessibility permission — text copied to clipboard only.")
            return
        }

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
    /// No-op when sandboxed (CGEvent posting into other apps is blocked).
    func type(text: String) {
        if Self.isSandboxed {
            print("[PasteService] Sandboxed — type() unavailable.")
            return
        }

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
        if Self.isSandboxed { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: false) else { return }
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    func simulateEnter() {
        if Self.isSandboxed {
            print("[PasteService] Sandboxed — simulateEnter() unavailable.")
            return
        }
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
    /// then returns the clipboard contents. Returns nil if nothing was copied (no selection),
    /// if accessibility permission is missing, or if we're sandboxed.
    func captureSelection() -> String? {
        if Self.isSandboxed {
            print("[PasteService] Sandboxed — captureSelection() unavailable.")
            return nil
        }

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
    /// Returns true if permission is granted. Always returns false when sandboxed,
    /// since the sandbox blocks cross-app event posting regardless of Accessibility.
    @discardableResult
    static func ensureAccessibilityPermission() -> Bool {
        if isSandboxed { return false }
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
