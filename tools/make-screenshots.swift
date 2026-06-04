// Generates App Store marketing screenshots for Clipdon.
//
//   swift tools/make-screenshots.swift
//
// Renders a faithful replica of the history popup (HistoryView) offscreen with
// SwiftUI's ImageRenderer, then composites it onto a branded gradient canvas at
// an App-Store-accepted size (2560×1600). No running GUI / screen-recording
// permission required. Output: store-assets/screenshots/*.png
//
// Note: the popup replica deliberately uses a solid card instead of the live
// `.regularMaterial`, and plain stacks instead of List/TextField, so it
// rasterizes cleanly (ImageRenderer cannot render NSView-backed controls).

import SwiftUI
import AppKit

// MARK: - Sample history data

struct Row {
    let text: String
    let rel: String
    let lines: Int

    /// Mirrors ClipItem.preview: single-line, newlines shown as ⏎, truncated.
    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ⏎ ")
        return singleLine.count > 100 ? String(singleLine.prefix(100)) + "…" : singleLine
    }
}

let baseRows: [Row] = [
    Row(text: "https://github.com/nexaspark/clipdon", rel: "now", lines: 1),
    Row(text: "git commit -m \"Fix popup positioning\"", rel: "1m ago", lines: 1),
    Row(text: "git push origin main", rel: "2m ago", lines: 1),
    Row(text: "yuta.kimura@nexaspark.org", rel: "5m ago", lines: 1),
    Row(text: "1 Infinite Loop, Cupertino, CA 95014", rel: "12m ago", lines: 1),
    Row(text: "func togglePopup() {\n    if panel.isVisible { close() }\n}", rel: "15m ago", lines: 3),
    Row(text: "Thanks for your help — talk soon!", rel: "22m ago", lines: 1),
    Row(text: "#5B8CF2", rel: "30m ago", lines: 1),
    Row(text: "TODO: upload screenshots to App Store Connect", rel: "1h ago", lines: 1),
]

// MARK: - Popup replica (matches HistoryView's look)

let selectionTint = Color(red: 0.30, green: 0.36, blue: 0.85)

struct RowView: View {
    let row: Row
    let selected: Bool
    var favorited: Bool = false
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.preview)
                    .lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.85))
                Text(row.rel)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
            Spacer(minLength: 4)
            if favorited {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.yellow.opacity(0.8))
            }
            if row.lines > 1 {
                Text("\(row.lines) lines")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.black.opacity(0.30))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? selectionTint.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// Sample favorite for the replica.
struct FavRow {
    let label: String
    let text: String
    let lines: Int

    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ⏎ ")
        return singleLine.count > 100 ? String(singleLine.prefix(100)) + "…" : singleLine
    }
    var displayTitle: String { label.isEmpty ? preview : label }
}

struct FavRowView: View {
    let fav: FavRow
    let selected: Bool
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(fav.displayTitle)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: fav.label.isEmpty ? .regular : .medium))
                    .foregroundStyle(Color.black.opacity(0.85))
                if !fav.label.isEmpty {
                    Text(fav.preview)
                        .lineLimit(1)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
            }
            Spacer(minLength: 4)
            if fav.lines > 1 {
                Text("\(fav.lines) lines")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.black.opacity(0.30))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? selectionTint.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct PopupView: View {
    let query: String
    let rows: [Row]
    let selected: Int
    let totalCount: Int
    var favorites: [FavRow] = []
    var favSelected: Int = -1

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.black.opacity(0.45))
                if query.isEmpty {
                    Text("Search…").foregroundStyle(Color.black.opacity(0.4))
                } else {
                    Text(query).foregroundStyle(Color.black.opacity(0.85))
                }
                Spacer()
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            // List
            VStack(spacing: 0) {
                if !favorites.isEmpty {
                    // Favorites section header
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.system(size: 10))
                        Text("Favorites")
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 3)

                    ForEach(Array(favorites.enumerated()), id: \.offset) { idx, fav in
                        FavRowView(fav: fav, selected: idx == favSelected)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                    }

                    // History section header (only shown alongside favorites)
                    Text("History")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                        .padding(.bottom, 3)
                }

                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    RowView(
                        row: row,
                        selected: idx == selected,
                        favorited: favorites.contains { $0.text == row.text }
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()

            // Footer
            HStack {
                Text("\(totalCount) items")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.black.opacity(0.45))
                Spacer()
                Image(systemName: "gearshape")
                    .foregroundStyle(Color.black.opacity(0.45))
            }
            .font(.system(size: 11))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(width: 360, height: 440)
        .background(Color(white: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
        )
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Full screenshot canvas

struct Shot: View {
    let grad: [Color]
    let headline: String
    let subhead: String
    let popupImage: NSImage
    let appIcon: NSImage

    var body: some View {
        ZStack {
            LinearGradient(colors: grad, startPoint: .topLeading, endPoint: .bottomTrailing)

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 16) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 56, height: 56)
                        Text("Clipdon")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text(headline)
                        .font(.system(size: 47, weight: .bold))
                        .foregroundStyle(.white)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subhead)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 560, alignment: .leading)

                Spacer(minLength: 0)

                Image(nsImage: popupImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 425, height: 520)
                    .shadow(color: .black.opacity(0.30), radius: 26, x: 0, y: 16)
            }
            .padding(.horizontal, 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 1280, height: 800)
    }
}

// MARK: - Rendering helpers

