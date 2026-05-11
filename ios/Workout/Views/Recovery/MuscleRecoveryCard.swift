//
//  MuscleRecoveryCard.swift
//  Workout
//
//  Single muscle recovery status card (kept for potential reuse).
//

import SwiftUI

struct MuscleRecoveryCard: View {
    let muscleName: String
    let recoveryPercentage: Double
    let lastWorkedDate: Date

    private var statusColor: Color {
        AppStyle.recoveryColor(recoveryPercentage)
    }

    private var statusLabel: String {
        switch recoveryPercentage {
        case 0.90...1.0: return "Recovered"
        case 0.75..<0.90: return "Almost Ready"
        case 0.50..<0.75: return "Recovering"
        case 0.25..<0.50: return "Fatigued"
        default: return "Very Fatigued"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppStyle.Colors.surface3, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: recoveryPercentage)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: recoveryPercentage)

                Text("\(Int(recoveryPercentage * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(statusColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(muscleName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.text)
                Text(statusLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Last worked")
                    .font(.system(size: 10))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                Text(lastWorkedDate, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(statusColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(statusColor.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        MuscleRecoveryCard(muscleName: "Chest", recoveryPercentage: 0.95, lastWorkedDate: Date().addingTimeInterval(-86400 * 3))
        MuscleRecoveryCard(muscleName: "Quadriceps", recoveryPercentage: 0.65, lastWorkedDate: Date().addingTimeInterval(-86400))
        MuscleRecoveryCard(muscleName: "Biceps", recoveryPercentage: 0.35, lastWorkedDate: Date().addingTimeInterval(-43200))
    }
    .padding()
    .background(AppStyle.Colors.background)
}
