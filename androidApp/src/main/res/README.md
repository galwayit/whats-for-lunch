# Resources

AAPT refuses non-resource files inside `res/font` and `res/drawable`, so the notes for both live here.

## Fonts (res/font)

The design system's type family is **Plus Jakarta Sans** (see `design/tokens.json`, `type.family`).
Font files are not committed; download them from Google Fonts and drop them here with exactly
these names (lower-case, underscores, `.ttf`):

| File | Weight |
| --- | --- |
| `plus_jakarta_sans_regular.ttf` | 400 |
| `plus_jakarta_sans_medium.ttf` | 500 |
| `plus_jakarta_sans_semibold.ttf` | 600 |
| `plus_jakarta_sans_bold.ttf` | 700 |
| `plus_jakarta_sans_extrabold.ttf` | 800 |

### How they are picked up

`ui/theme/Type.kt` (`LunchFont.resolve`) looks each name up at runtime with
`Resources.getIdentifier(name, "font", packageName)` and builds a `FontFamily` from the ones it
finds. No code change is needed after adding the files: rebuild and
`LunchTheme.typography.isCustomFontAvailable` becomes `true` (the gallery's controls card shows
"Plus Jakarta Sans loaded from res/font"). Until then every text role falls back to
`FontFamily.Default` (Roboto) at the same size, weight, line height and tracking.

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
