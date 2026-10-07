import SwiftUI

extension ExpirationStatus {
    var title: String {
        switch self {
        case .expired: "Expired"
        case .expiringSoon: "Expiring Soon"
        case .fresh: "OK"
        }
    }

    var symbolName: String {
        switch self {
        case .expired: "xmark.octagon.fill"
        case .expiringSoon: "exclamationmark.triangle.fill"
        case .fresh: "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .expired: .red
        case .expiringSoon: .orange
        case .fresh: .green
        }
    }

    static func relativeDescription(daysRemaining days: Int) -> String {
        switch days {
        case ..<(-1): "Expired \(-days) days ago"
        case -1: "Expired yesterday"
        case 0: "Expires today"
        case 1: "Expires tomorrow"
        default: "In \(days) days"
        }
    }
}
