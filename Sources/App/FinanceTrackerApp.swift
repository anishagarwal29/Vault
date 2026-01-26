
import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App {
    let container = DataManager.shared.container
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
    }
}
