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
    @State private var muscleVolumePeriod: StatPeriod = .month
    @State private var selectedOneRMExercise: Exercise? = nil
    @State private var showExercisePicker = false

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

                    // Volume by muscle
                    muscleVolumeSection
                        .padding(.bottom, 20)

                    // 1RM trend
                    oneRMTrendSection
                        .padding(.bottom, 20)

                    // Activity heatmap
                    activityHeatmapSection
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
        .sheet(isPresented: $showExercisePicker) {
            exercisePickerSheet
        }
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

    // MARK: - 1RM Trend

    private var oneRMTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Strength Trend")
                    .sectionHeader()
                    .padding(.leading, 4)
                Spacer()
                Button {
                    showExercisePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedOneRMExercise?.name ?? "Select Exercise")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppStyle.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(maxWidth: 180, alignment: .trailing)
            }

            if let exercise = selectedOneRMExercise {
                let data = oneRMData(for: exercise)
                if data.isEmpty {
                    Text("No logged sets for \(exercise.name) yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppStyle.Colors.surface1)
                        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: AppStyle.Radius.card).stroke(AppStyle.Colors.border, lineWidth: 1))
                } else {
                    let pr = data.map(\.oneRM).max() ?? 0
                    Chart {
                        ForEach(data) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("1RM", entry.oneRM)
                            )
                            .foregroundStyle(AppStyle.Colors.brand)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("1RM", entry.oneRM)
                            )
                            .foregroundStyle(entry.oneRM == pr ? AppStyle.Colors.success : AppStyle.Colors.brand)
                            .symbolSize(entry.oneRM == pr ? 80 : 36)
                            .annotation(position: .top) {
                                if entry.oneRM == pr {
                                    Text("PR")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppStyle.Colors.success)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(AppStyle.Colors.success.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(AppStyle.Colors.border)
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(AppStyle.Colors.border)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v)) kg")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppStyle.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(16)
                    .background(AppStyle.Colors.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: AppStyle.Radius.card).stroke(AppStyle.Colors.border, lineWidth: 1))
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).delay(0.15), value: showContent)
                }
            } else {
                Button {
                    showExercisePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                        Text("Pick an exercise to see your strength trend")
                            .font(.system(size: 14))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppStyle.Colors.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: AppStyle.Radius.card).stroke(AppStyle.Colors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var exercisePickerSheet: some View {
        NavigationStack {
            let options = exercisesWithHistory
            List(options, id: \.id) { exercise in
                Button {
                    selectedOneRMExercise = exercise
                    showExercisePicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppStyle.Colors.text)
                            Text(exercise.primaryMusclesDisplayString)
                                .font(.system(size: 12))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                        }
                        Spacer()
                        if exercise.id == selectedOneRMExercise?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppStyle.Colors.brand)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showExercisePicker = false }
                }
            }
        }
    }

    // MARK: - Activity Heatmap

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .sectionHeader()
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 6) {
                let grid = heatmapGrid
                let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

                HStack(alignment: .top, spacing: 4) {
                    // Day-of-week labels
                    VStack(alignment: .trailing, spacing: 3) {
                        ForEach(dayLabels, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 9))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                                .frame(width: 10, height: 14)
                        }
                    }

                    // Week columns
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 3) {
                            ForEach(Array(grid.enumerated()), id: \.offset) { _, week in
                                VStack(spacing: 3) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        let count = week[dayIndex]
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(heatmapColor(count: count))
                                            .frame(width: 14, height: 14)
                                    }
                                }
                            }
                        }
                    }
                }

                // Legend
                HStack(spacing: 6) {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                    ForEach([0, 1, 2, 3], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatmapColor(count: level))
                            .frame(width: 14, height: 14)
                    }
                    Text("More")
                        .font(.system(size: 10))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
                .padding(.leading, 14)
            }
            .padding(16)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: AppStyle.Radius.card).stroke(AppStyle.Colors.border, lineWidth: 1))
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.2), value: showContent)
        }
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case ..<0:     return Color.clear
        case 0:        return AppStyle.Colors.surface2
        case 1:        return AppStyle.Colors.brand.opacity(0.35)
        case 2:        return AppStyle.Colors.brand.opacity(0.65)
        default:       return AppStyle.Colors.brand
        }
    }

    // MARK: - Muscle Volume Chart

    private var muscleVolumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Volume by Muscle")
                    .sectionHeader()
                    .padding(.leading, 4)
                Spacer()
                Menu {
                    Picker("", selection: $muscleVolumePeriod) {
                        ForEach(StatPeriod.allCases, id: \.self) { Text($0.label) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(muscleVolumePeriod.label)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppStyle.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            let data = muscleVolumeData
            if data.isEmpty {
                Text("No data for this period.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppStyle.Colors.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                            .stroke(AppStyle.Colors.border, lineWidth: 1)
                    )
            } else {
                Chart(data, id: \.muscle) { entry in
                    BarMark(
                        x: .value("Volume", entry.volume),
                        y: .value("Muscle", entry.muscle.rawValue)
                    )
                    .foregroundStyle(
                        entry.muscle.category == .upperBody
                            ? AppStyle.Colors.brand.gradient
                            : AppStyle.Colors.success.gradient
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(AppStyle.Colors.border)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppStyle.Colors.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                    }
                }
                .frame(height: CGFloat(data.count) * 30 + 24)
                .padding(16)
                .background(AppStyle.Colors.surface1)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                        .stroke(AppStyle.Colors.border, lineWidth: 1)
                )
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.15), value: showContent)
            }
        }
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
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    struct MuscleVolumeEntry {
        let muscle: MuscleGroup
        let volume: Double
    }

    private var muscleVolumeData: [MuscleVolumeEntry] {
        let cutoff = muscleVolumePeriod.cutoffDate
        var muscleVolume: [MuscleGroup: Double] = [:]

        for session in sessions where session.startTime >= cutoff {
            for ce in session.completedExercises {
                guard let exercise = ce.exercise else { continue }
                let volume = ce.sets.filter(\.isCompleted)
                    .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                guard volume > 0 else { continue }
                for muscle in exercise.primaryMuscleGroups {
                    muscleVolume[muscle, default: 0] += volume
                }
                for muscle in exercise.secondaryMuscleGroups {
                    muscleVolume[muscle, default: 0] += volume * 0.5
                }
            }
        }

        return muscleVolume
            .map { MuscleVolumeEntry(muscle: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }

    // MARK: - 1RM Data

    struct OneRMEntry: Identifiable {
        let id = UUID()
        let date: Date
        let oneRM: Double
    }

    private func oneRMData(for exercise: Exercise) -> [OneRMEntry] {
        sessions.compactMap { session -> OneRMEntry? in
            guard let ce = session.completedExercises.first(where: { $0.exercise?.id == exercise.id }) else { return nil }
            let best = ce.sets.filter(\.isCompleted)
                .map { $0.weight * (1.0 + Double($0.reps) / 30.0) }
                .max() ?? 0
            guard best > 0 else { return nil }
            return OneRMEntry(date: session.startTime, oneRM: best)
        }
        .sorted { $0.date < $1.date }
    }

    private var exercisesWithHistory: [Exercise] {
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for session in sessions.reversed() {
            for ce in session.completedExercises {
                guard let ex = ce.exercise,
                      !seen.contains(ex.id),
                      ce.sets.contains(where: \.isCompleted) else { continue }
                seen.insert(ex.id)
                result.append(ex)
            }
        }
        return result
    }

    // MARK: - Heatmap Data

    private var heatmapGrid: [[Int]] {
        let calendar = Calendar.current
        let today = Date()

        // Start from the Monday 12 weeks ago
        let weeksBack = 12
        let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        guard let gridStart = calendar.date(byAdding: .weekOfYear, value: -(weeksBack - 1), to: startOfThisWeek) else { return [] }

        // Build a lookup: normalized day → session count
        var countByDay: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            countByDay[day, default: 0] += 1
        }

        // Build weeks × days grid (week columns, 0=Mon … 6=Sun)
        var grid: [[Int]] = []
        for weekOffset in 0..<weeksBack {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: gridStart) else { continue }
            var week: [Int] = []
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    week.append(0); continue
                }
                let normalized = calendar.startOfDay(for: day)
                week.append(day <= today ? (countByDay[normalized] ?? 0) : -1)
            }
            grid.append(week)
        }
        return grid
    }
}

enum StatPeriod: String, CaseIterable {
    case week, month, allTime

    var label: String {
        switch self {
        case .week: return "This Week"
        case .month: return "4 Weeks"
        case .allTime: return "All Time"
        }
    }

    var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:    return calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? .distantPast
        case .month:   return calendar.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? .distantPast
        case .allTime: return .distantPast
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutProgressView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
