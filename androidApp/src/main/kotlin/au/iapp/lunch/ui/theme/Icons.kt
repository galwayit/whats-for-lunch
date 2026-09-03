/**
 * @file Icons.kt
 * @description One LunchIcon per Material Symbols name in design/tokens.json `icons.set`. Until
 * the Material Symbols Rounded subset is added under res/drawable as `ms_<name>.xml` (and
 * `ms_<name>_fill.xml` for the filled variant; see res/README.md), `painter()` returns
 * a Material Icons stand-in from androidx.compose.material.icons.
 *
 * Stand-in mapping (Material Symbols name → Material Icons Outlined / Rounded vector):
 *
 * | Symbol                | Stand-in                    |
 * |-----------------------|-----------------------------|
 * | home                  | Home                        |
 * | explore               | Explore                     |
 * | analytics             | Analytics                   |
 * | person                | Person                      |
 * | restaurant            | Restaurant                  |
 * | restaurant_menu       | RestaurantMenu              |
 * | local_fire_department | LocalFireDepartment         |
 * | notifications         | Notifications               |
 * | search                | Search                      |
 * | expand_more           | ExpandMore                  |
 * | filter_list           | FilterList                  |
 * | favorite              | FavoriteBorder / Favorite   |
 * | star                  | StarOutline / Star          |
 * | payments              | Payments                    |
 * | near_me               | NearMe                      |
 * | arrow_back            | AutoMirrored ArrowBack      |
 * | chevron_right         | ChevronRight                |
 * | close                 | Close                       |
 * | check                 | Check                       |
 * | add                   | Add                         |
 * | history               | History                     |
 * | schedule              | Schedule                    |
 * | calendar_today        | CalendarToday               |
 * | location_on           | LocationOn                  |
 * | directions            | Directions                  |
 * | map                   | Map                         |
 * | tune                  | Tune                        |
 * | shield                | Shield                      |
 * | help                  | AutoMirrored Help           |
 * | info                  | Info                        |
 * | celebration           | Celebration                 |
 * | eco                   | Eco                         |
 * | psychology            | Psychology                  |
 * | delivery_dining       | DeliveryDining              |
 * | takeout_dining        | TakeoutDining               |
 * | shopping_cart         | ShoppingCart                |
 * | local_cafe            | LocalCafe                   |
 * | attach_money          | AttachMoney                 |
 * | group                 | Group                       |
 * | group_add             | GroupAdd                    |
 * | share                 | Share                       |
 * | event                 | Event                       |
 * | event_available       | EventAvailable              |
 * | event_busy            | EventBusy                   |
 * | mail                  | Mail                        |
 * | send                  | AutoMirrored Send           |
 * | workspace_premium     | WorkspacePremium            |
 * | lock                  | Lock                        |
 * | lock_open             | LockOpen                    |
 * | refresh               | Refresh                     |
 * | error                 | ErrorOutline / Error        |
 * | wifi_off              | WifiOff                     |
 * | cloud_off             | CloudOff                    |
 * | auto_awesome          | AutoAwesome                 |
 * | edit                  | Edit                        |
 * | delete                | Delete                      |
 * | download              | Download                    |
 * | logout                | AutoMirrored Logout         |
 * | login                 | AutoMirrored Login          |
 * | settings              | Settings                    |
 * | visibility            | Visibility                  |
 * | visibility_off        | VisibilityOff               |
 * | more_horiz            | MoreHoriz                   |
 *
 * The Outlined theme stands in for the default weight-400 symbol and the Rounded theme for the
 * filled variant (selected tabs, favourited hearts).
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.theme

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Help
import androidx.compose.material.icons.automirrored.outlined.Login
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.Help
import androidx.compose.material.icons.automirrored.rounded.Login
import androidx.compose.material.icons.automirrored.rounded.Logout
import androidx.compose.material.icons.automirrored.rounded.Send
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Analytics
import androidx.compose.material.icons.outlined.AttachMoney
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Celebration
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DeliveryDining
import androidx.compose.material.icons.outlined.Directions
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Eco
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Event
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.GroupAdd
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.Mail
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.NearMe
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Psychology
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Restaurant
import androidx.compose.material.icons.outlined.RestaurantMenu
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.ShoppingCart
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.TakeoutDining
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.WifiOff
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Analytics
import androidx.compose.material.icons.rounded.AttachMoney
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.CalendarToday
import androidx.compose.material.icons.rounded.Celebration
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.CloudOff
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.DeliveryDining
import androidx.compose.material.icons.rounded.Directions
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.Eco
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.Event
import androidx.compose.material.icons.rounded.EventAvailable
import androidx.compose.material.icons.rounded.EventBusy
import androidx.compose.material.icons.rounded.ExpandMore
import androidx.compose.material.icons.rounded.Explore
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FilterList
import androidx.compose.material.icons.rounded.Group
import androidx.compose.material.icons.rounded.GroupAdd
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.LocalCafe
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.LockOpen
import androidx.compose.material.icons.rounded.Mail
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.NearMe
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.Payments
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Restaurant
import androidx.compose.material.icons.rounded.RestaurantMenu
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material.icons.rounded.ShoppingCart
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.TakeoutDining
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material.icons.rounded.Visibility
import androidx.compose.material.icons.rounded.VisibilityOff
import androidx.compose.material.icons.rounded.WifiOff
import androidx.compose.material.icons.rounded.WorkspacePremium
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp

/**
 * @param materialName The Material Symbols name; also the drawable suffix (`ms_<name>`).
 * @param outlined Stand-in for the default symbol.
 * @param filled Stand-in for the filled variant.
 */
