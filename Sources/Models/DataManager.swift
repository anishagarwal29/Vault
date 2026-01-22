import SwiftData
import SwiftUI

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    
    // MARK: - Initialization
    init() {
        // Use in-memory for preview/sandbox, or persistent for real app.
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self
        ])
        
        // Use a versioned store file to avoid migration crashes during development

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last ?? URL(fileURLWithPath: NSHomeDirectory())
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let url = appSupport.appendingPathComponent("finance_tracker_v3.store")
        let modelConfiguration = ModelConfiguration("finance_tracker_v3", schema: schema, url: url)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Could not create ModelContainer: \(error)")
            // Fallback: Try to use an in-memory container if persistent fails, so the app doesn't crash completely
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer even in memory: \(error)")
            }
        }
    }
    
}
