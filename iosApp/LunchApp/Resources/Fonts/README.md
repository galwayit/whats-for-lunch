# Bricolage Grotesque

The display roles (`display`, `title`, `heading` in `design/tokens.json`) are set in Bricolage
Grotesque. Every other role uses the system text face, so there are only two files here. The
Xcode project uses a synchronised folder, so they are bundled automatically; `Info.plist` lists
them under `UIAppFonts`.

| File | PostScript name | Token weight |
|---|---|---|
| `BricolageGrotesque-Bold.ttf` | `BricolageGrotesque-Bold` | 700 |
| `BricolageGrotesque-ExtraBold.ttf` | `BricolageGrotesque-ExtraBold` | 800 |

Both are static instances cut from the Google Fonts variable file
(`ofl/bricolagegrotesque`, version 1.001) at width 100 and optical size 24 with
`fontTools.varLib.instancer`, then renamed to the PostScript names above. The same two files
ship in the Android app as `res/font/bricolage_grotesque_*.ttf`.

Licence: SIL Open Font License 1.1, in `BricolageGrotesque-OFL.txt`, which ships in the bundle
alongside the fonts as the licence requires.

If the files are missing `LunchFont.isCustomFontAvailable` is `false` and the display roles fall
back to the system font at the same sizes and weights (`DesignSystem/Theme.swift`).
