import SwiftData
import SwiftUI

@main
struct ShelfLifeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    private let container = ShelfLifeApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            ProductListView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // The day may have changed while in the background: refresh widget and reminders.
            if phase == .active {
                ProductSync.refresh(using: container.mainContext)
            }
        }
    }

    private static func makeContainer() -> ModelContainer {
        let container = SharedModelContainer.shared
        #if DEBUG
        // Launch argument used for demos and screenshots: fills an empty store.
        if ProcessInfo.processInfo.arguments.contains("-seed-sample-data") {
            let context = container.mainContext
            if (try? context.fetchCount(FetchDescriptor<Product>())) == 0 {
                Product.samples().forEach(context.insert)
                try? context.save()
            }
        }
        #endif
        return container
    }
}
