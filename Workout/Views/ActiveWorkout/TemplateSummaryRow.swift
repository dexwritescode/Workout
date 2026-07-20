// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  TemplateSummaryRow.swift
//  Workout
//
//  Shared template row layout used by TemplatePickerView and TemplateEntryView.
//

import SwiftUI

struct TemplateSummaryRow: View {
    let template: WorkoutTemplate

    var body: some View {
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
                        .lineLimit(1)

                    if let lastUsed = template.lastUsedDate {
                        Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 3)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }
}
