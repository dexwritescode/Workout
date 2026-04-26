//
//  ProgressView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData
import Charts

/// Shows workout analytics: volume over time, workout frequency, and personal records.
struct WorkoutProgressView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.startTime
    ) private var sessions: [WorkoutSession]

    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Progress")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                if sessions.isEmpty {
                    emptyState
                } else {
                    // Summary stats
                    summarySection
                        .padding(.bottom, 20)

                    // Volume chart
                    volumeChartSection
                        .padding(.bottom, 20)

                    // Frequency chart
                    frequencyChartSection
                        .padding(.bottom, 20)

                    // Personal records
                    personalRecordsSection
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.3), value: sessions.isEmpty)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                showContent = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No Data Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Complete some workouts to see your progress.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Time")
                .sectionHeader()
                .padding(.leading, 4)

            HStack(spacing: 8) {
                statCard(value: "\(sessions.count)", label: "Workouts")
                statCard(value: formatVolume(totalVolume), label: "Volume")
            }

            HStack(spacing: 8) {
                statCard(value: "\(totalSets)", label: "Total Sets")
                if let streak = currentStreak, streak > 0 {
                    statCard(value: "\(streak)w", label: "Streak")
                }
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppStyle.Colors.brand)
                .contentTransition(.numericText())
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

    // MARK: - Volume Chart

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Volume")
                .sectionHeader()
                .padding(.leading, 4)

            Chart(weeklyVolume, id: \.weekStart) { entry in
                BarMark(
                    x: .value("Week", entry.weekStart, unit: .weekOfYear),
                    y: .value("Volume (kg)", entry.volume)
                )
                .foregroundStyle(AppStyle.Colors.brand.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                        .foregroundStyle(AppStyle.Colors.border)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(AppStyle.Colors.border)
                    AxisValueLabel()
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
            }
            .frame(height: 200)
            .padding(16)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.1), value: showContent)
        }
    }

    // MARK: - Frequency Chart

    private var frequencyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workouts Per Week")
                .sectionHeader()
                .padding(.leading, 4)

            Chart(weeklyFrequency, id: \.weekStart) { entry in
                BarMark(
                    x: .value("Week", entry.weekStart, unit: .weekOfYear),
                    y: .value("Workouts", entry.count)
                )
                .foregroundStyle(AppStyle.Colors.success.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...7)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                        .foregroundStyle(AppStyle.Colors.border)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(AppStyle.Colors.border)
                    AxisValueLabel()
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
            }
            .frame(height: 160)
            .padding(16)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.2), value: showContent)
        }
    }

    // MARK: - Personal Records

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Records")
                .sectionHeader()
                .padding(.leading, 4)

            let records = personalRecords
            VStack(spacing: 0) {
                if records.isEmpty {
                    Text("No records yet.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .padding(16)
                } else {
                    ForEach(Array(records.prefix(10).enumerated()), id: \.element.exerciseName) { index, record in
                        if index > 0 {
                            AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.exerciseName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppStyle.Colors.text)
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppStyle.Colors.textTertiary)
                            }
                            Spacer()
                            Text(String(format: "%.1f kg × %d", record.weight, record.reps))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppStyle.Colors.brand)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: showContent)
                    }
                }
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 20)
    }

    // MARK: - Computed Data

    private var totalVolume: Double {
        sessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }
            .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var totalSets: Int {
        sessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }.count
    }

    struct WeeklyEntry {
        let weekStart: Date
        let volume: Double
        let count: Int
    }

    private var weeklyVolume: [WeeklyEntry] {
        let calendar = Calendar.current
        let last8Weeks = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()
        let recent = sessions.filter { $0.startTime >= last8Weeks }

        let grouped = Dictionary(grouping: recent) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startTime)?.start ?? session.startTime
        }

        return grouped.map { weekStart, weekSessions in
            let vol = weekSessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }
                .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            return WeeklyEntry(weekStart: weekStart, volume: vol, count: weekSessions.count)
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    private var weeklyFrequency: [WeeklyEntry] {
        weeklyVolume
    }

    private var currentStreak: Int? {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<52 {
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: checkDate)
            guard let start = weekInterval?.start else { break }

            let hasWorkout = sessions.contains { session in
                calendar.isDate(session.startTime, equalTo: start, toGranularity: .weekOfYear)
            }

            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        return streak
    }

    struct PersonalRecord {
        let exerciseName: String
        let weight: Double
        let reps: Int
        let date: Date
    }

    private var personalRecords: [PersonalRecord] {
        var best: [String: (weight: Double, reps: Int, date: Date)] = [:]

        for session in sessions {
            for ce in session.completedExercises {
                guard let name = ce.exercise?.name else { continue }
                for set in ce.sets where set.isCompleted {
                    let current = best[name]
                    if current == nil || set.weight > current!.weight ||
                       (set.weight == current!.weight && set.reps > current!.reps) {
                        best[name] = (set.weight, set.reps, session.startTime)
                    }
                }
            }
        }

        return best.map { PersonalRecord(exerciseName: $0.key, weight: $0.value.weight, reps: $0.value.reps, date: $0.value.date) }
            .sorted { $0.weight > $1.weight }
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM kg", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }
}

#Preview {
    NavigationStack {
        WorkoutProgressView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
