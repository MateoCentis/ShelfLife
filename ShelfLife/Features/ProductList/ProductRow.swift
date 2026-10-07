import SwiftUI

struct ProductRow: View {
    let product: Product

    var body: some View {
        let days = product.daysRemaining()
        let status = ExpirationStatus(daysRemaining: days)

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ExpirationStatus.relativeDescription(daysRemaining: days))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(status.color)
                Text(product.expirationDate, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let quantity = "Qty \(product.quantity)"
        return product.location.isEmpty ? quantity : "\(product.location) · \(quantity)"
    }
}
