import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage(ReminderSettings.Key.isEnabled)
    private var remindersEnabled = ReminderSettings.default.isEnabled
    @AppStorage(ReminderSettings.Key.daysBefore)
    private var daysBefore = ReminderSettings.default.daysBefore
    @AppStorage(ReminderSettings.Key.minutesAfterMidnight)
    private var minutesAfterMidnight = ReminderSettings.default.minutesAfterMidnight

    @State private var isAuthorizationDenied = false
    @State private var pendingCount = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Expiration Reminders", isOn: $remindersEnabled)
                    if remindersEnabled {
                        Stepper(value: $daysBefore, in: 0...30) {
                            Text(daysBefore == 0 ? "Only on expiration day" : "Also \(daysBefore) days before")
                        }
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if remindersEnabled {
                        Text("\(pendingCount) reminders scheduled.")
                    }
                }

                if isAuthorizationDenied {
                    Section {
                        Text("Notifications are turned off for ShelfLife.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button("Send Test Notification in 5 s") {
                        ReminderScheduler.sendTestNotification()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { pendingCount = await ReminderScheduler.pendingCount() }
            .onChange(of: remindersEnabled) { _, isEnabled in
                Task {
                    if isEnabled {
                        let granted = await ReminderScheduler.requestAuthorization()
                        isAuthorizationDenied = !granted
                        if !granted { remindersEnabled = false }
                    }
                    await reschedule()
                }
            }
            .onChange(of: daysBefore) { Task { await reschedule() } }
            .onChange(of: minutesAfterMidnight) { Task { await reschedule() } }
        }
    }

    /// Adapts the stored minutes-after-midnight to the `Date` a DatePicker needs.
    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: minutesAfterMidnight / 60,
                minute: minutesAfterMidnight % 60,
                second: 0,
                of: .now
            ) ?? .now
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutesAfterMidnight = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
    }

    private func reschedule() async {
        ReminderScheduler.reschedule(using: modelContext)
        pendingCount = await ReminderScheduler.pendingCount()
    }
}

#Preview {
    SettingsView()
        .modelContainer(.preview)
}
