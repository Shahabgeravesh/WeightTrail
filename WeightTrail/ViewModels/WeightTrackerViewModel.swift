import Foundation
import SwiftUI
import UserNotifications

// MARK: - NotificationManager
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
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current  // Now we can modify the calendar
        
        // Extract hour and minute components in user's time zone
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // For debugging
        print("Scheduling notification for \(components.hour ?? 0):\(components.minute ?? 0) in timezone: \(TimeZone.current.identifier)")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weightReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        
        // Verify next trigger date
        if let nextTrigger = trigger.nextTriggerDate() {
            print("Next notification scheduled for: \(nextTrigger)")
        }
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Helper method to check scheduled notifications
    func checkScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("Scheduled notification: \(trigger.dateComponents)")
                    if let next = trigger.nextTriggerDate() {
                        print("Next trigger: \(next)")
                    }
                }
            }
        }
    }
}

class WeightTrackerViewModel: ObservableObject {
    @Published var weights: [Weight] = []
    @Published var goalWeight: Double? {
        didSet {
            saveGoalWeight()
        }
    }
    @Published var hasSeenSwipeHint: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenSwipeHint, forKey: "hasSeenSwipeHint")
        }
    }
    @Published var journalEntries: [JournalEntry] = []
    @Published var preferredUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(preferredUnit.rawValue, forKey: unitPreferenceKey)
        }
    }
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: reminderTimeKey)
            if isRemindersEnabled {
                NotificationManager.shared.scheduleWeightReminder(at: reminderTime)
            }
        }
    }
    @Published var isRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRemindersEnabled, forKey: remindersEnabledKey)
            if isRemindersEnabled {
                NotificationManager.shared.scheduleWeightReminder(at: reminderTime)
            } else {
                NotificationManager.shared.cancelNotifications()
            }
        }
    }
    
    private let weightsKey = "savedWeights"
    private let goalWeightKey = "goalWeight"
    private let swipeHintKey = "hasSeenSwipeHint"
    private let journalKey = "savedJournalEntries"
    private let unitPreferenceKey = "weightUnitPreference"
    private let reminderTimeKey = "reminderTime"
    private let remindersEnabledKey = "remindersEnabled"
    
    init() {
        self.hasSeenSwipeHint = UserDefaults.standard.bool(forKey: swipeHintKey)
        if let savedUnit = UserDefaults.standard.string(forKey: unitPreferenceKey),
           let unit = WeightUnit(rawValue: savedUnit) {
            self.preferredUnit = unit
        } else {
            self.preferredUnit = .lbs // Default to lbs
        }
        self.reminderTime = UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
        self.isRemindersEnabled = UserDefaults.standard.bool(forKey: remindersEnabledKey)
        loadData()
        loadJournalEntries()
    }
    
    // MARK: - Weight Management
    func addWeight(_ weight: Double) {
        let newWeight = Weight(weight: weight)
        weights.append(newWeight)
        weights.sort { $0.date > $1.date }
        saveWeights()
        
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func deleteWeight(_ weight: Weight) {
        withAnimation {
            weights.removeAll { $0.id == weight.id }
            saveWeights()
        }
    }
    
    func setGoalWeight(_ weight: Double?) {
        goalWeight = weight
    }
    
    func resetAllData() {
        weights.removeAll()
        goalWeight = nil
        UserDefaults.standard.removeObject(forKey: weightsKey)
        UserDefaults.standard.removeObject(forKey: goalWeightKey)
    }
    
    func updateWeight(_ weight: Weight, newWeight: Double) {
        if let index = weights.firstIndex(where: { $0.id == weight.id }) {
            weights[index] = Weight(id: weight.id, date: weight.date, weight: newWeight)
            saveWeights()
        }
    }
    
    // MARK: - Journal Management
    func addJournalEntry(_ content: String) {
        let entry = JournalEntry(content: content)
        journalEntries.append(entry)
        journalEntries.sort { $0.date > $1.date }
        saveJournalEntries()
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        withAnimation {
            journalEntries.removeAll { $0.id == entry.id }
            saveJournalEntries()
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry, newContent: String) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = JournalEntry(id: entry.id, date: entry.date, content: newContent)
            saveJournalEntries()
        }
    }
    
    // MARK: - Persistence
    private func saveWeights() {
        if let encoded = try? JSONEncoder().encode(weights) {
            UserDefaults.standard.set(encoded, forKey: weightsKey)
        }
    }
    
    private func saveGoalWeight() {
        UserDefaults.standard.set(goalWeight, forKey: goalWeightKey)
    }
    
    private func saveJournalEntries() {
        if let encoded = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(encoded, forKey: journalKey)
        }
    }
    
    private func loadData() {
        // Load weights
        if let savedWeights = UserDefaults.standard.data(forKey: weightsKey),
           let decodedWeights = try? JSONDecoder().decode([Weight].self, from: savedWeights) {
            weights = decodedWeights
        }
        
        // Load goal weight
        goalWeight = UserDefaults.standard.object(forKey: goalWeightKey) as? Double
    }
    
    private func loadJournalEntries() {
        if let savedEntries = UserDefaults.standard.data(forKey: journalKey),
           let decodedEntries = try? JSONDecoder().decode([JournalEntry].self, from: savedEntries) {
            journalEntries = decodedEntries
        }
    }
    
    func dismissSwipeHint() {
        hasSeenSwipeHint = true
    }
    
    func displayWeight(_ weight: Double) -> String {
        let weightInPreferredUnit = preferredUnit == .kg ? weight / 2.20462 : weight
        return String(format: "%.1f", weightInPreferredUnit)
    }
} 