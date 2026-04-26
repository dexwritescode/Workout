//
//  ExerciseDetailView.swift
//  Workout
//
//  Exercise detail: hero card, about, instructions with step indicators.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Hero card
                heroCard
                    .padding(.bottom, 4)

                // About
                aboutSection

                // Instructions
                instructionsSection

                // Add to template CTA
                addToTemplateButton
            }
            .padding(16)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                showContent = true
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyle.Colors.brand.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppStyle.Colors.brand.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "dumbbell")
                        .font(.system(size: 24))
                        .foregroundStyle(AppStyle.Colors.brand)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.difficultyColor(exercise.difficulty))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.difficultyColor(exercise.difficulty).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(exercise.primaryMusclesDisplayString)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.Colors.textSecondary.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text(exercise.equipmentDisplayString)
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.large)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .sectionHeader()

            Text(exercise.exerciseDescription)
                .font(.system(size: 15))
                .foregroundStyle(AppStyle.Colors.text)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to perform")
                .sectionHeader()

            if exercise.instructions.isEmpty {
                Text("No instructions available.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            } else {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppStyle.Colors.brand.opacity(0.1))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppStyle.Colors.brand)
                            )

                        Text(step)
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.text)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -10)
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: showContent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Add to Template

    private var addToTemplateButton: some View {
        Button {
            // TODO: add to template action
        } label: {
            Text("+ Add to Template")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppStyle.Colors.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                        .stroke(AppStyle.Colors.brand.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(
            name: "Barbell Bench Press",
            description: "A compound chest exercise performed lying on a flat bench, pressing a barbell from chest to full arm extension.",
            instructions: [
                "Lie flat on a bench with feet firmly on the ground",
                "Grip the barbell slightly wider than shoulder width",
                "Unrack the bar and hold it above your chest with arms extended",
                "Lower the bar to your mid-chest in a controlled manner",
                "Press the bar back up to the starting position",
                "Keep your shoulder blades retracted throughout the movement"
            ],
            equipment: ["Barbell", "Flat Bench"],
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            difficultyLevel: .intermediate
        ))
    }
}