@MainActor
func renderNSImage<V: View>(_ view: V, width: CGFloat, height: CGFloat, scale: CGFloat) -> NSImage {
    let r = ImageRenderer(content: view.frame(width: width, height: height))
    r.scale = scale
    r.isOpaque = false
    return r.nsImage ?? NSImage(size: NSSize(width: width, height: height))
}

@MainActor
func renderPNG<V: View>(_ view: V, width: CGFloat, height: CGFloat, scale: CGFloat, to url: URL) throws {
    let r = ImageRenderer(content: view.frame(width: width, height: height))
    r.scale = scale
    r.isOpaque = true
    guard let cg = r.cgImage else { throw NSError(domain: "render", code: 1) }
    let rep = NSBitmapImageRep(cgImage: cg)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "png", code: 1)
    }
    try png.write(to: url)
}

func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(red: r/255, green: g/255, blue: b/255)
}

// MARK: - Screenshot definitions

struct ShotSpec {
    let file: String
    let grad: [Color]
    let headline: String
    let subhead: String
    let query: String
    let rows: [Row]
    let selected: Int
    var favorites: [FavRow] = []
    var favSelected: Int = -1
}

let gitRows = baseRows.filter { $0.text.localizedCaseInsensitiveContains("git") }

// Sample data for the favorites screenshot.
let favRows: [FavRow] = [
    FavRow(label: "Deploy to prod", text: "kubectl rollout restart deployment/web -n prod", lines: 1),
    FavRow(label: "", text: "https://github.com/nexaspark/clipdon", lines: 1),
    FavRow(label: "Support reply", text: "Thanks for reaching out!\nWe'll get back to you shortly.", lines: 2),
]
// A shorter history list so favorites + history both fit the fixed-height card.
// The GitHub URL is also a favorite, so its history row shows the ★ indicator.
let favHistory: [Row] = [
    Row(text: "https://github.com/nexaspark/clipdon", rel: "now", lines: 1),
    Row(text: "git commit -m \"Fix popup positioning\"", rel: "1m ago", lines: 1),
    Row(text: "yuta.kimura@nexaspark.org", rel: "5m ago", lines: 1),
    Row(text: "func togglePopup() {\n    if panel.isVisible { close() }\n}", rel: "15m ago", lines: 3),
    Row(text: "#5B8CF2", rel: "30m ago", lines: 1),
]

let specs: [ShotSpec] = [
    ShotSpec(
        file: "01-history",
        grad: [rgb(110, 143, 243), rgb(74, 79, 212)],
        headline: "Recall everything\nyou've copied.",
        subhead: "A popup at your cursor with ⌘⇧V.\nPick one, press Enter, paste with ⌘V.",
        query: "", rows: baseRows, selected: 0
    ),
    ShotSpec(
        file: "02-search",
        grad: [rgb(91, 176, 236), rgb(62, 111, 208)],
        headline: "Type to\nfilter instantly.",
        subhead: "Search straight to the one you need.",
        query: "git", rows: gitRows, selected: 0
    ),
    ShotSpec(
        file: "03-keyboard",
        grad: [rgb(130, 112, 242), rgb(84, 54, 201)],
        headline: "All from\nthe keyboard.",
        subhead: "↑ ↓ to select, Enter to re-copy,\nEsc to close. No mouse needed.",
        query: "", rows: baseRows, selected: 3
    ),
    ShotSpec(
        file: "04-privacy",
        grad: [rgb(70, 188, 200), rgb(58, 122, 201)],
        headline: "Your history\nnever leaves this Mac.",
        subhead: "Nothing is sent anywhere. Passwords and\nother secrets are skipped automatically.",
        query: "", rows: baseRows, selected: 0
    ),
    ShotSpec(
        file: "05-favorites",
        grad: [rgb(245, 182, 76), rgb(223, 130, 40)],
        headline: "Pin the ones\nyou use most.",
        subhead: "Save commands and snippets as favorites —\nalways one keystroke away.",
        query: "", rows: favHistory, selected: -1,
        favorites: favRows, favSelected: 0
    ),
]

// MARK: - Main

@MainActor
func generateAll() throws {
    let fm = FileManager.default
    let outDir = URL(fileURLWithPath: "store-assets/screenshots")
    try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

    let appIcon = NSImage(contentsOfFile: "Assets.xcassets/AppIcon.appiconset/icon_256.png")
        ?? NSImage(contentsOfFile: "Assets.xcassets/AppIcon.appiconset/icon_1024.png")
        ?? NSImage()

    for spec in specs {
        let popup = PopupView(
            query: spec.query,
            rows: spec.rows,
            selected: spec.selected,
            totalCount: baseRows.count,
            favorites: spec.favorites,
            favSelected: spec.favSelected
        )
        // Render the popup at 3x so the downscaled card text stays crisp.
        let popupImage = renderNSImage(popup, width: 360, height: 440, scale: 3)

        let shot = Shot(
            grad: spec.grad,
            headline: spec.headline,
            subhead: spec.subhead,
            popupImage: popupImage,
            appIcon: appIcon
        )
        // Design space is 1280×800; scale 2 → 2560×1600 (App Store accepted).
        let url = outDir.appendingPathComponent("\(spec.file).png")
        try renderPNG(shot, width: 1280, height: 800, scale: 2, to: url)
        print("✓ \(url.path)")
    }
    print("Done: \(specs.count) screenshots @ 2560×1600")
}

Task { @MainActor in
    do {
        try generateAll()
    } catch {
        FileHandle.standardError.write("ERROR: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
    exit(0)
}
dispatchMain()
