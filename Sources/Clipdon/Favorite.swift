import Foundation

/// A pinned clipboard entry the user wants to keep around permanently —
/// e.g. a frequently used command or snippet. Unlike `ClipItem`, favorites are
/// never evicted by the history cap and carry an optional human-readable label.
struct Favorite: Identifiable, Codable, Equatable {
    let id: UUID
    /// Optional name (e.g. "Deploy to prod"). Empty means show the text itself.
    var label: String
    var text: String
    var date: Date

    init(id: UUID = UUID(), label: String = "", text: String, date: Date = Date()) {
        self.id = id
        self.label = label
        self.text = text
        self.date = date
    }

    /// The row's primary line: the label when present, otherwise a text preview.
    var displayTitle: String { label.isEmpty ? preview : label }
    var preview: String { text.clipPreview }
    var lineCount: Int { text.clipLineCount }
}
