import AppIntents
import SwiftData
import WidgetKit

/// Removes a product, e.g. once it was sold or discarded. Available in Siri and Shortcuts.
struct RemoveProductIntent: AppIntent {
    static let title: LocalizedStringResource = "Remove Product"
    static let description = IntentDescription("Removes a product from ShelfLife after it was sold or discarded.")

    @Parameter(title: "Product")
    var product: ProductEntity

    init() {}

    init(product: ProductEntity) {
        self.product = product
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ProductRemoval.remove(id: product.id)
        return .result(dialog: "Removed \(product.name).")
    }
}

/// Widget-only variant. It takes the ID as plain text, so the widget extension
/// doesn't need the system to resolve a `ProductEntity` for it.
struct RemoveProductByIDIntent: AppIntent {
    static let title: LocalizedStringResource = "Remove Product by ID"
    static let isDiscoverable = false

    @Parameter(title: "Product ID")
    var productID: String

    init() {}

    init(productID: UUID) {
        self.productID = productID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: productID) {
            try ProductRemoval.remove(id: id)
        }
        return .result()
    }
}

nonisolated enum ProductRemoval {
    @MainActor
    static func remove(id: UUID) throws {
        let context = SharedModelContainer.shared.mainContext
        let matches = try context.fetch(FetchDescriptor<Product>(predicate: #Predicate { $0.uuid == id }))
        matches.forEach(context.delete)
        try context.save()
        // Reminders are rescheduled the next time the app becomes active.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
