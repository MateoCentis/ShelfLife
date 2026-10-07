import AppIntents
import SwiftData

/// How a product is exposed to Siri, Shortcuts, Spotlight and widgets.
/// App Intents work with these lightweight values, never with SwiftData models directly.
nonisolated struct ProductEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Product"
    static let defaultQuery = ProductQuery()

    let id: UUID
    let name: String
    let expirationDate: Date

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "Expires \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
        )
    }
}

extension ProductEntity {
    @MainActor
    init(product: Product) {
        self.init(id: product.uuid, name: product.name, expirationDate: product.expirationDate)
    }
}

/// Lets the system look products up by ID, by name, or suggest them in a picker.
nonisolated struct ProductQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ProductEntity] {
        try fetch(#Predicate { identifiers.contains($0.uuid) })
    }

    @MainActor
    func entities(matching string: String) async throws -> [ProductEntity] {
        try fetch(#Predicate { $0.name.localizedStandardContains(string) })
    }

    @MainActor
    func suggestedEntities() async throws -> [ProductEntity] {
        try fetch(nil)
    }

    @MainActor
    private func fetch(_ predicate: Predicate<Product>?) throws -> [ProductEntity] {
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.expirationDate)])
        return try SharedModelContainer.shared.mainContext.fetch(descriptor).map(ProductEntity.init(product:))
    }
}
