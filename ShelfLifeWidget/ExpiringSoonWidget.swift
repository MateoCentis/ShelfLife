import SwiftData
import SwiftUI
import WidgetKit

/// A snapshot of what the widget shows at a given date.
struct ExpiringSoonEntry: TimelineEntry {
    let date: Date
    let expiredCount: Int
    let expiringSoonCount: Int
    let upcoming: [ProductEntity]
}

struct ExpiringSoonProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpiringSoonEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (ExpiringSoonEntry) -> Void) {
        completion(context.isPreview ? .sample : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiringSoonEntry>) -> Void) {
        let entry = loadEntry()
        // "Days remaining" changes at midnight, so ask WidgetKit to reload then.
        // The app also reloads the widget whenever products change.
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date))
        completion(Timeline(entries: [entry], policy: tomorrow.map { .after($0) } ?? .atEnd))
    }

    private func loadEntry(now: Date = .now) -> ExpiringSoonEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let endOfWarning = calendar.date(byAdding: .day, value: ExpirationStatus.warningDays + 1, to: today) ?? today

        do {
            let context = ModelContext(SharedModelContainer.shared)
            let expired = try context.fetchCount(FetchDescriptor<Product>(
                predicate: #Predicate { $0.expirationDate < today }
            ))
            let expiringSoon = try context.fetchCount(FetchDescriptor<Product>(
                predicate: #Predicate { $0.expirationDate >= today && $0.expirationDate < endOfWarning }
            ))
            var upcomingDescriptor = FetchDescriptor<Product>(sortBy: [SortDescriptor(\.expirationDate)])
            upcomingDescriptor.fetchLimit = 3
            let upcoming = try context.fetch(upcomingDescriptor).map {
                ProductEntity(id: $0.uuid, name: $0.name, expirationDate: $0.expirationDate)
            }
            return ExpiringSoonEntry(date: now, expiredCount: expired, expiringSoonCount: expiringSoon, upcoming: upcoming)
        } catch {
            return ExpiringSoonEntry(date: now, expiredCount: 0, expiringSoonCount: 0, upcoming: [])
        }
    }
}

struct ExpiringSoonWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ExpiringSoonWidget", provider: ExpiringSoonProvider()) { entry in
            ExpiringSoonWidgetView(entry: entry)
        }
        .configurationDisplayName("Expiring Soon")
        .description("See what has expired and what expires next.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

extension ExpiringSoonEntry {
    static var sample: ExpiringSoonEntry {
        let now = Date.now
        func inDays(_ days: Int) -> Date { Calendar.current.date(byAdding: .day, value: days, to: now) ?? now }
        return ExpiringSoonEntry(
            date: now,
            expiredCount: 1,
            expiringSoonCount: 3,
            upcoming: [
                ProductEntity(id: UUID(), name: "Ibuprofen 400 mg", expirationDate: inDays(-3)),
                ProductEntity(id: UUID(), name: "Whole Milk 1 L", expirationDate: inDays(0)),
                ProductEntity(id: UUID(), name: "Greek Yogurt", expirationDate: inDays(2)),
            ]
        )
    }
}
