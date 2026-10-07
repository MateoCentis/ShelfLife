import Foundation
import SwiftData

/// Builds the SwiftData container stored in the App Group, so the app,
/// the widget extension and App Intents read and write the same database file.
nonisolated enum SharedModelContainer {
    static let appGroupID = "group.dev.mateo.ShelfLife"

    /// One container per process, so every context sees the same data.
    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = inMemory
            ? ModelConfiguration(isStoredInMemoryOnly: true)
            : ModelConfiguration(groupContainer: .identifier(appGroupID))
        return try ModelContainer(for: Product.self, configurations: configuration)
    }
}
