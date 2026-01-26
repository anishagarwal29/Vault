
import UserNotifications
import Foundation

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permission granted")
                // Schedule the notification after permission is granted
                self.scheduleDailyNotification()
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Track Finances"
        content.body = "Don't forget to log your expenses/income for today!"
        content.sound = .default
        
        // Configure the date components for the user's requested time
        var dateComponents = DateComponents()
        // Daily at 9:00 PM
        dateComponents.hour = 21
        dateComponents.minute = 00
        
         // Remove pending notifications to avoid duplicates when testing
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "DailyFinanceReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Daily notification scheduled for \(dateComponents.hour!):\(String(format: "%02d", dateComponents.minute!))")
            }
        }
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
