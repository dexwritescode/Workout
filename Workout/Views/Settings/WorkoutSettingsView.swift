// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  WorkoutSettingsView.swift
//  Workout
//
//  Workout-specific configuration, reached via a gear icon from the unified staging view — a
//  sibling to SettingsView, not nested under the general Settings tab.
//

import SwiftUI
import SwiftData

struct WorkoutSettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Query private var dayAssignments: [DayTemplateAssignment]
    @Environment(\.modelContext) private var modelContext

    private var settings: UserSettings {
        if let existing = allSettings.first { return existing }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    private var scheduleSummary: String {
        let parts = Weekday.displayOrder.compactMap { weekday -> String? in
            guard let assignment = dayAssignments.first(where: { $0.weekday == weekday.rawValue }),
                  let name = assignment.template?.name else { return nil }
            return "\(weekday.shortName) \(name)"
        }
        return parts.isEmpty ? "Not set" : parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Workout Settings")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                settingsSection("Start Mode") {
                    VStack(alignment: .leading, spacing: 2) {
                        pickerRow("Mode") {
                            Picker("Mode", selection: Binding(
                                get: { settings.workoutStartMode },
                                set: { settings.workoutStartMode = $0 }
                            )) {
                                ForEach(WorkoutStartMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                        }
                        Text(settings.workoutStartMode.description)
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    if settings.workoutStartMode == .dayTemplate {
                        sectionDivider

                        VStack(alignment: .leading, spacing: 2) {
                            pickerRow("If No Template") {
                                Picker("If No Template", selection: Binding(
                                    get: { settings.dayTemplateFallbackMode },
                                    set: { settings.dayTemplateFallbackMode = $0 }
                                )) {
                                    Text(WorkoutStartMode.smart.title).tag(WorkoutStartMode.smart)
                                    Text(WorkoutStartMode.freeform.title).tag(WorkoutStartMode.freeform)
                                }
                            }
                            Text("What to do on a day with no scheduled template")
                                .font(.system(size: 13))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }

                        sectionDivider

                        NavigationLink {
                            WeeklyScheduleView()
                        } label: {
                            settingRowWithChevron(label: "Weekly Schedule", value: scheduleSummary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: settings.workoutStartMode)
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
                    .lineLimit(1)
                    .truncationMode(.tail)
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
        WorkoutSettingsView()
    }
    .modelContainer(for: [UserSettings.self, DayTemplateAssignment.self, WorkoutTemplate.self], inMemory: true)
}
