// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  AddExerciseButton.swift
//  Workout
//
//  Shared "Add Exercise" card button — previously three different treatments (bordered card,
//  plain Form row, buried in a toolbar Menu) for the same action across WorkoutStagingView,
//  TemplateEditorView, and ActiveWorkoutView.
//

import SwiftUI

struct AddExerciseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.brand)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }
}
