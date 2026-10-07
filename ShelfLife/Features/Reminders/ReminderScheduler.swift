import Foundation
import OSLog
import SwiftData
import UserNotifications

/// Talks to the system notification center. Every reschedule makes the pending
/// reminders match the current data exactly.
enum ReminderScheduler {
    private static var rescheduleTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "dev.mateo.ShelfLife", category: "Reminders")

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Number of scheduled reminders, once the latest reschedule has finished.
    static func pendingCount() async -> Int {
        await rescheduleTask?.value
        return await UNUserNotificationCenter.current().pendingNotificationRequests().count
    }

    static func reschedule(using context: ModelContext) {
        let products = (try? context.fetch(FetchDescriptor<Product>())) ?? []
        let items = products.map {
            ReminderPlanner.Item(id: $0.uuid, name: $0.name, expirationDate: $0.expirationDate)
        }
        let reminders = ReminderPlanner.reminders(for: items, settings: .load())

        // A newer reschedule supersedes any one still in flight: cancel it and
        // wait for it to stop, so the two never interleave.
        let previous = rescheduleTask
        previous?.cancel()
        rescheduleTask = Task {
            await previous?.value
            let center = UNUserNotificationCenter.current()
            // Remove only stale reminders. Removal runs asynchronously inside iOS,
            // so "remove all, then add" could delete requests we just added.
            // Adding an existing identifier replaces it, so the rest need no removal.
            let newIDs = Set(reminders.map(\.id))
            let staleIDs = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { !newIDs.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
            logger.debug("Scheduling \(reminders.count) reminders for \(items.count) products")
            for reminder in reminders {
                guard !Task.isCancelled else { return }
                do {
                    try await center.add(request(for: reminder))
                } catch {
                    logger.error("Could not schedule \(reminder.id): \(error)")
                }
            }
        }
    }

    #if DEBUG
    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ShelfLife"
        content.body = "Test reminder: notifications are working."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        Task { try? await UNUserNotificationCenter.current().add(request) }
    }
    #endif

    private static func request(for reminder: ReminderPlanner.Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.productName
        content.body = switch reminder.daysBefore {
        case 0: "Expires today."
        case 1: "Expires tomorrow."
        default: "Expires in \(reminder.daysBefore) days."
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: reminder.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }
}
