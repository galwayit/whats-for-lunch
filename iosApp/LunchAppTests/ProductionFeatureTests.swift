import Foundation
import PDFKit
import Testing
@testable import LunchApp

@MainActor
struct ProductionFeatureTests {
    @Test func signed_out_purchase_and_restore_are_blocked() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: false))
        let model = PaywallViewModel(core: core)
        await model.load()
        await model.purchase(model.monthly!)
        #expect(!model.isSubscribed)
        #expect(model.error == .gate(.signInRequired))
        _ = await model.restore()
        #expect(!core.entitlements.isPro)
    }

    @Test func group_ai_requires_consent_and_honours_withdrawal() async {
        let defaults = UserDefaults(suiteName: "ProductionFeatureTests.\(UUID().uuidString)")!
        let consent = AIDataConsent(defaults: defaults)
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = GroupProposalsViewModel(core: core, groupId: PreviewData.group.id, consent: consent)
        await model.load()
        #expect(model.needsConsent)
        consent.grant(version: "preview-ai-v2")
        await model.load()
        #expect(!model.needsConsent)
        consent.revoke()
        await model.load()
        #expect(model.needsConsent)
    }

    @Test func pdf_contains_all_meals_and_paginates_long_notes() {
        let meals = (0..<80).map { index in
            Meal(id: Int64(index), userId: 1, restaurantId: nil, restaurantName: "Fictional cafe \(index)", mealType: "lunch", cost: 12.5, dateEpochSeconds: 1_790_812_800, notes: String(repeating: "A fictional meal note. ", count: 12), photoIds: [])
        }
        let bytes = MealReportPDF.data(profile: PreviewData.user, meals: meals, exportedAt: Date(timeIntervalSince1970: 1_790_812_800))
        let pdf = PDFDocument(data: bytes)
        #expect((pdf?.pageCount ?? 0) > 1)
        #expect(pdf?.string?.contains("Fictional cafe 0") == true)
        #expect(pdf?.string?.contains("Fictional cafe 79") == true)
    }

    @Test func free_user_keeps_json_export_but_cannot_export_pro_pdf() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false))
        let model = ProfileViewModel(core: core, tokens: PreviewSignInTokens())
        #expect(await model.exportPDF(user: PreviewData.user) == nil)
        #expect(model.error == .gate(.historyWindow))
        let json = await model.exportData(user: PreviewData.user)
        #expect(json != nil)
        if let json { try? FileManager.default.removeItem(at: json) }
    }
}
