//
//  ExerciseHistoryView.swift
//  Workout
//
//  Per-exercise strength history: estimated 1RM trend chart and
//  session-by-session set log.
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    let exercise: Exercise

    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [SessionRecord] = []

    struct SetRecord {
        let weight: Double
        let reps: Int
        var estimatedOneRM: Double { weight * (1.0 + Double(reps) / 30.0) }
    }

    struct SessionRecord: Identifiable {
        let id = UUID()
        let date: Date
        let sets: [SetRecord]
        var bestOneRM: Double { sets.map(\.estimatedOneRM).max() ?? 0 }
    }

    private var prOneRM: Double { sessions.map(\.bestOneRM).max() ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if sessions.isEmpty {
                    emptyState
                } else {
                    oneRMChart
                    sessionLog
                }
            }
            .padding(16)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadHistory() }
    }

    // MARK: - 1RM Chart

    private var oneRMChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated 1RM")
                    .sectionHeader()
                Text("Epley formula · best set per session")
                    .font(.system(size: 11))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .padding(.leading, 4)

            Chart {
                ForEach(sessions) { session in
                    LineMark(
                        x: .value("Date", session.date),
                        y: .value("1RM", session.bestOneRM)
                    )
                    .foregroundStyle(AppStyle.Colors.brand)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", session.date),
                        y: .value("1RM", session.bestOneRM)
                    )
                    .foregroundStyle(session.bestOneRM == prOneRM && prOneRM > 0
                        ? AppStyle.Colors.success
                        : AppStyle.Colors.brand)
                    .symbolSize(session.bestOneRM == prOneRM && prOneRM > 0 ? 80 : 40)
                    .annotation(position: .top) {
                        if session.bestOneRM == prOneRM && prOneRM > 0 {
                            Text("PR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppStyle.Colors.success)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
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
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Session Log

    private var sessionLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions")
                .sectionHeader()
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(sessions.reversed().enumerated()), id: \.element.id) { index, session in
                    if index > 0 {
                        AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
                    }
                    sessionRow(session)
                }
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
    }

    private func sessionRow(_ session: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)
                Spacer()
                if session.bestOneRM == prOneRM && prOneRM > 0 {
                    Text("PR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppStyle.Colors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppStyle.Colors.success.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Text("≈\(Int(session.bestOneRM)) kg 1RM")
                    .font(.system(size: 12))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }

            HStack(spacing: 8) {
                ForEach(Array(session.sets.enumerated()), id: \.offset) { _, set in
                    let w = set.weight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", set.weight)
                        : String(format: "%.1f", set.weight)
                    Text("\(w)×\(set.reps)")
                        .font(AppStyle.Typography.mono(12, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No History Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Complete a workout with \(exercise.name) to start tracking progress.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Data

    private func loadHistory() {
        let exerciseID = exercise.id
        do {
            let all = try modelContext.fetch(FetchDescriptor<CompletedExercise>())
            let matching = all
                .filter { ce in
                    ce.exercise?.id == exerciseID &&
                    ce.session?.isCompleted == true
                }
                .sorted { ($0.session?.startTime ?? .distantPast) < ($1.session?.startTime ?? .distantPast) }

            sessions = matching.compactMap { ce -> SessionRecord? in
                guard let date = ce.session?.startTime else { return nil }
                let sets = ce.sets
                    .filter(\.isCompleted)
                    .sorted { $0.setNumber < $1.setNumber }
                    .map { SetRecord(weight: $0.weight, reps: $0.reps) }
                guard !sets.isEmpty else { return nil }
                return SessionRecord(date: date, sets: sets)
            }
        } catch {}
    }
}
