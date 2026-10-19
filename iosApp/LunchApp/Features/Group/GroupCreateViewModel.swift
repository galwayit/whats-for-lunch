//
//  GroupCreateViewModel.swift
//  LunchApp
//
//  @file GroupCreateViewModel.swift
//  @description State for GroupCreateView: locates the host area through the core LocationProvider and creates the group through GroupRepository.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Observation

@Observable
final class GroupCreateViewModel {
    static let radiusOptions: [Double] = [1, 2, 5]

    var name = ""
    var detailsDraft: GroupDetailsDraft
    var scheduledAt = GroupCreateViewModel.nextWeekdayLunch()
    var radiusKm = 2.0
    private(set) var area: Location?
    private(set) var isLocating = false
    private(set) var isCreating = false
    private(set) var error: CoreError?

    private let core: LunchCoreClient

    init(core: LunchCoreClient) {
        self.core = core
        self.detailsDraft = GroupDetailsDraft(GroupDetails(hostName: core.auth.session?.displayName ?? core.users.current?.name ?? ""))
    }

    var locationSummary: String {
        guard let area else { return isLocating ? Copy.Group.locatingArea : Copy.Group.locationRequired }
        return "\(Copy.Group.locationReady) · \(area.latitude.formatted(.number.precision(.fractionLength(2)))), \(area.longitude.formatted(.number.precision(.fractionLength(2))))"
    }

    func loadArea() async {
        guard area == nil, !isLocating else { return }
        isLocating = true
        error = nil
        defer { isLocating = false }
        do {
            area = try await core.location.current()
        } catch {
            self.error = CoreError.from(error)
        }
    }

    func create() async -> LunchGroup? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, let details = detailsDraft.value, let area, !isCreating else { return nil }
        isCreating = true
        error = nil
        defer { isCreating = false }
        do {
            return try await core.groups.create(
                name: cleanName,
                scheduledAtEpochSeconds: Int64(scheduledAt.timeIntervalSince1970),
                area: area,
                radiusKm: radiusKm,
                details: details
            )
        } catch {
            self.error = CoreError.from(error)
            return nil
        }
    }

    private static func nextWeekdayLunch(now: Date = Date(), calendar: Calendar = .current) -> Date {
        var day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        while calendar.isDateInWeekend(day) {
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }
        return calendar.date(bySettingHour: 12, minute: 30, second: 0, of: day) ?? day
    }
}
