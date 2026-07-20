// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  TemplateEntryView.swift
//  Workout
//
//  Single entry point for the Workout tab's toolbar: pick a template to load into the
//  current draft, or drill into Manage Templates for CRUD. Replaces the old pair of
//  separate "Load Template" / "Manage Templates" entry points on WorkoutStagingView.
//

import SwiftUI
import SwiftData

struct TemplateEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<WorkoutTemplate> { $0.draftKindRaw == nil },
        sort: \WorkoutTemplate.createdDate
    ) private var templates: [WorkoutTemplate]

    let onSelect: (WorkoutTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        TemplatePickerView()
                    } label: {
                        Label("Manage Templates", systemImage: "list.bullet.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppStyle.Colors.brand)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))

                if templates.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                } else {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                            dismiss()
                        } label: {
                            TemplateSummaryRow(template: template)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .navigationTitle("Load Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No Templates Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Tap Manage Templates above to create one")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    TemplateEntryView { _ in }
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
