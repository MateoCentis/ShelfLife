import Foundation

/// How close a product is to expiring. Pure logic, so it is `nonisolated`
/// (usable from any thread or actor) and easy to unit test.
nonisolated enum ExpirationStatus: Int, CaseIterable, Sendable {
    case expired
    case expiringSoon
    case fresh

    static let warningDays = 7

    init(daysRemaining: Int, warningDays: Int = ExpirationStatus.warningDays) {
        switch daysRemaining {
        case ..<0: self = .expired
        case 0...warningDays: self = .expiringSoon
        default: self = .fresh
        }
    }

    /// Whole calendar days between two dates, ignoring the time of day.
    static func daysBetween(_ start: Date, and end: Date, calendar: Calendar) -> Int {
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
