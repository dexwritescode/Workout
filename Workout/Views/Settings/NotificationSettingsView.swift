//
//  NotificationSettingsView.swift
//  Workout
//
//  Created by Dexter Darwich on 2026-03-16.
//

import SwiftUI
import SwiftData

/// Settings screen for configuring workout reminder notifications.
struct NotificationSettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var modelContext

    @State private var notificationManager = NotificationManager.shared
    @State private var showingDeniedAlert = false

    private var settings: UserSettings {
        if let existing = allSettings.first { return existing }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    /// The reminder time, defaulting to 9:00 AM if not set.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                settings.notificationTime ?? Calendar.current.date(
                    from: DateComponents(hour: 9, minute: 0)
                ) ?? Date()
            },
            set: { newValue in
                settings.notificationTime = newValue
                if settings.notificationsEnabled {
                    Task {
                        await notificationManager.scheduleDailyReminder(at: newValue)
                    }
                }
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminders")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Notifications")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                // Workout Reminders
                settingsSection("Workout Reminders") {
                    HStack {
                        Text("Daily Reminder")
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                Task { await toggleNotifications(newValue) }
                            }
                        ))
                        .tint(AppStyle.Colors.brand)
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if settings.notificationsEnabled {
                        sectionDivider

                        HStack {
                            Text("Reminder Time")
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.text)
                            Spacer()
                            DatePicker(
                                "",
                                selection: reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .tint(AppStyle.Colors.brand)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: settings.notificationsEnabled)

                Text("Get a daily reminder to check your recovery and start a workout.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.top, -16)
                    .padding(.bottom, 24)

                // Status
                settingsSection("Status") {
                    HStack {
                        Text("System Permission")
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)
                        Spacer()
                        Text(statusText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(statusColor)
                            .animation(.easeInOut(duration: 0.4), value: notificationManager.authorizationStatus)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showingDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notifications are disabled in system settings. Open Settings to enable them.")
        }
    }

    // MARK: - Section Builder

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionHeader()
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 24)
    }

    private var sectionDivider: some View {
        AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
    }

    // MARK: - Logic

    private func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            await notificationManager.refreshAuthorizationStatus()

            switch notificationManager.authorizationStatus {
            case .notDetermined:
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    settings.notificationsEnabled = true
                    await notificationManager.scheduleDailyReminder(at: reminderTime.wrappedValue)
                }
            case .authorized, .provisional, .ephemeral:
                settings.notificationsEnabled = true
                await notificationManager.scheduleDailyReminder(at: reminderTime.wrappedValue)
            case .denied:
                showingDeniedAlert = true
            @unknown default:
                break
            }
        } else {
            settings.notificationsEnabled = false
            notificationManager.cancelAllReminders()
        }
    }

    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .notDetermined: return "Not Asked"
        @unknown default: return "Unknown"
        }
    }

    private var statusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return AppStyle.Colors.success
        case .denied: return AppStyle.Colors.error
        case .notDetermined: return AppStyle.Colors.textSecondary
        @unknown default: return AppStyle.Colors.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .modelContainer(for: UserSettings.self, inMemory: true)
}
