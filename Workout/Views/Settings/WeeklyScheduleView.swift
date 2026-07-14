// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  WeeklyScheduleView.swift
//  Workout
//
//  7-row Mon-Sun schedule editor for Day Template mode — each row assigns or clears the
//  template that auto-loads on that weekday.
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if assignment(for: weekday)?.template != nil {
                            Button(role: .destructive) {
                                assignment(for: weekday)?.template = nil
                            } label: {
                                Label("Clear", systemImage: "xmark.circle")
                            }
                            .tint(.red)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppStyle.Colors.background)
        .navigationTitle("Weekly Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $weekdayToAssign) { weekday in
            TemplatePickerView { template in
                assignment(for: weekday)?.template = template
            }
        }
    }

    private func dayRow(_ weekday: Weekday) -> some View {
        Button {
            weekdayToAssign = weekday
        } label: {
            HStack {
                Text(weekday.fullName)
                    .font(.system(size: 16))
                    .foregroundStyle(AppStyle.Colors.text)
                Spacer()
                Text(assignment(for: weekday)?.template?.name ?? "None")
                    .font(.system(size: 15))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WeeklyScheduleView()
    }
    .modelContainer(for: [DayTemplateAssignment.self, WorkoutTemplate.self], inMemory: true)
}
