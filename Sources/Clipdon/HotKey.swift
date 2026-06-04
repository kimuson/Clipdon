import AppKit
import Carbon

/// Registers a system-wide hot key using the Carbon Event Manager.
///
/// Unlike synthesizing key events, registering a hot key does NOT require the
/// Accessibility permission, which keeps Clipdon zero-permission to install.
final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    /// Invoked on the main thread when the hot key is pressed.
    var action: (() -> Void)?

    /// The Carbon callback is a C function pointer and cannot capture context,
    /// so we route through this shared reference.
    private static var shared: HotKey?

    /// Registers the hot key. `keyCode` is a Carbon virtual key code
    /// (e.g. `kVK_ANSI_V`) and `modifiers` is a mask such as
    /// `UInt32(cmdKey | shiftKey)`.
    func register(keyCode: UInt32, modifiers: UInt32) {
        HotKey.shared = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                HotKey.shared?.action?()
                return noErr
            },
            1, &eventType, nil, &handlerRef
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x636C646E /* 'cldn' */), id: 1)
        RegisterEventHotKey(
            keyCode, modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
