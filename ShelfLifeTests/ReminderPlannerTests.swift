import Foundation
import Testing
@testable import ShelfLife

struct ReminderPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-10-07 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_791_374_400)

    private func date(daysFromNow days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: now)!
    }

    private func item(_ name: String, expiresInDays days: Int) -> ReminderPlanner.Item {
        ReminderPlanner.Item(id: UUID(), name: name, expirationDate: date(daysFromNow: days))
    }

    private let enabled = ReminderSettings(isEnabled: true, daysBefore: 3, minutesAfterMidnight: 9 * 60)

    @Test func disabledSettingsScheduleNothing() {
        var settings = enabled
        settings.isEnabled = false
        let reminders = ReminderPlanner.reminders(
            for: [item("Milk", expiresInDays: 10)], settings: settings, now: now, calendar: calendar
        )
        #expect(reminders.isEmpty)
    }

    @Test func schedulesEarlyReminderAndExpirationDayAtConfiguredTime() throws {
        let reminders = ReminderPlanner.reminders(
            for: [item("Milk", expiresInDays: 10)], settings: enabled, now: now, calendar: calendar
        )
        #expect(reminders.map(\.daysBefore) == [3, 0])

        let first = try #require(reminders.first)
        let components = calendar.dateComponents([.day, .hour, .minute], from: first.fireDate)
        #expect(components.day == 14) // Oct 17 expiration − 3 days
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }

    @Test func skipsRemindersThatWouldFireInThePast() {
        // Expires in 2 days: the "3 days before" reminder is already in the past.
        let reminders = ReminderPlanner.reminders(
            for: [item("Yogurt", expiresInDays: 2)], settings: enabled, now: now, calendar: calendar
        )
        #expect(reminders.map(\.daysBefore) == [0])
    }

    @Test func capsAtSystemLimitKeepingTheSoonest() {
        let items = (1...100).map { item("Item \($0)", expiresInDays: $0 + 5) }
        let reminders = ReminderPlanner.reminders(for: items, settings: enabled, now: now, calendar: calendar)

        #expect(reminders.count == ReminderPlanner.maxPendingRequests)
        #expect(reminders.map(\.fireDate) == reminders.map(\.fireDate).sorted())
        #expect(reminders.first?.productName == "Item 1")
    }
}
