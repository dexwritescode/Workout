//
//  SwipeToRevealDelete.swift
//  Workout
//
//  Reusable swipe-left-to-delete row wrapper for custom (non-List) layouts.
//
//  Layout note: the delete button sits ON TOP in the ZStack (front) so its
//  hit-test beats the content's, which stays at its original layout frame
//  even when visually offset (SwiftUI offset() doesn't move hit-testing).
//  allowsHitTesting gates the button so it only intercepts touches once
//  the reveal is mostly complete.
//

import SwiftUI

struct SwipeToRevealDelete<Content: View>: View {
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    private let revealWidth: CGFloat = 68

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            content
                .background(AppStyle.Colors.surface1)
                .offset(x: offset)

            // Rendered on top so it wins hit-testing over the offset content
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.25)) { offset = 0 }
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: revealWidth)
                    .frame(maxHeight: .infinity)
                    .background(.red)
            }
            .buttonStyle(.plain)
            .opacity(offset < -1 ? 1 : 0)
            .allowsHitTesting(offset <= -(revealWidth / 2))
        }
        .clipped()
        .highPriorityGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { v in
                    guard abs(v.translation.width) > abs(v.translation.height) else { return }
                    offset = min(0, v.translation.width)
                }
                .onEnded { v in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = v.translation.width < -(revealWidth / 2) ? -revealWidth : 0
                    }
                }
        )
    }
}
