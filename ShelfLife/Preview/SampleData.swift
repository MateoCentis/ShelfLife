import Foundation
import SwiftData

extension Product {
    /// Demo products with dates relative to today, used by previews and the seed launch argument.
    static func samples(now: Date = .now, calendar: Calendar = .current) -> [Product] {
        func inDays(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: now) ?? now
        }
        return [
            Product(name: "Ibuprofen 400 mg", location: "Shelf A2", quantity: 12, expirationDate: inDays(-3)),
            Product(name: "Whole Milk 1 L", location: "Fridge", quantity: 6, expirationDate: inDays(0)),
            Product(name: "Greek Yogurt", location: "Fridge", quantity: 8, expirationDate: inDays(2)),
            Product(name: "Amoxicillin 500 mg", location: "Shelf B1", quantity: 4, expirationDate: inDays(6)),
            Product(name: "Sunscreen SPF 50", location: "Counter", quantity: 3, expirationDate: inDays(45)),
            Product(name: "Vitamin C 1 g", location: "Shelf A1", quantity: 20, expirationDate: inDays(180)),
        ]
    }
}

extension ModelContainer {
    /// In-memory container filled with sample data, for SwiftUI previews.
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(
                for: Product.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            Product.samples().forEach(container.mainContext.insert)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }
}
