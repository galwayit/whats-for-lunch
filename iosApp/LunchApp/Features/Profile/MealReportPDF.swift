import UIKit
import CoreText

/// A printable report of the complete local journal. CoreText paginates even long notes.
enum MealReportPDF {
    static func data(profile: UserProfile, meals: [Meal], exportedAt: Date) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let body = NSMutableAttributedString(string: "")
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = 9
        let normal: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph,
        ]
        func append(_ text: String, bold: Bool = false) {
            var attributes = normal
            if bold { attributes[.font] = UIFont.boldSystemFont(ofSize: 12) }
            body.append(NSAttributedString(string: text + "\n", attributes: attributes))
        }
        let currency = NumberFormatter()
        currency.numberStyle = .currency
        currency.locale = Locale(identifier: "en_AU")
        currency.currencyCode = "AUD"
        func money(_ value: Double) -> String { currency.string(from: NSNumber(value: value)) ?? String(format: "A$%.2f", value) }
        let date = DateFormatter()
        date.dateStyle = .medium
        append("Meal journal for \(profile.name)", bold: true)
        append("Exported \(date.string(from: exportedAt)) · Amounts in AUD")
        append("\(meals.count) meals · Total \(money(meals.reduce(0) { $0 + $1.cost }))", bold: true)
        if meals.isEmpty { append("No meals have been logged yet.") }
        for meal in meals.sorted(by: { $0.dateEpochSeconds > $1.dateEpochSeconds }) {
            append("\(date.string(from: meal.date)) · \(meal.mealType.replacingOccurrences(of: "_", with: " ").capitalized) · \(money(meal.cost))", bold: true)
            if let restaurant = meal.restaurantName, !restaurant.isEmpty { append(restaurant) }
            if let notes = meal.notes, !notes.isEmpty { append(notes) }
        }
        let framesetter = CTFramesetterCreateWithAttributedString(body)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: "Lunch Pro meal journal", kCGPDFContextCreator as String: "What We Have for Lunch"]
        return UIGraphicsPDFRenderer(bounds: page, format: format).pdfData { context in
            var offset = 0
            var pageNumber = 0
            repeat {
                context.beginPage()
                pageNumber += 1
                ("LUNCH PRO · MEAL JOURNAL" as NSString).draw(at: CGPoint(x: 42, y: 30), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black])
                ("Page \(pageNumber) · Personal record" as NSString).draw(at: CGPoint(x: 42, y: 810), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray])
                let cg = context.cgContext
                cg.saveGState()
                cg.translateBy(x: 0, y: page.height)
                cg.scaleBy(x: 1, y: -1)
                let path = CGPath(rect: CGRect(x: 42, y: 48, width: 511, height: 725), transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
                CTFrameDraw(frame, cg)
                cg.restoreGState()
                let visible = CTFrameGetVisibleStringRange(frame)
                guard visible.length > 0 else { break }
                offset += visible.length
            } while offset < body.length
        }
    }
}
