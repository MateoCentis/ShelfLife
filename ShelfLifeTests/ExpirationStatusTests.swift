import Foundation
import Testing
@testable import ShelfLife

struct ExpirationStatusTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test(arguments: zip(
        [-30, -1, 0, 7, 8, 365],
        [ExpirationStatus.expired, .expired, .expiringSoon, .expiringSoon, .fresh, .fresh]
    ))
    func statusFromDaysRemaining(days: Int, expected: ExpirationStatus) {
        #expect(ExpirationStatus(daysRemaining: days) == expected)
    }

    @Test func daysBetweenIgnoresTimeOfDay() {
        // 23:59 today → 00:01 tomorrow is still one calendar day.
        let lateTonight = Date(timeIntervalSince1970: 1_791_590_340) // 2026-10-09 23:59 UTC
        let earlyTomorrow = lateTonight.addingTimeInterval(120)
        #expect(ExpirationStatus.daysBetween(lateTonight, and: earlyTomorrow, calendar: calendar) == 1)
    }

    @Test func daysBetweenIsNegativeForPastDates() {
        let now = Date(timeIntervalSince1970: 1_791_590_340)
        let threeDaysAgo = now.addingTimeInterval(-3 * 86_400)
        #expect(ExpirationStatus.daysBetween(now, and: threeDaysAgo, calendar: calendar) == -3)
    }
}
