//
//  ExerciseImageView.swift
//  Workout
//
//  Bundled exercise image view. Fills whatever frame the caller gives it.
//  When animated, crossfades between frame 0 and frame 1.
//  Falls back to a dumbbell icon when no media is available.
//
//  Usage:
//    ExerciseImageView(mediaFileName: exercise.mediaFileName)
//        .frame(width: 44, height: 44)            // square thumbnail
//
//    ExerciseImageView(mediaFileName: exercise.mediaFileName, animated: true)
//        .frame(maxWidth: .infinity, maxHeight: 220) // hero card
//

import SwiftUI

struct ExerciseImageView: View {
    let mediaFileName: String?
    var animated: Bool = false
    var cornerRadius: CGFloat = 8
    var contentMode: ContentMode = .fill

    @State private var showSecondFrame = false
    @State private var frame0: UIImage? = nil
    @State private var frame1: UIImage? = nil
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            if let img = currentImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .animation(.easeInOut(duration: 0.6), value: showSecondFrame)
            } else {
                AppStyle.Colors.surface2
                Image(systemName: "dumbbell")
                    .font(.system(size: 16))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            loadImages()
            if animated { startAnimation() }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Helpers

    private var currentImage: UIImage? {
        showSecondFrame ? (frame1 ?? frame0) : frame0
    }

    private func loadImages() {
        guard let name = mediaFileName else { return }
        frame0 = loadFrame(name: name, index: 0)
        frame1 = loadFrame(name: name, index: 1)
    }

    private func loadFrame(name: String, index: Int) -> UIImage? {
        guard
            let bundleURL = Bundle.main.url(forResource: "Media", withExtension: "bundle"),
            let mediaBundle = Bundle(url: bundleURL),
            let path = mediaBundle.path(forResource: "\(index)", ofType: "jpg", inDirectory: name)
        else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private func startAnimation() {
        guard frame0 != nil, frame1 != nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            showSecondFrame.toggle()
        }
    }
}
