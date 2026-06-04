import SwiftUI

/// The popover content: a search field, a pinned "favorites" section, and the
/// scrollable history list below it. Keyboard navigation runs across both
/// sections (favorites first, then history).
struct HistoryView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var favorites: FavoritesStore

    /// Copy the given text back to the clipboard and dismiss.
    var onCopy: (String) -> Void
    /// Dismiss without choosing anything.
    var onClose: () -> Void
    /// Quit the whole app.
    var onQuit: () -> Void

    @State private var query = ""
    @State private var selection: UUID?
    @FocusState private var searchFocused: Bool

    // Inline add/edit form. The popup is a borderless panel, so an inline editor
    // is more reliable here than a presented sheet.
    @State private var showingEditor = false
    @State private var editingID: UUID?
    @State private var editLabel = ""
    @State private var editText = ""

    // MARK: - Derived data

    private var filteredFavorites: [Favorite] {
        guard !query.isEmpty else { return favorites.items }
        return favorites.items.filter {
            $0.text.localizedCaseInsensitiveContains(query) ||
            $0.label.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredHistory: [ClipItem] {
        guard !query.isEmpty else { return store.items }
        return store.items.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }

    /// Flat, ordered ids of every selectable row, for keyboard navigation.
    private var orderedIDs: [UUID] {
        filteredFavorites.map(\.id) + filteredHistory.map(\.id)
    }

    private func text(for id: UUID) -> String? {
        if let fav = filteredFavorites.first(where: { $0.id == id }) { return fav.text }
        if let item = filteredHistory.first(where: { $0.id == id }) { return item.text }
        return nil
    }

    private var isEmpty: Bool { filteredFavorites.isEmpty && filteredHistory.isEmpty }

    // MARK: - Body

    var body: some View {
        Group {
            if showingEditor {
                editorView
            } else {
                mainView
            }
        }
        .frame(width: 360, height: 440)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            searchFocused = true
            selection = orderedIDs.first
        }
        .onChange(of: query) { _, _ in
            selection = orderedIDs.first
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()

            if isEmpty {
                emptyState
            } else {
                listView
            }

            Divider()
            footer
        }
    }

    // MARK: - Sections

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search…", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit { copySelected() }
                .onKeyPress(.downArrow) { moveSelection(1); return .handled }
                .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
                .onKeyPress(.escape) { onClose(); return .handled }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var listView: some View {
        ScrollViewReader { proxy in
            List {
                if !filteredFavorites.isEmpty {
                    Section {
                        ForEach(filteredFavorites) { fav in
                            FavoriteRow(fav: fav, selected: fav.id == selection)
                                .id(fav.id)
                                .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                                .listRowSeparator(.hidden)
                                .contentShape(Rectangle())
                                .onTapGesture { onCopy(fav.text) }
                                .contextMenu {
                                    Button("Copy") { onCopy(fav.text) }
                                    Button("Edit Label & Content…") { startEdit(fav) }
                                    Button("Remove from Favorites", role: .destructive) {
                                        favorites.remove(fav)
                                    }
                                }
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Label("Favorites", systemImage: "star.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button { startNewFavorite() } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderless)
                            .help("Add favorite")
                        }
                        .font(.system(size: 11))
                    }
                }

                if !filteredHistory.isEmpty {
                    Section {
                        ForEach(filteredHistory) { item in
                            RowView(
                                item: item,
                                selected: item.id == selection,
                                favorited: favorites.contains(item.text)
                            )
                            .id(item.id)
                            .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture { onCopy(item.text) }
                            .contextMenu {
                                Button("Copy") { onCopy(item.text) }
                                if favorites.contains(item.text) {
                                    Button("Remove from Favorites") { favorites.removeByText(item.text) }
                                } else {
                                    Button("Add to Favorites") { favorites.add(label: "", text: item.text) }
                                }
                                Button("Delete", role: .destructive) { store.remove(item) }
                            }
                        }
                    } header: {
                        // Only label the history when favorites are shown above it.
                        if !filteredFavorites.isEmpty {
                            Text("History")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: selection) { _, newValue in
                if let newValue { withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(newValue) } }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: query.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(query.isEmpty ? "No history yet\nCopy something and it shows up here" : "No matching items")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(store.items.count == 1 ? "1 item" : "\(store.items.count) items")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                Button("Add Favorite…") { startNewFavorite() }
                Divider()
                if LaunchAtLogin.isAvailable {
                    Toggle("Launch at Login", isOn: launchAtLoginBinding)
                } else {
                    Button("Launch at Login (requires .app)") { }
                        .disabled(true)
                }
                Divider()
                Button("Clear History") { store.clear() }
                    .disabled(store.items.isEmpty)
                Divider()
                Button("Quit Clipdon") { onQuit() }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Favorite editor

    private var editorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(editingID == nil ? "Add Favorite" : "Edit Favorite")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Label (optional)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("e.g. Deploy to prod", text: $editLabel)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Content")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextEditor(text: $editText)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.15))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack {
                Spacer()
                Button("Cancel") { showingEditor = false }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { saveEditor() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
    }

    /// Reads/writes the login-item state through `SMAppService`.
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { LaunchAtLogin.isEnabled },
            set: { LaunchAtLogin.setEnabled($0) }
        )
    }

    // MARK: - Editor actions

    private func startNewFavorite() {
        editingID = nil
        editLabel = ""
        editText = ""
        showingEditor = true
    }

    private func startEdit(_ fav: Favorite) {
        editingID = fav.id
        editLabel = fav.label
        editText = fav.text
        showingEditor = true
    }

    private func saveEditor() {
        guard !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let label = editLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = editingID {
            favorites.update(id: id, label: label, text: editText)
        } else {
            favorites.add(label: label, text: editText)
        }
        showingEditor = false
    }

    // MARK: - Keyboard navigation

    private func moveSelection(_ delta: Int) {
        let ids = orderedIDs
        guard !ids.isEmpty else { return }
        if let sel = selection, let idx = ids.firstIndex(of: sel) {
            selection = ids[max(0, min(ids.count - 1, idx + delta))]
        } else {
            selection = ids.first
        }
    }

    private func copySelected() {
        if let id = selection ?? orderedIDs.first, let target = text(for: id) {
            onCopy(target)
        }
    }
}

/// A single favorite row: a star, the label (or text preview), and — when a
/// label is set — the underlying text as a secondary line.
private struct FavoriteRow: View {
    let fav: Favorite
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(fav.displayTitle)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: fav.label.isEmpty ? .regular : .medium))
                if !fav.label.isEmpty {
                    Text(fav.preview)
                        .lineLimit(1)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 4)
            if fav.lineCount > 1 {
                Text("\(fav.lineCount) lines")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// A single history row.
private struct RowView: View {
    let item: ClipItem
    let selected: Bool
    var favorited: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .lineLimit(1)
                    .font(.system(size: 13))
                Text(Self.formatter.localizedString(for: item.date, relativeTo: Date()))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if favorited {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow.opacity(0.8))
            }
            if item.lineCount > 1 {
                Text("\(item.lineCount) lines")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()
}
