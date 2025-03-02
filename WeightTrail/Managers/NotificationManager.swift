import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    
    func requestAuthorization() async throws {
        let result = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
        
        DispatchQueue.main.async {
            self.isNotificationsEnabled = result
        }
    }
    
    func scheduleWeightReminder(at time: Date) {
        // Remove existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to weigh in!"
        content.body = "Keep your streak going by logging today's weight"
        content.sound = .default
        
        // Create daily trigger at specified time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weightReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 