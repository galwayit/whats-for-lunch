//
//  SplitBillDemoView.swift
//  LunchApp
//
//  Reachable with `-previewCore -openRoute splitBill`: a realistic split with one adjusted row,
//  for screenshots. Track and Group detail build their own SplitBillViewModel; this route exists
//  only because the sheet has no AppRoute of its own to reach it from a cold launch.
//

import SwiftUI

struct SplitBillDemoView: View {
    @State private var model = SplitBillViewModel.demo()

    var body: some View {
        SplitBillView(model: model, onUseShare: {})
    }
}

extension SplitBillViewModel {
    static func demo() -> SplitBillViewModel {
        let guestNames = acceptedGuestNames(PreviewData.rsvps, hostId: PreviewData.group.hostId)
        let model = SplitBillViewModel(
            guestNames: guestNames,
            placeName: PreviewData.group.placeName,
            defaults: UserDefaults(suiteName: "split.demo") ?? .standard
        )
        model.bill = 86.50
        model.surchargePercent = 1.5
        model.setShare(20, for: guestNames.count)
        return model
    }
}

#Preview("Split bill demo") {
    SplitBillDemoView()
}
