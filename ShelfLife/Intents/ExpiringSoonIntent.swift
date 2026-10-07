import AppIntents
import SwiftData
import SwiftUI

/// "What expires soon?" — answers with a spoken summary and a visual snippet.
nonisolated struct ExpiringSoonIntent: AppIntent {
    static let title: LocalizedStringResource = "What Expires Soon"
    static let description = IntentDescription("Lists products that have expired or expire within a week.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let endOfWarning = calendar.date(byAdding: .day, value: ExpirationStatus.warningDays + 1, to: today) ?? today

        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.expirationDate < endOfWarning },
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        let products = try SharedModelContainer.shared.mainContext.fetch(descriptor)
            .map(ProductEntity.init(product:))

        return .result(
            dialog: IntentDialog(stringLiteral: Self.summary(for: products.map(\.name))),
            view: ExpiringSoonSnippet(products: products)
        )
    }

    static func summary(for names: [String], locale: Locale = .current) -> String {
        switch names.count {
        case 0: "Nothing expires in the next \(ExpirationStatus.warningDays) days."
        case 1: "\(names[0]) needs attention."
        default: "\(names.count) products need attention: \(names.formatted(.list(type: .and).locale(locale)))."
        }
    }
}

private struct ExpiringSoonSnippet: View {
    let products: [ProductEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(products.prefix(5)) { product in
                let days = ExpirationStatus.daysBetween(.now, and: product.expirationDate, calendar: .current)
                HStack {
                    Text(product.name)
                        .lineLimit(1)
                    Spacer()
                    Text(ExpirationStatus.relativeDescription(daysRemaining: days))
                        .foregroundStyle(ExpirationStatus(daysRemaining: days).color)
                }
                .font(.subheadline)
            }
        }
        .padding()
    }
}
