import Foundation
import Combine

/// Holds the clipboard history and persists it to disk.
///
/// All mutations happen on the main thread (the monitor's timer and the
/// SwiftUI views both run there), so no extra synchronization is needed.
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    /// Maximum number of entries kept in history.
    private let maxItems = 200
    private let saveURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Clipdon", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        saveURL = base.appendingPathComponent("history.json")
        load()
    }

    /// Adds new text to the top of the history. If the same text already
    /// exists it is moved to the top instead of being duplicated.
    func add(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let idx = items.firstIndex(where: { $0.text == text }) {
            var existing = items.remove(at: idx)
            existing.date = Date()
            items.insert(existing, at: 0)
        } else {
            items.insert(ClipItem(text: text), at: 0)
        }

        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
        save()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
