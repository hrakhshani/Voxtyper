import AppKit
import Carbon.HIToolbox

/// System-wide hotkey using Carbon's `RegisterEventHotKey`. Fires `onPress` on the main queue
/// whenever the registered key combination is pressed, regardless of which app is focused.
final class GlobalHotkey {
    static let shared = GlobalHotkey()

    var onPress: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x53545054 /* 'STPT' */, id: 1)

    private init() {
        installEventHandler()
    }

    func register(keyCode: UInt32, carbonModifiers: UInt32) {
        unregister()
        // Require at least one modifier — a bare letter would steal global input.
        guard carbonModifiers != 0 else { return }

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            print("[GlobalHotkey] RegisterEventHotKey failed: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installEventHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let instance = Unmanaged<GlobalHotkey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { instance.onPress?() }
                return noErr
            },
            1,
            &spec,
            userData,
            &eventHandlerRef
        )
    }

    // MARK: - Modifier helpers

    static func carbonFlags(from ns: NSEvent.ModifierFlags) -> UInt32 {
        var c: UInt32 = 0
        if ns.contains(.command)  { c |= UInt32(cmdKey) }
        if ns.contains(.option)   { c |= UInt32(optionKey) }
        if ns.contains(.control)  { c |= UInt32(controlKey) }
        if ns.contains(.shift)    { c |= UInt32(shiftKey) }
        return c
    }

    static func modifierSymbols(carbon: UInt32) -> String {
        var s = ""
        if carbon & UInt32(controlKey) != 0 { s += "⌃" }
        if carbon & UInt32(optionKey)  != 0 { s += "⌥" }
        if carbon & UInt32(shiftKey)   != 0 { s += "⇧" }
        if carbon & UInt32(cmdKey)     != 0 { s += "⌘" }
        return s
    }
}
