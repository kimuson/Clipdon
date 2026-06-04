import Foundation
import Combine

/// Holds the user's saved favorites and persists them to disk, next to the
/// history file in the app's Application Support container.
///
/// Like `ClipboardStore`, all mutations happen on the main thread, so no extra
/// synchronization is needed.
final class FavoritesStore: ObservableObject {
    @Published private(set) var items: [Favorite] = []

    private let saveURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Clipdon", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        saveURL = base.appendingPathComponent("favorites.json")
        load()
    }

    /// Adds a favorite at the end of the list. If the same text already exists,
    /// its label is updated (when a non-empty one is supplied) instead of adding
    /// a duplicate.
    func add(label: String, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let idx = items.firstIndex(where: { $0.text == text }) {
            if !label.isEmpty { items[idx].label = label }
        } else {
            items.append(Favorite(label: label, text: text))
        }
        save()
    }

    func update(id: UUID, label: String, text: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].label = label
        items[idx].text = text
        save()
    }

    func remove(_ favorite: Favorite) {
        items.removeAll { $0.id == favorite.id }
        save()
    }

    /// Removes whichever favorite holds this exact text (used by the
    /// "unstar" action on a history row).
    func removeByText(_ text: String) {
        items.removeAll { $0.text == text }
        save()
    }

    /// Whether some favorite already holds this exact text.
    func contains(_ text: String) -> Bool {
        items.contains { $0.text == text }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Favorite].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
