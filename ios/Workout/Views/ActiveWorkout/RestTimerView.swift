//
//  RestTimerView.swift
//  Workout
//
//  Inline rest timer banner between sets (matches design prototype).
//  Uses wall-clock endDate so the timer stays accurate when the app is backgrounded.
//

import SwiftUI

struct RestTimerView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var endDate: Date
    @State private var remainingSeconds: Int
    @State private var timer: Timer?

    /// Create a new rest timer counting down from `totalSeconds`.
    init(totalSeconds: Int, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onSkip = onSkip
        let end = Date().addingTimeInterval(Double(totalSeconds))
        self._endDate = State(initialValue: end)
        self._remainingSeconds = State(initialValue: totalSeconds)
    }

    /// Restore a rest timer from a persisted `endDate`.
    init(endDate: Date, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onSkip = onSkip
        self._endDate = State(initialValue: endDate)
        self._remainingSeconds = State(initialValue: max(0, Int(ceil(endDate.timeIntervalSinceNow))))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.7)

                Text(formatTime(remainingSeconds))
                    .font(AppStyle.Typography.mono(28, weight: .bold))
                    .foregroundStyle(AppStyle.Colors.brand)
                    .contentTransition(.numericText())
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    endDate = endDate.addingTimeInterval(-10)
                    remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
                    NotificationManager.shared.scheduleRestTimer(endDate: endDate)
                } label: {
                    Text("−10s")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppStyle.Colors.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    endDate = endDate.addingTimeInterval(10)
                    remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
                    NotificationManager.shared.scheduleRestTimer(endDate: endDate)
                } label: {
                    Text("+10s")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppStyle.Colors.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    stopTimer()
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppStyle.Colors.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppStyle.Colors.brand.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.brand.opacity(0.2), lineWidth: 1)
        )
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        NotificationManager.shared.scheduleRestTimer(endDate: endDate)
        // Compute from wall clock so background time is accounted for
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let remaining = Int(ceil(endDate.timeIntervalSinceNow))
            if remaining <= 0 {
                remainingSeconds = 0
                stopTimer()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            } else {
                remainingSeconds = remaining
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        NotificationManager.shared.cancelRestTimer()
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    RestTimerView(totalSeconds: 90, onComplete: {}, onSkip: {})
        .padding()
        .background(AppStyle.Colors.background)
}
