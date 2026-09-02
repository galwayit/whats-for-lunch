//
//  Icons.swift
//  LunchApp
//
//  One case per Material Symbols name in design/tokens.json `icons.set`. Until the Material
//  Symbols Rounded SVG subset is added under Resources/Icons (as template image sets named
//  after the Material name, plus `<name>_fill` variants), `image` returns an SF Symbol
//  stand-in; the mapping is the `sfSymbolName` table below.
//

import SwiftUI
import UIKit

enum LunchIcon: String, CaseIterable {
    case home, explore, analytics, person, restaurant
    case restaurantMenu = "restaurant_menu"
    case localFireDepartment = "local_fire_department"
    case notifications, search
    case expandMore = "expand_more"
    case filterList = "filter_list"
    case favorite, star, payments
    case nearMe = "near_me"
    case arrowBack = "arrow_back"
    case chevronRight = "chevron_right"
    case close, check, add, history, schedule
    case calendarToday = "calendar_today"
    case locationOn = "location_on"
    case directions, map, tune, shield, help, info, celebration, eco, psychology
    case deliveryDining = "delivery_dining"
    case takeoutDining = "takeout_dining"
    case shoppingCart = "shopping_cart"
    case localCafe = "local_cafe"
    case attachMoney = "attach_money"
    case group
    case groupAdd = "group_add"
    case share, event
    case eventAvailable = "event_available"
    case eventBusy = "event_busy"
    case mail, send
    case workspacePremium = "workspace_premium"
    case lock
    case lockOpen = "lock_open"
    case refresh, error
    case wifiOff = "wifi_off"
    case cloudOff = "cloud_off"
    case autoAwesome = "auto_awesome"
    case edit, delete, download, logout, login, settings, visibility
    case visibilityOff = "visibility_off"
    case moreHoriz = "more_horiz"

    /// Material name; also the asset name once the SVG subset is added.
    var assetName: String { rawValue }

    /// SF Symbol stand-in used until the Material assets exist.
    var sfSymbolName: String {
        switch self {
        case .home: return "house"
        case .explore: return "safari"
        case .analytics: return "chart.bar"
        case .person: return "person"
        case .restaurant: return "fork.knife"
        case .restaurantMenu: return "menucard"
        case .localFireDepartment: return "flame"
        case .notifications: return "bell"
        case .search: return "magnifyingglass"
        case .expandMore: return "chevron.down"
        case .filterList: return "line.3.horizontal.decrease"
        case .favorite: return "heart"
        case .star: return "star"
        case .payments: return "banknote"
        case .nearMe: return "location"
        case .arrowBack: return "arrow.backward"
        case .chevronRight: return "chevron.right"
        case .close: return "xmark"
        case .check: return "checkmark"
        case .add: return "plus"
        case .history: return "clock.arrow.circlepath"
        case .schedule: return "clock"
        case .calendarToday: return "calendar"
        case .locationOn: return "mappin.and.ellipse"
        case .directions: return "arrow.triangle.turn.up.right.diamond"
        case .map: return "map"
        case .tune: return "slider.horizontal.3"
        case .shield: return "shield"
        case .help: return "questionmark.circle"
        case .info: return "info.circle"
        case .celebration: return "party.popper"
        case .eco: return "leaf"
        case .psychology: return "brain.head.profile"
        case .deliveryDining: return "bicycle"
        case .takeoutDining: return "takeoutbag.and.cup.and.straw"
        case .shoppingCart: return "cart"
        case .localCafe: return "cup.and.saucer"
        case .attachMoney: return "dollarsign"
        case .group: return "person.2"
        case .groupAdd: return "person.badge.plus"
        case .share: return "square.and.arrow.up"
        case .event: return "calendar"
        case .eventAvailable: return "calendar.badge.checkmark"
        case .eventBusy: return "calendar.badge.exclamationmark"
        case .mail: return "envelope"
        case .send: return "paperplane"
        case .workspacePremium: return "crown"
        case .lock: return "lock"
        case .lockOpen: return "lock.open"
        case .refresh: return "arrow.clockwise"
        case .error: return "exclamationmark.circle"
        case .wifiOff: return "wifi.slash"
        case .cloudOff: return "icloud.slash"
        case .autoAwesome: return "sparkles"
        case .edit: return "pencil"
        case .delete: return "trash"
        case .download: return "arrow.down.circle"
        case .logout: return "rectangle.portrait.and.arrow.right"
        case .login: return "person.crop.circle.badge.checkmark"
        case .settings: return "gearshape"
        case .visibility: return "eye"
        case .visibilityOff: return "eye.slash"
        case .moreHoriz: return "ellipsis"
        }
    }

    /// Asset name for the filled variant (selected tabs, favourited hearts).
    var filledAssetName: String { "\(assetName)_fill" }

    /// True when a Material asset with this name is in the bundle.
    static func hasAsset(named name: String) -> Bool {
        UIImage(named: name, in: .main, with: nil) != nil
    }

    /// The icon image. Prefers the Material asset when bundled, else the SF Symbol stand-in.
    var image: Image { image(filled: false) }

    func image(filled: Bool) -> Image {
        let name = filled ? filledAssetName : assetName
        if Self.hasAsset(named: name) {
            return Image(name).renderingMode(.template)
        }
        if filled, Self.hasAsset(named: assetName) {
            return Image(assetName).renderingMode(.template)
        }
        return Image(systemName: sfSymbolName)
    }
}

/// Renders a `LunchIcon` at a fixed square size with the same geometry for both sources.
struct IconView: View {
    let icon: LunchIcon
    var size: CGFloat = Tokens.Size.iconDefault
    var filled = false

    var body: some View {
        icon.image(filled: filled)
            .resizable()
            .scaledToFit()
            .symbolVariant(filled ? .fill : .none)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview("Icon set") {
    let columns = [GridItem(.adaptive(minimum: Tokens.Size.touchTarget), spacing: Tokens.Spacing.sm)]
    LunchPreview {
        LazyVGrid(columns: columns, spacing: Tokens.Spacing.md) {
            ForEach(LunchIcon.allCases, id: \.self) { icon in
                IconView(icon: icon)
                    .foregroundStyle(Tokens.Palette.primary)
                    .accessibilityLabel(icon.rawValue)
            }
        }
    }
}
