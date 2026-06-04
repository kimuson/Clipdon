# Clipdon

A simple clipboard-history tool that lives in your Mac's menu bar.
Anything you copy with `⌘C` is saved to your history automatically. Press
`⌘⇧V` to bring up a popup **right at your mouse cursor**, where you can search
and re-copy past items.

## Features

- 📋 **Lives in the menu bar** — an agent app that keeps your Dock clean
- 🖱 **Appears at the cursor** — the popup opens wherever you press `⌘⇧V` (or click the menu-bar icon)
- 🔍 **Built-in search** — type to filter
- ⌨️ **Keyboard-driven** — `↑`/`↓` to select, `Enter` to re-copy, `Esc` to close
- 🔁 **Re-copy model** — selecting an item just puts it back on the clipboard; paste it yourself with `⌘V`
- ⭐️ **Favorites** — pin commands and snippets you use often to the top of the popup. Right-click a history item to star it, or add one manually. An optional label lets you name each entry.
- 🔒 **No extra permissions** — no Accessibility or other approvals required
- 💾 **Persistent history** — the latest 200 items are saved to `~/Library/Application Support/Clipdon/history.json` (favorites are saved separately to `favorites.json`, with no limit)
- 🙈 **Skips passwords** — content marked "concealed" by password managers and the like is never kept in history

## Running it

### Try it instantly during development

```sh
swift run
```

A 📋 icon appears in the menu bar. Quit from the "Quit" button in the popup, or
press `Ctrl+C` in the terminal.

### Run it as a resident app

```sh
./build-app.sh
open Clipdon.app
```

This produces `Clipdon.app` (a universal binary). To launch it automatically at
login, add it under **System Settings ▸ General ▸ Login Items**.

## Usage

1. Copy with `⌘C` as usual → it's added to your history automatically
2. Press **`⌘⇧V`** (the popup opens at your cursor)
3. Type to filter, use `↑`/`↓` to select
4. Click or press `Enter` to put the chosen item back on the clipboard
5. Paste it in the original app with `⌘V`

Right-click an item for "Copy", "Delete", and "Add to Favorites".

### Favorites

Pin commands and boilerplate you reuse, kept separate from the rolling history.

- **From history** — right-click a history item → "Add to Favorites" (it gets a ★)
- **Add manually** — the ⚙️ menu in the footer → "Add Favorite…", or the ＋ button on the "Favorites" header
- **Labels** — give an entry a name when adding/editing (e.g. "Deploy to prod"); if set, the list shows the name
- **Edit / delete** — right-click a favorite
- Favorites always appear at the top of the popup and re-copy with `↑`/`↓` → `Enter`, just like history

## Layout

| File | Role |
|---|---|
| `main.swift` | Entry point (launches `NSApplication`) |
| `AppDelegate.swift` | Menu bar, cursor-anchored popup, and wiring of the parts |
| `ClipboardMonitor.swift` | Polls `NSPasteboard` to detect changes |
| `ClipboardStore.swift` | Holds history data and persists it as JSON |
| `ClipItem.swift` | Data model for a single history entry |
| `Favorite.swift` | Data model for a single favorite (with a label) |
| `FavoritesStore.swift` | Holds favorites and persists them as JSON |
| `HotKey.swift` | Registers the global hot key via Carbon |
| `HistoryView.swift` | SwiftUI history view (search + list) |

## Customizing

- **Hot key** — `keyCode` / `modifiers` in `AppDelegate.setUpHotKey()`
- **History limit** — `ClipboardStore.maxItems` (default 200)
- **Polling interval** — the `0.4` seconds in `ClipboardMonitor`
- **Popup size** — `AppDelegate.popupSize`

## Releasing (distribution)

Direct distribution (Developer ID signing + notarization):

```sh
# 1. Build and sign with your Developer ID (Hardened Runtime enabled)
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-app.sh

# 2. Notarize → staple → produce a distributable zip
./notarize.sh
```

See `RELEASING.md` for the full set of preparation steps.
