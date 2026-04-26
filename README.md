# Workout

[![Build](https://github.com/dexwritescode/Workout/actions/workflows/build.yml/badge.svg)](https://github.com/dexwritescode/Workout/actions/workflows/build.yml)
[![Test](https://github.com/dexwritescode/Workout/actions/workflows/test.yml/badge.svg)](https://github.com/dexwritescode/Workout/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Offline-first iOS workout tracking app with muscle recovery modeling.

## Architecture

**Pattern**: MVVM + Services — `SwiftData Models → Services → ViewModels → SwiftUI Views`

**Zero external dependencies** — pure Swift/SwiftUI, no CocoaPods/SPM packages. iOS 17+.

### Data layer (SwiftData)
- 8 models: `Exercise`, `WorkoutTemplate`, `TemplateExercise`, `WorkoutSession`, `CompletedExercise`, `ExerciseSet`, `UserSettings`, `MuscleRecoveryState`
- Enums stored as `String` raw values with typed computed accessors
- `exercises.json` seeded on first launch via `SeedDataService`

### Services
- **RecoveryEngine** — deterministic fatigue model: volume = weight × reps, tanh-normalized, exponential decay with half-life proportional to muscle size (small 24h, medium 48h, large 72h)
- **WorkoutEngine** — generates workout suggestions based on recovery state and split type; scores exercises by compound bonus, recency, and difficulty
- **NotificationManager** — daily workout reminders and rest-timer background notifications
- **ExportService / ImportService** — JSON backup & restore

### Views (5-tab navigation)
- **Workout** — template picker, active workout flow: start → track sets → rest timer → summary → save. Smart Workout generates a session from recovery state.
- **Recovery** — per-muscle recovery cards with color-coded status and progress rings
- **History** — calendar + session list with detail view
- **Exercises** — searchable library with filters and detail view
- **Settings** — preferences, notifications, accent theme, data management (export/import)

### Design system
- `AppStyle.swift` — colors, spacing, radii, accent themes (Forge, Carbon, Pulse)
- `ButtonStyles.swift` — `PrimaryActionButtonStyle`, `ScaleButtonStyle`
- `ViewModifiers.swift` — `.cardStyle()`, `.statusCardStyle()`, `.badgePill()`, `.sectionHeader()`
- `ThemeManager.swift` — persisted accent color selection

### Tests
- ~1400 lines in `WorkoutTests/WorkoutTests.swift` (Swift Testing framework)
- Suites: `EnumTests`, `ExerciseModelTests`, `RecoveryEngineTests`, `WorkoutEngineTests`, `ExportServiceTests`, `ImportServiceTests`

## Getting started

1. Clone the repo
2. Copy `Config/Signing.xcconfig.example` → `Config/Signing.xcconfig` and fill in your team ID and bundle ID prefix
3. Open `Workout.xcodeproj` in Xcode and build (Cmd+B)

The `Config/Signing.xcconfig` file is gitignored — your developer credentials stay local.
