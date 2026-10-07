import Foundation

/// User preferences for expiration reminders, stored in UserDefaults.
/// Views bind to the same keys with `@AppStorage`.
nonisolated struct ReminderSettings: Equatable, Sendable {
    var isEnabled: Bool
    /// Extra reminder this many days before expiring (0 = only on the day).
    var daysBefore: Int
    /// Time of day for reminders, in minutes after midnight.
    var minutesAfterMidnight: Int

    static let `default` = ReminderSettings(isEnabled: false, daysBefore: 3, minutesAfterMidnight: 9 * 60)

    enum Key {
        static let isEnabled = "reminders.isEnabled"
        static let daysBefore = "reminders.daysBefore"
        static let minutesAfterMidnight = "reminders.minutesAfterMidnight"
    }

    static func load(from defaults: UserDefaults = .standard) -> ReminderSettings {
        ReminderSettings(
            isEnabled: defaults.object(forKey: Key.isEnabled) as? Bool ?? Self.default.isEnabled,
            daysBefore: defaults.object(forKey: Key.daysBefore) as? Int ?? Self.default.daysBefore,
            minutesAfterMidnight: defaults.object(forKey: Key.minutesAfterMidnight) as? Int
                ?? Self.default.minutesAfterMidnight
        )
    }
}
