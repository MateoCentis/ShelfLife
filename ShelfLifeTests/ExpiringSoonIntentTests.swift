import Foundation
import Testing
@testable import ShelfLife

struct ExpiringSoonIntentTests {
    private let english = Locale(identifier: "en_US")

    @Test func summaryWhenNothingExpires() {
        #expect(ExpiringSoonIntent.summary(for: [], locale: english) == "Nothing expires in the next 7 days.")
    }

    @Test func summaryForOneProduct() {
        #expect(ExpiringSoonIntent.summary(for: ["Milk"], locale: english) == "Milk needs attention.")
    }

    @Test func summaryListsSeveralProducts() {
        let summary = ExpiringSoonIntent.summary(for: ["Milk", "Yogurt", "Ibuprofen"], locale: english)
        #expect(summary == "3 products need attention: Milk, Yogurt, and Ibuprofen.")
    }
}