enum class LunchIcon(val materialName: String, val outlined: ImageVector, val filled: ImageVector) {
    Home("home", Icons.Outlined.Home, Icons.Rounded.Home),
    Explore("explore", Icons.Outlined.Explore, Icons.Rounded.Explore),
    Analytics("analytics", Icons.Outlined.Analytics, Icons.Rounded.Analytics),
    Person("person", Icons.Outlined.Person, Icons.Rounded.Person),
    Restaurant("restaurant", Icons.Outlined.Restaurant, Icons.Rounded.Restaurant),
    RestaurantMenu("restaurant_menu", Icons.Outlined.RestaurantMenu, Icons.Rounded.RestaurantMenu),
    LocalFireDepartment("local_fire_department", Icons.Outlined.LocalFireDepartment, Icons.Rounded.LocalFireDepartment),
    Notifications("notifications", Icons.Outlined.Notifications, Icons.Rounded.Notifications),
    Search("search", Icons.Outlined.Search, Icons.Rounded.Search),
    ExpandMore("expand_more", Icons.Outlined.ExpandMore, Icons.Rounded.ExpandMore),
    FilterList("filter_list", Icons.Outlined.FilterList, Icons.Rounded.FilterList),
    Favorite("favorite", Icons.Outlined.FavoriteBorder, Icons.Rounded.Favorite),
    Star("star", Icons.Outlined.StarOutline, Icons.Rounded.Star),
    Payments("payments", Icons.Outlined.Payments, Icons.Rounded.Payments),
    NearMe("near_me", Icons.Outlined.NearMe, Icons.Rounded.NearMe),
    ArrowBack("arrow_back", Icons.AutoMirrored.Outlined.ArrowBack, Icons.AutoMirrored.Rounded.ArrowBack),
    ChevronRight("chevron_right", Icons.Outlined.ChevronRight, Icons.Rounded.ChevronRight),
    Close("close", Icons.Outlined.Close, Icons.Rounded.Close),
    Check("check", Icons.Outlined.Check, Icons.Rounded.Check),
    Add("add", Icons.Outlined.Add, Icons.Rounded.Add),
    History("history", Icons.Outlined.History, Icons.Rounded.History),
    Schedule("schedule", Icons.Outlined.Schedule, Icons.Rounded.Schedule),
    CalendarToday("calendar_today", Icons.Outlined.CalendarToday, Icons.Rounded.CalendarToday),
    LocationOn("location_on", Icons.Outlined.LocationOn, Icons.Rounded.LocationOn),
    Directions("directions", Icons.Outlined.Directions, Icons.Rounded.Directions),
    Map("map", Icons.Outlined.Map, Icons.Rounded.Map),
    Tune("tune", Icons.Outlined.Tune, Icons.Rounded.Tune),
    Shield("shield", Icons.Outlined.Shield, Icons.Rounded.Shield),
    Help("help", Icons.AutoMirrored.Outlined.Help, Icons.AutoMirrored.Rounded.Help),
    Info("info", Icons.Outlined.Info, Icons.Rounded.Info),
    Celebration("celebration", Icons.Outlined.Celebration, Icons.Rounded.Celebration),
    Eco("eco", Icons.Outlined.Eco, Icons.Rounded.Eco),
    Psychology("psychology", Icons.Outlined.Psychology, Icons.Rounded.Psychology),
    DeliveryDining("delivery_dining", Icons.Outlined.DeliveryDining, Icons.Rounded.DeliveryDining),
    TakeoutDining("takeout_dining", Icons.Outlined.TakeoutDining, Icons.Rounded.TakeoutDining),
    ShoppingCart("shopping_cart", Icons.Outlined.ShoppingCart, Icons.Rounded.ShoppingCart),
    LocalCafe("local_cafe", Icons.Outlined.LocalCafe, Icons.Rounded.LocalCafe),
    AttachMoney("attach_money", Icons.Outlined.AttachMoney, Icons.Rounded.AttachMoney),
    Group("group", Icons.Outlined.Group, Icons.Rounded.Group),
    GroupAdd("group_add", Icons.Outlined.GroupAdd, Icons.Rounded.GroupAdd),
    Share("share", Icons.Outlined.Share, Icons.Rounded.Share),
    Event("event", Icons.Outlined.Event, Icons.Rounded.Event),
    EventAvailable("event_available", Icons.Outlined.EventAvailable, Icons.Rounded.EventAvailable),
    EventBusy("event_busy", Icons.Outlined.EventBusy, Icons.Rounded.EventBusy),
    Mail("mail", Icons.Outlined.Mail, Icons.Rounded.Mail),
    Send("send", Icons.AutoMirrored.Outlined.Send, Icons.AutoMirrored.Rounded.Send),
    WorkspacePremium("workspace_premium", Icons.Outlined.WorkspacePremium, Icons.Rounded.WorkspacePremium),
    Lock("lock", Icons.Outlined.Lock, Icons.Rounded.Lock),
    LockOpen("lock_open", Icons.Outlined.LockOpen, Icons.Rounded.LockOpen),
    Refresh("refresh", Icons.Outlined.Refresh, Icons.Rounded.Refresh),
    Error("error", Icons.Outlined.ErrorOutline, Icons.Rounded.Error),
    WifiOff("wifi_off", Icons.Outlined.WifiOff, Icons.Rounded.WifiOff),
    CloudOff("cloud_off", Icons.Outlined.CloudOff, Icons.Rounded.CloudOff),
    AutoAwesome("auto_awesome", Icons.Outlined.AutoAwesome, Icons.Rounded.AutoAwesome),
    Edit("edit", Icons.Outlined.Edit, Icons.Rounded.Edit),
    Delete("delete", Icons.Outlined.Delete, Icons.Rounded.Delete),
    Download("download", Icons.Outlined.Download, Icons.Rounded.Download),
    Logout("logout", Icons.AutoMirrored.Outlined.Logout, Icons.AutoMirrored.Rounded.Logout),
    Login("login", Icons.AutoMirrored.Outlined.Login, Icons.AutoMirrored.Rounded.Login),
    Settings("settings", Icons.Outlined.Settings, Icons.Rounded.Settings),
    Visibility("visibility", Icons.Outlined.Visibility, Icons.Rounded.Visibility),
    VisibilityOff("visibility_off", Icons.Outlined.VisibilityOff, Icons.Rounded.VisibilityOff),
    MoreHoriz("more_horiz", Icons.Outlined.MoreHoriz, Icons.Rounded.MoreHoriz),
    ;

