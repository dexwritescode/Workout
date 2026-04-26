//
//  SettingsView.swift
//  Workout
//
//  Settings tab: grouped dark card sections matching prototype design.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    private var settings: UserSettings {
        if let existing = allSettings.first { return existing }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferences")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Settings")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                // Appearance
                settingsSection("Appearance") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)

                        HStack(spacing: 12) {
                            ForEach(AppStyle.AccentTheme.allCases, id: \.rawValue) { theme in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        themeManager.accentTheme = theme
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(themeManager.accentTheme == theme ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                            )
                                            .overlay(
                                                themeManager.accentTheme == theme ?
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(.white) : nil
                                            )
                                        Text(theme.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(themeManager.accentTheme == theme ? AppStyle.Colors.text : AppStyle.Colors.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }

                // Units
                settingsSection("Units") {
                    pickerRow("Weight Unit") {
                        Picker("Weight Unit", selection: Binding(
                            get: { settings.unit },
                            set: { settings.unit = $0 }
                        )) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text("\(unit.rawValue) (\(unit.abbreviation))").tag(unit)
                            }
                        }
                    }
                }

                // Workout Defaults
                settingsSection("Workout Defaults") {
                    VStack(alignment: .leading, spacing: 2) {
                        pickerRow("Rest Between Sets") {
                            Picker("Rest Between Sets", selection: Binding(
                                get: { settings.defaultRestTime },
                                set: { settings.defaultRestTime = $0 }
                            )) {
                                Text("60s").tag(60)
                                Text("90s").tag(90)
                                Text("120s").tag(120)
                                Text("180s").tag(180)
                            }
                        }
                        Text("Timer duration after completing a set")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    sectionDivider
                    VStack(alignment: .leading, spacing: 2) {
                        pickerRow("Training Split") {
                            Picker("Training Split", selection: Binding(
                                get: { settings.splitType ?? .pushPullLegs },
                                set: { settings.splitType = $0 }
                            )) {
                                ForEach(SplitType.allCases) { split in
                                    Text(split.rawValue).tag(split)
                                }
                            }
                        }
                        Text("How Smart Workout groups your exercises")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                }

                // Notifications
                settingsSection("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        settingRowWithChevron(label: "Workout Reminders", value: settings.notificationsEnabled ? "On" : "Off")
                    }
                    .buttonStyle(.plain)
                }

                // Data
                settingsSection("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        settingRowWithChevron(label: "Export & Import", value: nil)
                    }
                    .buttonStyle(.plain)
                }

                // About
                settingsSection("About") {
                    settingRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    sectionDivider
                    settingRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }

                // Acknowledgements
                settingsSection("Acknowledgements") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Body diagram muscle illustrations adapted from Wikimedia Commons.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                        Text("By Termininja — CC BY-SA 3.0")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
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

    private func pickerRow<P: View>(_ label: String, @ViewBuilder picker: () -> P) -> some View {
        HStack {
            picker()
                .tint(AppStyle.Colors.textSecondary)
        }
        .font(.system(size: 16))
        .foregroundStyle(AppStyle.Colors.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }

    private func settingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(AppStyle.Colors.text)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func settingRowWithChevron(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(AppStyle.Colors.text)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var sectionDivider: some View {
        AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: UserSettings.self, inMemory: true)
}
