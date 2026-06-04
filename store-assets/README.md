# App Store assets

## Screenshots (`screenshots/`)

macOS screenshots to upload to App Store Connect. They are generated at
**2560×1600** (Retina, 16:10), one of the screenshot sizes the App Store
accepts. (The others are 1280×800 / 1440×900 / 2880×1800.)

| File | Selling point |
|---|---|
| `01-history.png` | Recall your history with ⌘⇧V (core feature) |
| `02-search.png` | Type to filter (search) |
| `03-keyboard.png` | Keyboard-only operation |
| `04-privacy.png` | Local-only storage; sensitive content excluded |
| `05-favorites.png` | Pin frequently used commands & snippets (favorites) |

### Regenerating

```sh
swift tools/make-screenshots.swift
```

No GUI interaction or Screen Recording permission required. `tools/make-screenshots.swift`
renders a faithful replica of the real `HistoryView` offscreen with SwiftUI's
`ImageRenderer` and composites it onto a branded gradient background.

### Changing copy, colors, or sample data

Edit these in `tools/make-screenshots.swift` and re-run:

- the `specs` array — each shot's headline (`headline`) / subhead (`subhead`) /
  background gradient (`grad`) / search term (`query`) / selected row (`selected`)
- `baseRows` — the sample history shown in the popup

### Upload steps (App Store Connect)

1. App Store Connect ▸ your App ▸ the version ▸ **"macOS App" Previews and Screenshots**
2. Drag and drop `screenshots/*.png` (1 minimum, 10 maximum)
3. Reorder by dragging (the `01`→`04` number order is recommended)
