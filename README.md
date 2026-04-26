# Workout App

Offline-first iOS workout tracking app with muscle recovery modeling.

## Architecture

**Pattern**: MVVM + Services -- `SwiftData Models -> Services -> ViewModels -> SwiftUI Views`

**Zero external dependencies** -- pure Swift/SwiftUI, no CocoaPods/SPM packages. iOS 17+.

### What exists today

**Data layer (SwiftData):**
- 8 models: Exercise, WorkoutTemplate, TemplateExercise, WorkoutSession, CompletedExercise, ExerciseSet, UserSettings, MuscleRecoveryState
- Enums stored as String raw values with typed computed accessors
- exercises.json seeded on first launch via SeedDataService

**Services:**
- RecoveryEngine -- deterministic fatigue model (tanh normalization, exponential decay by muscle size)
- WorkoutEngine -- generates workout suggestions based on recovery state and split type
- ExportService / ImportService -- JSON backup & restore
- NotificationManager -- workout reminders
- SeedDataService -- first-launch data seeding

**Views (5-tab navigation):**
- Workout tab -- template picker, active workout flow (start -> track sets -> rest timer -> summary -> save)
- Recovery tab -- per-muscle recovery cards with color-coded status and progress rings
- History tab -- calendar + session list, detail view
- Exercises tab -- searchable library with filters, detail view
- Settings tab -- preferences, notifications, data management (export/import)

**Design system:**
- AppStyle.swift -- colors, spacing, radii, shared color functions
- ButtonStyles.swift -- ScaleButtonStyle
- ViewModifiers.swift -- .cardStyle(), .statusCardStyle(), .badgePill(), .numberedCircle()
- ThemeManager.swift

**Tests:**
- ~1400 lines in WorkoutTests.swift (Swift Testing framework)
- Suites: EnumTests, ExerciseModelTests, RecoveryEngineTests, WorkoutEngineTests, ExportServiceTests, ImportServiceTests

## What's left

See [REMAINING_WORK.md](REMAINING_WORK.md) for the full list. Key items:
- Future workout scheduling (ScheduleView)
- Deeper analytics (StatsView)
- Exercise media (images/videos)
- Dark mode support
- Background timer fixes
- Editing completed sets
