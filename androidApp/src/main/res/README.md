# Resources

AAPT refuses non-resource files inside `res/font` and `res/drawable`, so the notes for both live here.

## Fonts (res/font)

The display roles (`display`, `title`, `heading` in `design/tokens.json`) are set in **Bricolage
Grotesque**. Every other role uses the system family (`FontFamily.Default`), so only two files
are bundled:

| File | Weight |
| --- | --- |
| `bricolage_grotesque_bold.ttf` | 700 |
| `bricolage_grotesque_extrabold.ttf` | 800 |

Both are static instances cut from the Google Fonts variable file (`ofl/bricolagegrotesque`,
version 1.001) at width 100 and optical size 24, the same files the iOS app bundles. Licence: SIL
Open Font License 1.1, shipped as `assets/BricolageGrotesque-OFL.txt`.

### How they are picked up

`ui/theme/Type.kt` (`LunchFont.resolve`) looks each name up at runtime with
`Resources.getIdentifier(name, "font", packageName)` and builds the display `FontFamily`. If
either file is missing, `LunchTheme.typography.isCustomFontAvailable` is `false`, the display
roles fall back to `FontFamily.Default` at the same size and weight, and the gallery's controls
card says so.

Keep this directory otherwise empty; a stray file with a different name is ignored.

## Icons (res/drawable)

The app uses **Material Symbols Rounded** (see `design/tokens.json`, `icons.set`). Vector
drawables are not committed; export each symbol from https://fonts.google.com/icons as an
Android vector (24dp, weight 400, rounded) and save it here as:

- `ms_<name>.xml` for the outlined (FILL 0) variant, e.g. `ms_restaurant.xml`
- `ms_<name>_fill.xml` for the filled (FILL 1) variant, e.g. `ms_restaurant_fill.xml`

`<name>` is the symbol name exactly as listed in `icons.set` (and as `LunchIcon.materialName` in
`ui/theme/Icons.kt`), e.g. `local_fire_department`, `workspace_premium`.

### How they are picked up

`LunchIconView` / `LunchIcon.painter(filled)` look for `ms_<name>` (or `ms_<name>_fill`) with
`Resources.getIdentifier(..., "drawable", packageName)` at runtime. When the drawable exists it is
used; otherwise the matching `androidx.compose.material.icons` Outlined/Rounded vector is drawn as
a stand-in. No code change is needed after adding the files.

`IconSetTest` keeps the `LunchIcon` enum in sync with `icons.set`; add a new symbol to
`design/tokens.json` first, then to the enum, then export the drawables.

The launcher icon resources (`ic_launcher*`) live in `mipmap-*` and are unrelated.
