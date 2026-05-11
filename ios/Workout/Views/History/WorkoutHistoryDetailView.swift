//
//  WorkoutHistoryDetailView.swift
//  Workout
//
//  Workout detail: summary stats + per-exercise set breakdown with best set highlight.
//

import SwiftUI

struct WorkoutHistoryDetailView: View {
    let session: WorkoutSession
    @State private var showContent = false

    private var sortedExercises: [CompletedExercise] {
        session.completedExercises.sorted { $0.order < $1.order }
    }

    private var totalSets: Int {
        sortedExercises.flatMap { $0.sets.filter(\.isCompleted) }.count
    }

    private var totalVolume: Double {
        sortedExercises.flatMap { $0.sets.filter(\.isCompleted) }
            .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Summary stats
                statsRow

                // Exercises
                Text("Exercises")
                    .sectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, completedExercise in
                    let doneSets = completedExercise.sets
                        .filter(\.isCompleted)
                        .sorted { $0.setNumber < $1.setNumber }

                    if !doneSets.isEmpty {
                        exerciseCard(completedExercise, sets: doneSets, index: index)
                    }
                }
            }
            .padding(16)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle(session.template?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                showContent = true
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            if let duration = session.duration {
                statCard(value: formatDuration(duration), label: "Duration")
            }
            statCard(value: "\(totalSets)", label: "Sets")
            statCard(value: formatVolume(totalVolume), label: "Volume")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppStyle.Colors.brand)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ completedExercise: CompletedExercise, sets: [ExerciseSet], index: Int) -> some View {
        let exVol = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        let best = sets.max(by: { $0.weight < $1.weight })

        return VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(AppStyle.Colors.brand.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "dumbbell")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.brand)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(completedExercise.exercise?.name ?? "Unknown")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.text)
                    if let best {
                        Text("\(sets.count) sets · Best: \(String(format: "%.1f", best.weight)) kg × \(best.reps)")
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                    }
                }

                Spacer()

                Text(formatVolume(exVol))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                AppStyle.Colors.border.frame(height: 1)
            }

            // Column headers
            HStack {
                Text("Set").frame(width: 36, alignment: .leading)
                Text("Weight").frame(maxWidth: .infinity, alignment: .leading)
                Text("Reps").frame(maxWidth: .infinity, alignment: .leading)
                Text("Vol").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppStyle.Colors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                AppStyle.Colors.border.frame(height: 1)
            }

            // Set rows
            ForEach(sets, id: \.id) { set in
                let isBest = set.weight == best?.weight
                HStack {
                    Text("\(set.setNumber)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .frame(width: 36, alignment: .leading)

                    Text("\(String(format: "%.1f", set.weight)) kg")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(set.reps)")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(formatSetVolume(set.weight * Double(set.reps)) + (isBest ? " ↑" : ""))
                        .font(.system(size: 14, weight: isBest ? .semibold : .regular))
                        .foregroundStyle(isBest ? AppStyle.Colors.brand : AppStyle.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isBest ? AppStyle.Colors.brand.opacity(0.05) : Color.clear)
            }
        }
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.06), value: showContent)
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes) min"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1ft", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }

    private func formatSetVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1ft", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryDetailView(session: WorkoutSession())
    }
}
