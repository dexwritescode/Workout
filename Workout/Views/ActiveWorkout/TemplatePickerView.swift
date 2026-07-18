// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  TemplatePickerView.swift
//  Workout
//
//  Dual-mode template list: Manage mode (CRUD, reached via a toolbar button from
//  WorkoutStagingView) and Pick mode (onSelect provided, used by "Load Template").
//

import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    private static let isNotDraft = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<WorkoutTemplate> { $0.isDraft == isNotDraft },
        sort: \WorkoutTemplate.createdDate
    ) private var templates: [WorkoutTemplate]

    /// Navigation title shown in pick mode — callers reusing this picker for a different flow
    /// (e.g. assigning a day's template rather than loading one into the current workout) can
    /// override the default. Ignored in manage mode, which always shows "Manage Templates".
    var pickTitle: String = "Load Template"

    /// When provided, shows a destructive "Clear Assignment" row above the template list —
    /// lets a caller with something currently assigned (e.g. a day's template) remove it from
    /// the same sheet used to assign it, instead of a separate, harder-to-discover gesture.
    /// Pass nil (the default) when there's nothing to clear, or when this picker isn't being
    /// used for an assignment flow at all.
    var onClear: (() -> Void)? = nil

    /// Pick mode when provided (tapping a row selects and dismisses); Manage mode when nil
    /// (tapping a row opens the template for editing). Declared last so trailing-closure call
    /// sites (`TemplatePickerView { template in ... }`) keep working.
    var onSelect: ((WorkoutTemplate) -> Void)? = nil

    @State private var showCreateTemplate = false
    @State private var templateToEdit: WorkoutTemplate?
    @State private var templateToDelete: WorkoutTemplate?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                if let onClear {
                    Button(role: .destructive) {
                        onClear()
                        dismiss()
                    } label: {
                        Label("Clear Assignment", systemImage: "xmark.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppStyle.Colors.error)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }

                if templates.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                } else {
                    ForEach(templates) { template in
                        templateRowLink(template)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    templateToDelete = template
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button {
                                    templateToEdit = template
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppStyle.Colors.brand)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .navigationTitle(onSelect == nil ? "Manage Templates" : pickTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                TemplateEditorView()
            }
            .sheet(item: $templateToEdit) { template in
                TemplateEditorView(template: template)
            }
            .alert("Delete \"\(templateToDelete?.name ?? "")\"?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let t = templateToDelete {
                        modelContext.delete(t)
                        templateToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { templateToDelete = nil }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: - Template Row

    @ViewBuilder
    private func templateRowLink(_ template: WorkoutTemplate) -> some View {
        if let onSelect {
            Button {
                onSelect(template)
                dismiss()
            } label: {
                templateRow(template)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                templateToEdit = template
            } label: {
                templateRow(template)
            }
            .buttonStyle(.plain)
        }
    }

    private func templateRow(_ template: WorkoutTemplate) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppStyle.Colors.brand.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppStyle.Colors.brand.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "dumbbell")
                        .font(.system(size: 16))
                        .foregroundStyle(AppStyle.Colors.brand)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)

                if !template.templateDescription.isEmpty {
                    Text(template.templateDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Label("\(template.exercises.count) exercises", systemImage: "square.grid.2x2")
                        .font(.system(size: 11))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .lineLimit(1)

                    if let lastUsed = template.lastUsedDate {
                        Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 3)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No Templates Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Tap + to create your first workout template")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    TemplatePickerView()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}