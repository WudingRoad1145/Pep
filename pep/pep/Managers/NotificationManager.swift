import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func triggerTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pep Test Notification"
        content.body = "This is a test notification for pep app build"
        content.sound = .default
        content.badge = 1
        content.launchImageName = "AppIcon"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error)")
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    print("Notification permission granted")
                    self?.scheduleExerciseReminders()
                } else {
                    print("Notification permission denied")
                    if let error = error {
                        print("Error requesting notification permission: \(error)")
                    }
                }
            }
        }
    }
    
    func scheduleExerciseReminders() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Create default reminders
        let reminders = [
            (hour: 10, minute: 0, identifier: "morning", title: "Morning Exercise"),
            (hour: 15, minute: 0, identifier: "afternoon", title: "Afternoon Exercise"),
            (hour: 22, minute: 08, identifier: "evening", title: "Evening Exercise")
        ]
        
        for reminder in reminders {
            scheduleNotification(
                hour: reminder.hour,
                minute: reminder.minute,
                identifier: reminder.identifier,
                title: reminder.title
            )
        }
    }
    
    private func scheduleNotification(hour: Int, minute: Int, identifier: String, title: String) {
        let content = UNMutableNotificationContent()
        content.title =  "Time to Exercise!"
        content.body = "Time to move your fingers! 🖐 Keep those hands healthy!"
        content.sound = .default
        content.badge = 1
        
        // Create date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "exercise_reminder_\(identifier)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Successfully scheduled \(identifier) notification for \(hour):\(minute)")
                print("   Trigger Time: \(hour):\(minute)")
                print("   Repeats: Yes")
            }
        }
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
    
    // Debug function to print all scheduled notifications
    func printScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("Scheduled notification: \(request.identifier)")
                    print("  Next trigger date: \(trigger.nextTriggerDate() ?? Date())")
                    print("  Is repeating: \(trigger.repeats)")
                }
            }
        }
    }
}
