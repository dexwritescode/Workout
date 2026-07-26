// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  SetsListCard.swift
//  Workout
//
//  Shared chrome for an editable/trackable sets list: column header, a List embedded purely for
//  native .swipeActions, the bordered/clipped card wrapper, and a freestanding Add Set button
//  below. State-agnostic — callers own what each row means (completed/current/future, or a
//  uniform editable target row) and attach their own .swipeActions per row.
//

import SwiftUI

/// Single source of truth for the row height every set row must render at — in this card and in
/// any caller's own row content — so the embedded List's swipe-to-delete button sizes identically
/// across every row state and every screen that uses this component.
enum SetsListRowMetrics {
    static let height: CGFloat = 60
}

struct SetsListCard<RowContent: View>: View {
    let rowCount: Int
    var rowHeight: CGFloat = SetsListRowMetrics.height
    @ViewBuilder let rowContent: (Int) -> RowContent
    let onAddSet: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                columnHeader

                List {
                    ForEach(0..<rowCount, id: \.self) { index in
                        rowContent(index)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(AppStyle.Colors.border)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: CGFloat(rowCount) * rowHeight)
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )

            addSetButton
        }
    }

    private var columnHeader: some View {
        HStack {
            Text("SET")
                .frame(width: 32, alignment: .leading)
            Text("WEIGHT")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("REPS")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppStyle.Colors.textTertiary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            AppStyle.Colors.border.frame(height: 1)
        }
    }

    private var addSetButton: some View {
        Button(action: onAddSet) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                Text("Add Set")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppStyle.Colors.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppStyle.Colors.brand.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.brand.opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityIdentifier("addSetButton")
        .padding(.top, 8)
    }
}
