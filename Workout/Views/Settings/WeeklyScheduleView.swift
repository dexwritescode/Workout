// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  WeeklyScheduleView.swift
//  Workout
//
//  7-row Mon-Sun schedule editor for Day Template mode — each row opens a sheet to assign or
//  clear the template that auto-loads on that weekday.
//

import SwiftUI
import SwiftData

struct WeeklyScheduleView: View {
    @Query private var dayAssignments: [DayTemplateAssignment]

    @State private var weekdayToAssign: Weekday?

    private func assignment(for weekday: Weekday) -> DayTemplateAssignment? {
        dayAssignments.first { $0.weekday == weekday.rawValue }
    }

    var body: some View {
        List {
            ForEach(Weekday.displayOrder) { weekday in
                dayRow(weekday)
                    .listRowBackground(AppStyle.Colors.surface1)
                    .listRowSeparatorTint(AppStyle.Colors.border)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppStyle.Colors.background)
        .navigationTitle("Weekly Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $weekdayToAssign) { weekday in
            let hasAssignment = assignment(for: weekday)?.template != nil
            TemplatePickerView(
                pickTitle: "Assign Template",
                onClear: hasAssignment ? { assignment(for: weekday)?.template = nil } : nil
            ) { template in
                assignment(for: weekday)?.template = template
            }
        }
    }

    private func dayRow(_ weekday: Weekday) -> some View {
        let templateName = assignment(for: weekday)?.template?.name

        return Button {
            weekdayToAssign = weekday
        } label: {
            HStack(spacing: 12) {
                statusDot(isAssigned: templateName != nil)

                Text(weekday.fullName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)

                Spacer()

                Text(templateName ?? "None")
                    .font(.system(size: 15, weight: templateName != nil ? .medium : .regular))
                    .foregroundStyle(templateName != nil ? AppStyle.Colors.brand : AppStyle.Colors.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .accessibilityIdentifier("weekdayRow-\(weekday.rawValue)")
    }

    private func statusDot(isAssigned: Bool) -> some View {
        Circle()
            .fill(isAssigned ? AppStyle.Colors.brand : Color.clear)
            .overlay(
                Circle()
                    .stroke(isAssigned ? AppStyle.Colors.brand : AppStyle.Colors.borderStrong, lineWidth: 1.5)
            )
            .frame(width: 8, height: 8)
    }
}

#Preview {
    NavigationStack {
        WeeklyScheduleView()
    }
    .modelContainer(for: [DayTemplateAssignment.self, WorkoutTemplate.self], inMemory: true)
}
