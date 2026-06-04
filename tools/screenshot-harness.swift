// Offscreen render harness for verifying the real popup UI.
//
// Compiled together with the production sources (everything in Sources/Clipdon
// except main.swift), so it renders the ACTUAL HistoryView / FavoriteRow /
// RowView with the real ClipboardStore and FavoritesStore — not a replica.
// Seeds sample data, hosts the view in a real window so SwiftUI's
// List/TextField lay out properly, then captures it to a PNG using in-process
// cacheDisplay (no Screen Recording permission required).
//
//   /tmp/clipdon-favorites.png

import AppKit
import SwiftUI

@main
struct Harness {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let store = ClipboardStore()
        let favorites = FavoritesStore()

        // Seed favorites: a labelled command, a bare URL, a labelled snippet.
        // The URL is also added to history so its row shows the ★ indicator.
        favorites.add(label: "Deploy to prod", text: "kubectl rollout restart deployment/web -n prod")
        favorites.add(label: "", text: "https://github.com/nexaspark/clipdon")
        favorites.add(label: "Support reply", text: "Thanks for reaching out!\nWe'll get back to you shortly.")

        // Seed history (add() inserts at top, so the last added shows first).
        for t in [
            "The quick brown fox jumps over the lazy dog",
            "git push origin main",
            "yuta.kimura@nexaspark.org",
            "func togglePopup() {\n    if panel.isVisible { close() }\n}",
            "https://github.com/nexaspark/clipdon",
            "#5B8CF2",
        ] { store.add(t) }

        let view = HistoryView(
            store: store,
            favorites: favorites,
            onCopy: { _ in },
            onClose: {},
            onQuit: {}
        )

        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 360, height: 440)
        host.wantsLayer = true

        let window = NSWindow(
            contentRect: host.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = host
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.setFrameOrigin(NSPoint(x: 60, y: 60))
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        // Give SwiftUI a couple of run-loop turns to lay out the List, then capture.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            host.displayIfNeeded()
            guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
                FileHandle.standardError.write("no rep\n".data(using: .utf8)!)
                exit(1)
            }
            host.cacheDisplay(in: host.bounds, to: rep)
            guard let png = rep.representation(using: .png, properties: [:]) else {
                FileHandle.standardError.write("no png\n".data(using: .utf8)!)
                exit(1)
            }
            try? png.write(to: URL(fileURLWithPath: "/tmp/clipdon-favorites.png"))
            print("captured \(rep.pixelsWide)x\(rep.pixelsHigh) -> /tmp/clipdon-favorites.png")
            NSApp.terminate(nil)
        }

        app.run()
    }
}
