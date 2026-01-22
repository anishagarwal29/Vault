
import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App {
    let container = DataManager.shared.container
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
    }
}
