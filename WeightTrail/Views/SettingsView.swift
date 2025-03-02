import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var viewModel: WeightTrackerViewModel
    @State private var showingNotificationRequest = false
    
    var body: some View {
        Form {
            Section("Daily Weigh-in Reminder") {
                Toggle("Enable Reminder", isOn: $viewModel.isRemindersEnabled)
                    .onChange(of: viewModel.isRemindersEnabled) { isEnabled in
                        if isEnabled {
                            showingNotificationRequest = true
                        }
                    }
                
                if viewModel.isRemindersEnabled {
                    DatePicker("Reminder Time", 
                              selection: $viewModel.reminderTime,
                              displayedComponents: .hourAndMinute)
                    
                    Text("You'll be reminded to weigh in daily at this time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.blue)
                    Text("Notifications must be enabled in Settings to receive reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Enable Notifications", isPresented: $showingNotificationRequest) {
            Button("Enable") {
                Task {
                    try? await NotificationManager.shared.requestAuthorization()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.isRemindersEnabled = false
            }
        } message: {
            Text("Would you like to receive daily reminders to log your weight?")
        }
    }
} 