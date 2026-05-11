//
//  DataManagementView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Allows users to export and import their workout data as JSON.
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.startTime
    ) private var sessions: [WorkoutSession]

    @State private var showExportShare = false
    @State private var exportURL: URL?
    @State private var showImportPicker = false
    @State private var importResult: String?
    @State private var showImportResult = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Data Management")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.bottom, 20)

                // Export
                settingsSection("Export") {
                    Button {
                        exportData()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.brand)
                            Text("Export Workout Data")
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }

                Text("Exports all \(sessions.count) completed workouts and settings as a JSON file.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.top, -16)
                    .padding(.bottom, 24)

                // Import
                settingsSection("Import") {
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.brand)
                            Text("Import from File")
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }

                Text("Import a previously exported JSON file. Duplicate workouts will be skipped.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.top, -16)
                    .padding(.bottom, 24)

                // Current Data
                settingsSection("Current Data") {
                    HStack {
                        Text("Completed Workouts")
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)
                        Spacer()
                        Text("\(sessions.count)")
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)

                    HStack {
                        Text("Total Sets Logged")
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)
                        Spacer()
                        let totalSets = sessions.flatMap { $0.completedExercises.flatMap { $0.sets.filter(\.isCompleted) } }.count
                        Text("\(totalSets)")
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            Text(importResult ?? "")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Section Builder

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionHeader()
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func exportData() {
        do {
            let url = try ExportService.exportToFile(modelContext: modelContext)
            exportURL = url
            showExportShare = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access the selected file."
                showError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let importResult = try ImportService.importData(from: data, modelContext: modelContext)
                var message = "Imported \(importResult.sessionsImported) workout(s)."
                if importResult.settingsImported {
                    message += " Settings were also updated."
                }
                self.importResult = message
                showImportResult = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

/// UIKit share sheet wrapper
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
