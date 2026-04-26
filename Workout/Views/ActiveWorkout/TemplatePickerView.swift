//
//  TemplatePickerView.swift
//  Workout
//
//  Workout tab: Smart Workout gradient card + template list rows.
//

import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

    @State private var showCreateTemplate = false
    @State private var templateToEdit: WorkoutTemplate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayOfWeek)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Text("Workouts")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 24)

                // Smart Workout Card
                NavigationLink(destination: SmartWorkoutView()) {
                    smartWorkoutCard
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)

                // My Templates
                if !templates.isEmpty {
                    Text("My Templates")
                        .sectionHeader()
                        .padding(.bottom, 14)

                    VStack(spacing: 8) {
                        ForEach(templates) { template in
                            NavigationLink(destination: ActiveWorkoutView(template: template, modelContext: modelContext)) {
                                templateRow(template)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    templateToEdit = template
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateTemplate) {
            TemplateEditorView()
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditorView(template: template)
        }
    }

    // MARK: - Smart Workout Card

    private var smartWorkoutCard: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 100, height: 100)
                .offset(x: 20, y: -20)
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: -10, y: 40)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.95))
                    Text("Smart Workout")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                }

                Text("AI-generated based on your recovery")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 8) {
                    smartWorkoutPill("Push Day")
                    smartWorkoutPill("~44 min")
                    smartWorkoutPill("5 exercises")
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [AppStyle.Colors.brand, Color(hex: 0xCC3520)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.large))
        .shadow(color: AppStyle.Colors.brand.opacity(0.35), radius: 12, y: 4)
    }

    private func smartWorkoutPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Template Row

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

                    if let lastUsed = template.lastUsedDate {
                        Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                    }
                }
                .padding(.top, 3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.textTertiary)
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
            Text("Create a workout template to get started")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}

#Preview {
    NavigationStack {
        TemplatePickerView()
    }
    .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
