import SwiftData
import WidgetKit

/// Side effects that must follow any change to products.
enum ProductSync {
    static func refresh(using context: ModelContext) {
        do {
            // The widget reads the database file, so pending changes must be saved first.
            try context.save()
        } catch {
            assertionFailure("Failed to save products: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
        ReminderScheduler.reschedule(using: context)
        // Lets Siri recognize product names in "Remove <product> from ShelfLife".
        ShelfLifeShortcuts.updateAppShortcutParameters()
    }
}
