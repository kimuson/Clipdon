import AppKit

/// Watches the system pasteboard for changes.
///
/// macOS does not post a notification when the clipboard changes, so we poll
/// `NSPasteboard.changeCount` on a short timer and read the new text when it
/// differs from what we last saw.
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    /// Called on the main thread whenever new text lands on the clipboard.
    var onCopy: ((String) -> Void)?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.poll()
        }
        // .common so polling keeps running while a menu/popover is tracking.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Tells the monitor that we just wrote to the pasteboard ourselves, so the
    /// resulting change should not be re-captured into history.
    func ignoreNextChange() {
        lastChangeCount = pasteboard.changeCount
    }

    private func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // Respect the nspasteboard.org convention: skip content that apps
        // (e.g. password managers) mark as concealed or transient.
        if let types = pasteboard.types {
            let skip: Set<NSPasteboard.PasteboardType> = [
                .init("org.nspasteboard.ConcealedType"),
                .init("org.nspasteboard.TransientType")
            ]
            if !skip.isDisjoint(with: types) { return }
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        onCopy?(text)
    }
}
