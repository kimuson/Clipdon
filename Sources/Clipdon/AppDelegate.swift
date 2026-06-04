import AppKit
import SwiftUI
import Carbon

/// A borderless panel that can still become key, so the search field inside
/// it receives keyboard focus the moment it appears.
final class PopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = ClipboardStore()
    private let favorites = FavoritesStore()
    private let monitor = ClipboardMonitor()
    private let hotKey = HotKey()

    private var statusItem: NSStatusItem!
    private var panel: PopupPanel?

    private let popupSize = NSSize(width: 360, height: 440)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)

        setUpStatusItem()
        setUpMonitor()
        setUpHotKey()
    }

    // MARK: - Setup

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Clipdon"
            )
            button.action = #selector(togglePopup)
            button.target = self
        }
    }

    private func setUpMonitor() {
        monitor.onCopy = { [weak self] text in self?.store.add(text) }
        monitor.start()
    }

    private func setUpHotKey() {
        hotKey.action = { [weak self] in self?.togglePopup() }
        // ⌘⇧V — system-wide, no Accessibility permission required.
        hotKey.register(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey))
    }

    // MARK: - Popup control

    @objc private func togglePopup() {
        if let panel, panel.isVisible {
            closePopup()
        } else {
            showPopup()
        }
    }

    /// Builds a fresh panel each time so the search field starts empty and
    /// re-focused, and shows it anchored at the current mouse location.
    private func showPopup() {
        let panel = PopupPanel(
            contentRect: NSRect(origin: .zero, size: popupSize),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self

        let root = HistoryView(
            store: store,
            favorites: favorites,
            onCopy: { [weak self] text in self?.copyToClipboard(text) },
            onClose: { [weak self] in self?.closePopup() },
            onQuit: { NSApp.terminate(nil) }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: popupSize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        self.panel = panel
        positionAtMouse(panel)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    /// Places the panel so its top-left corner sits at the cursor, clamped to
    /// stay fully on the screen that contains the cursor.
    private func positionAtMouse(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        var topLeft = mouse
        if let vf = screen?.visibleFrame {
            let w = popupSize.width, h = popupSize.height
            if topLeft.x + w > vf.maxX { topLeft.x = vf.maxX - w }
            if topLeft.x < vf.minX { topLeft.x = vf.minX }
            if topLeft.y - h < vf.minY { topLeft.y = vf.minY + h }
            if topLeft.y > vf.maxY { topLeft.y = vf.maxY }
        }
        panel.setFrameTopLeftPoint(topLeft)
    }

    private func closePopup() {
        panel?.orderOut(nil)
        panel = nil
    }

    /// Dismiss when the user clicks somewhere else.
    func windowDidResignKey(_ notification: Notification) {
        if (notification.object as? NSWindow) === panel {
            closePopup()
        }
    }

    // MARK: - Selecting an entry

    /// Copies the chosen text (a history item or a favorite) back onto the
    /// clipboard. The user then pastes it themselves with ⌘V (no Accessibility
    /// permission required).
    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        monitor.ignoreNextChange()
        store.add(text) // bump it to the top of history
        closePopup()
    }
}
