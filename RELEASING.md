# Clipdon release guide

There are two ways to distribute. **The current goal is Mac App Store (MAS) distribution.**

| Method | What you need | Project |
|---|---|---|
| **Mac App Store** (current) | Paid Developer Program + App Sandbox | `project.yml` → `Clipdon.xcodeproj` (XcodeGen) |
| Direct distribution (reference) | Same + Developer ID + notarization | `build-app.sh` + `notarize.sh` (SPM) |

> **Correction:** an earlier note claimed "Carbon hot keys tend to be rejected in MAS review" — that was **wrong**.
> `RegisterEventHotKey`, `NSPasteboard` monitoring, and `SMAppService` all **work inside the App Sandbox and are fine for MAS**. Clipdon can ship on the Mac App Store.

---

## Mac App Store distribution

### Prerequisites (required)

- **A paid Apple Developer Program membership** ($99/year). You cannot submit to the App Store with a free/Personal Team.
  - You will need an **Apple Distribution certificate** and a **Mac App Store provisioning profile**;
    Xcode's automatic signing generates both once you've joined the paid program.
- In Xcode ▸ Settings ▸ Accounts, add your Apple ID and select the paid team.

### Repo-side preparation (already done)

- ✅ App Sandbox entitlement (`Clipdon.entitlements`)
- ✅ Menu-bar agent `LSUIElement` / category Productivity (`Clipdon-Info.plist`)
- ✅ App icon asset catalog (`Assets.xcassets/AppIcon.appiconset`, including 1024px)
- ✅ XcodeGen config (`project.yml`, with `DEVELOPMENT_TEAM` as a placeholder — set your own `YOUR_TEAM_ID`)
- ✅ Export-compliance declaration (`ITSAppUsesNonExemptEncryption = NO`) so you aren't prompted on every upload
- ✅ Works under the sandbox (history is stored in the app's private container, `~/Library/Containers/org.nexaspark.clipdon/...`)

### Steps

**1. Create the App ID and app record**
- [App Store Connect](https://appstoreconnect.apple.com) ▸ Apps ▸ ＋ ▸ **New App (macOS)**
  - Name: `Clipdon` / Bundle ID: `org.nexaspark.clipdon` / SKU: anything
- If the bundle ID isn't registered yet, Xcode's automatic signing registers it on your first Archive.

**2. Generate and open the project**
```sh
xcodegen generate
open Clipdon.xcodeproj
```
- Target Clipdon ▸ **Signing & Capabilities**:
  - Team = **your paid program team** (not a Personal Team)
  - Turn on "Automatically manage signing" → distribution cert and profile are generated automatically
  - Confirm **App Sandbox** is present (from the entitlements file)

**3. Version / build number**
- `MARKETING_VERSION` (the display version) and `CURRENT_PROJECT_VERSION` (the build number) in `project.yml`.
  **Increment the build number by 1 for every upload** (you can't re-upload the same number). Run `xcodegen generate` after changing it.

**4. Archive**
- Xcode: set the run destination to **My Mac** and choose **Product ▸ Archive**
- Or via CLI:
  ```sh
  xcodebuild -project Clipdon.xcodeproj -scheme Clipdon \
    -configuration Release -archivePath build/Clipdon.xcarchive archive
  ```

**5. Upload**
- In the Xcode **Organizer** (Window ▸ Organizer), select the archive ▸ **Distribute App ▸ App Store Connect ▸ Upload** (recommended, most reliable)
- Or via CLI (using the bundled `ExportOptions.plist`):
  ```sh
  xcodebuild -exportArchive -archivePath build/Clipdon.xcarchive \
    -exportPath build/export -exportOptionsPlist ExportOptions.plist
  ```
  With `destination=upload` it's submitted directly. With `export` it writes a `.pkg`, which you then send with
  [Transporter](https://apps.apple.com/app/transporter/id1450874784) or altool:
  ```sh
  xcrun altool --upload-app -f build/export/Clipdon.pkg -t macos \
    -u "you@example.com" -p "app-specific-password"
  ```

**6. Enter metadata in App Store Connect**
- **Screenshots** (required, at least 1; e.g. 2560×1600) — capturing the popup is recommended
- Description, keywords, support URL, category (Productivity)
- **App Privacy**: Clipdon **stores the clipboard locally and never transmits it** → declare "**Data Not Collected**"
- Price and availability
- **Review notes**: state "A clipboard-history manager. Press `⌘⇧V` to recall history and re-copy. No Accessibility permission required," and include the steps to use it

**7. Submit for review.**

### Things to watch for in review (clipboard apps)

- Reading the clipboard, a global hot key, and login items are all within allowed bounds. Explaining the purpose in the review notes makes them unlikely to be an issue.
- Not requiring the Accessibility permission (by design) is a plus.
- Apps get bounced when the feature is unclear, so make the behavior obvious with review notes + screenshots.

### Common stumbling points

- **Personal Team can't submit** → a paid membership is the prerequisite.
- Increment the build number every time.
- The icon must be an asset catalog that includes a 1024px image (done).
- No private APIs (Carbon is deprecated but it's a public API, so it's fine).

---

## Direct distribution (reference — if not using the App Store)

Distribute a `.zip`/`.dmg` yourself with Developer ID signing + notarization:
```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-app.sh
./notarize.sh
```
(`build-app.sh` builds and signs a universal `.app`; `notarize.sh` notarizes → staples → zips it.)

---

## Remaining "nice to have" items

- Launch-at-login toggle is implemented (`SMAppService`).
- Favorites (pin commands/snippets) are implemented (`FavoritesStore`).
- In-app settings screen (change hot key, history limit).
- `LICENSE` / CHANGELOG.
- Updates: MAS delivers updates through the App Store, so Sparkle isn't needed.
