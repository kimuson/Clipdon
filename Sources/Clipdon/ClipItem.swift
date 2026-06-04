import Foundation

/// A single entry in the clipboard history.
struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var date: Date

    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }

    /// A short, single-line preview suitable for the list row.
    var preview: String { text.clipPreview }

    /// Number of lines in the stored text (used to hint multi-line entries).
    var lineCount: Int { text.clipLineCount }
}

extension String {
    /// A short, single-line preview suitable for a list row: trimmed, with
    /// newlines collapsed to a ⏎ marker and long text truncated.
    var clipPreview: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ⏎ ")
        if singleLine.count > 100 {
            return String(singleLine.prefix(100)) + "…"
        }
        return singleLine
    }

    /// Number of lines in the text (used to hint multi-line entries).
    var clipLineCount: Int {
        split(separator: "\n", omittingEmptySubsequences: false).count
    }
}
