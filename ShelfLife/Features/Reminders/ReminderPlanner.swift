import Foundation

/// Decides which reminders to schedule. Pure logic with no iOS APIs, so it is unit tested.
nonisolated enum ReminderPlanner {
    /// iOS keeps at most 64 pending local notifications per app.
    static let maxPendingRequests = 64

    struct Item: Sendable {
        let id: UUID
        let name: String
        let expirationDate: Date
    }

    struct Reminder: Equatable, Sendable {
        let id: String
        let productName: String
        let fireDate: Date
        /// 0 means the reminder fires on the expiration day itself.
        let daysBefore: Int
    }

    static func reminders(
        for items: [Item],
        settings: ReminderSettings,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Reminder] {
        guard settings.isEnabled else { return [] }

        let offsets = settings.daysBefore > 0 ? [settings.daysBefore, 0] : [0]
        let hour = settings.minutesAfterMidnight / 60
        let minute = settings.minutesAfterMidnight % 60

        let reminders = items.flatMap { item in
            offsets.compactMap { daysBefore -> Reminder? in
                guard
                    let day = calendar.date(byAdding: .day, value: -daysBefore, to: item.expirationDate),
                    let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                    fireDate > now
                else { return nil }
                return Reminder(
                    id: "\(item.id.uuidString)-\(daysBefore)",
                    productName: item.name,
                    fireDate: fireDate,
                    daysBefore: daysBefore
                )
            }
        }
        // Keep the soonest ones; the rest get scheduled on a later refresh.
        return Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(maxPendingRequests))
    }
}