    /** Drawable name of the Material Symbols asset once added: `ms_<name>` or `ms_<name>_fill`. */
    fun drawableName(filled: Boolean): String = if (filled) "${DRAWABLE_PREFIX}${materialName}_fill" else "$DRAWABLE_PREFIX$materialName"

    /**
     * The icon painter. Prefers `res/drawable/ms_<name>.xml` (falling back to the unfilled
     * asset when only that exists), otherwise the Material Icons stand-in.
     */
    @Composable
    fun painter(filled: Boolean = false): Painter {
        val context = LocalContext.current
        val resId = remember(context, this, filled) {
            drawableId(context, drawableName(filled)).takeIf { it != 0 }
                ?: if (filled) drawableId(context, drawableName(filled = false)) else 0
        }
        return if (resId != 0) painterResource(resId) else rememberVectorPainter(if (filled) this.filled else outlined)
    }

    companion object {
        const val DRAWABLE_PREFIX = "ms_"

        /** Lookup by name because `R.drawable` members only exist once the files are added. */
        @SuppressLint("DiscouragedApi")
        private fun drawableId(context: android.content.Context, name: String): Int =
            context.resources.getIdentifier(name, "drawable", context.packageName)
    }
}

/**
 * Renders a [LunchIcon] at a fixed square size. Decorative by default (`contentDescription`
 * null); pass one when the icon carries meaning on its own.
 */
@Composable
fun LunchIconView(
    icon: LunchIcon,
    modifier: Modifier = Modifier,
    size: Dp = TokenSize.iconDefault,
    filled: Boolean = false,
    tint: Color = LunchTheme.colors.text,
    contentDescription: String? = null,
) {
    Icon(
        painter = icon.painter(filled),
        contentDescription = contentDescription,
        modifier = modifier.size(size),
        tint = tint,
    )
}
