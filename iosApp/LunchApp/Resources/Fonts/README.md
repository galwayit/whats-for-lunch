# Plus Jakarta Sans

Drop the static TTF files from the Plus Jakarta Sans release (OFL licensed,
https://github.com/tokotype/PlusJakartaSans) into this folder. The Xcode project uses a
synchronised folder, so the files are picked up automatically; `Info.plist` already lists
them under `UIAppFonts`.

Exact file names expected (PostScript names in brackets, used by `LunchFont`):

| File | PostScript name | Token weight |
|---|---|---|
| `PlusJakartaSans-Regular.ttf` | `PlusJakartaSans-Regular` | 400 |
| `PlusJakartaSans-Medium.ttf` | `PlusJakartaSans-Medium` | 500 |
| `PlusJakartaSans-SemiBold.ttf` | `PlusJakartaSans-SemiBold` | 600 |
| `PlusJakartaSans-Bold.ttf` | `PlusJakartaSans-Bold` | 700 |
| `PlusJakartaSans-ExtraBold.ttf` | `PlusJakartaSans-ExtraBold` | 800 |

Until the files are present `LunchFont` falls back to the system font with the rounded
design at the same sizes and weights (`DesignSystem/Theme.swift`). No code change is
needed after adding the files; `LunchFont.isCustomFontAvailable` flips to `true` at launch.
