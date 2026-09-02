# Material Symbols Rounded subset

`DesignSystem/Icons.swift` renders SF Symbol stand-ins until the Material Symbols Rounded
SVGs (weight 400, https://fonts.google.com/icons) are added here as template images.

Add the SVGs to `Assets.xcassets` as image sets named exactly after the Material name, with
`Render As: Template Image`, plus a `<name>_fill` variant for the icons that have a filled
state (the tab bar uses the filled variant for the selected tab). `LunchIcon.image(filled:)`
checks `UIImage(named:)` at runtime and prefers the asset when present, so no code changes
are required once the assets exist.

Expected names (63):

home, explore, analytics, person, restaurant, restaurant_menu, local_fire_department,
notifications, search, expand_more, filter_list, favorite, star, payments, near_me,
arrow_back, chevron_right, close, check, add, history, schedule, calendar_today,
location_on, directions, map, tune, shield, help, info, celebration, eco, psychology,
delivery_dining, takeout_dining, shopping_cart, local_cafe, attach_money, group, group_add,
share, event, event_available, event_busy, mail, send, workspace_premium, lock, lock_open,
refresh, error, wifi_off, cloud_off, auto_awesome, edit, delete, download, logout, login,
settings, visibility, visibility_off, more_horiz

Filled variants used by the app: home_fill, explore_fill, analytics_fill, person_fill,
favorite_fill, star_fill.
