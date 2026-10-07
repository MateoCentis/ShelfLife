import SwiftUI
import WidgetKit

struct ExpiringSoonWidgetView: View {
    let entry: ExpiringSoonEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium: medium
            case .accessoryRectangular: rectangular
            default: small
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Families

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer(minLength: 0)
            counts
            Spacer(minLength: 0)
            if let next = entry.upcoming.first {
                Text(next.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                relativeText(for: next)
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                header
                Spacer(minLength: 0)
                counts
            }
            .frame(width: 110, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                if entry.upcoming.isEmpty {
                    Text("No products yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.upcoming) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                relativeText(for: item)
                                    .font(.caption)
                            }
                            Spacer(minLength: 4)
                            // Interactive widget: runs the intent without opening the app.
                            Button(intent: RemoveProductByIDIntent(productID: item.id)) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Remove \(item.name)")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading) {
            Label("ShelfLife", systemImage: "shippingbox.fill")
                .font(.headline)
            Text("\(entry.expiredCount) expired · \(entry.expiringSoonCount) soon")
            if let next = entry.upcoming.first {
                Text(next.name)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pieces

    private var header: some View {
        Label("ShelfLife", systemImage: "shippingbox.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("AccentColor"))
    }

    private var counts: some View {
        VStack(alignment: .leading, spacing: 0) {
            countRow(entry.expiredCount, label: "expired", status: .expired)
            countRow(entry.expiringSoonCount, label: "expiring soon", status: .expiringSoon)
        }
    }

    private func countRow(_ count: Int, label: String, status: ExpirationStatus) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(count)")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(count > 0 ? status.color : .secondary)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func relativeText(for item: ProductEntity) -> some View {
        let days = ExpirationStatus.daysBetween(entry.date, and: item.expirationDate, calendar: .current)
        return Text(ExpirationStatus.relativeDescription(daysRemaining: days))
            .foregroundStyle(ExpirationStatus(daysRemaining: days).color)
    }
}

#Preview(as: .systemSmall) {
    ExpiringSoonWidget()
} timeline: {
    ExpiringSoonEntry.sample
}

#Preview(as: .systemMedium) {
    ExpiringSoonWidget()
} timeline: {
    ExpiringSoonEntry.sample
}
