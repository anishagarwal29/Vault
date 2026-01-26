import SwiftData
import SwiftUI

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    
    // MARK: - Initialization
    init() {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self,
            RecurringSubscription.self
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
            // Fatal error to prevent data loss perception. 
            // If we fallback to in-memory, the user sees an empty app and thinks data is deleted.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
}
