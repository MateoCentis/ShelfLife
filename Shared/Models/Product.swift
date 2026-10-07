import Foundation
import SwiftData

/// A tracked item with an expiration date, persisted locally with SwiftData.
@Model
final class Product {
    /// Stable identifier, used e.g. for notification request IDs.
    var uuid: UUID = UUID()
    var name: String
    var location: String
    var quantity: Int
    var expirationDate: Date
    var barcode: String?
    var notes: String
    var createdAt: Date

    init(
        name: String,
        location: String = "",
        quantity: Int = 1,
        expirationDate: Date,
        barcode: String? = nil,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.location = location
        self.quantity = quantity
        self.expirationDate = expirationDate
        self.barcode = barcode
        self.notes = notes
        self.createdAt = createdAt
    }
}

extension Product {
    func daysRemaining(from now: Date = .now, calendar: Calendar = .current) -> Int {
        ExpirationStatus.daysBetween(now, and: expirationDate, calendar: calendar)
    }

    func status(from now: Date = .now, calendar: Calendar = .current) -> ExpirationStatus {
        ExpirationStatus(daysRemaining: daysRemaining(from: now, calendar: calendar))
    }
}
