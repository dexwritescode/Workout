//
//  WorkoutHistoryView.swift
//  Workout
//
//  History tab: stats strip + session list with date and volume info.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.startTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("History")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                if sessions.isEmpty {
                    emptyState
                } else {
                    // Stats strip
                    statsStrip
                        .padding(.bottom, 20)

                    // Session list
                    VStack(spacing: 8) {
                        ForEach(sessions) { session in
                            NavigationLink {
                                WorkoutHistoryDetailView(session: session)
                            } label: {
                                sessionRow(session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WorkoutProgressView()
                } label: {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 15))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 8) {
            statPill(value: "\(sessions.count)", label: "Workouts")
            statPill(value: "\(totalSets)", label: "Total Sets")
            statPill(value: formatVolume(totalVolume), label: "Volume")
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
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

    // MARK: - Session Row

    private func sessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 14) {
            // Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(AppStyle.Colors.brand.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppStyle.Colors.brand.opacity(0.16), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "dumbbell")
                        .font(.system(size: 16))
                        .foregroundStyle(AppStyle.Colors.brand)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(session.template?.name ?? "Workout")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)

                HStack(spacing: 10) {
                    if let duration = session.duration {
                        Label(formatDuration(duration), systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                    }
                    let setCount = session.completedExercises.flatMap { $0.sets.filter(\.isCompleted) }.count
                    Label("\(setCount) sets", systemImage: "square.grid.2x2")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.startTime.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textSecondary)

                let vol = sessionVolume(session)
                if vol > 0 {
                    Text(formatVolume(vol))
                        .font(.system(size: 11))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
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
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No Workouts Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Completed workouts will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private var totalSets: Int {
        sessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }.count
    }

    private var totalVolume: Double {
        sessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }
            .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private func sessionVolume(_ session: WorkoutSession) -> Double {
        session.completedExercises.flatMap { $0.sets.filter(\.isCompleted) }
            .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes) min"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
