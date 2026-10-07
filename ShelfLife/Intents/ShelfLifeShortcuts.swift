import AppIntents

/// Shortcuts available as soon as the app is installed — no setup needed in the Shortcuts app.
/// Every phrase must mention the app name.
nonisolated struct ShelfLifeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExpiringSoonIntent(),
            phrases: [
                "What expires soon in \(.applicationName)",
                "Check expirations in \(.applicationName)",
            ],
            shortTitle: "Expiring Soon",
            systemImageName: "clock.badge.exclamationmark"
        )
        AppShortcut(
            intent: RemoveProductIntent(),
            phrases: [
                "Remove \(\.$product) from \(.applicationName)",
                "Remove a product from \(.applicationName)",
            ],
            shortTitle: "Remove Product",
            systemImageName: "trash"
        )
    }
}
