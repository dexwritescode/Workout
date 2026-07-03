# Contributing

## Architecture

**Pattern**: MVVM + Services — `SwiftData Models → Services → @Observable ViewModels → SwiftUI Views`

iOS 17+. One external dependency: [`MuscleMap`](https://github.com/ShengHuaWu/MuscleMap) (SPM) for the interactive muscle silhouette view.

### Data layer (SwiftData, 9 models)

```
Exercise           — seeded from exercises.json; enums stored as String raw values
WorkoutTemplate    ─┬─ TemplateExercise ─┬─ TemplateSet   (per-set weight/rep targets)
                    │                    └─ Exercise
WorkoutSession     ─┴─ CompletedExercise ─── ExerciseSet   (actual logged sets)
UserSettings       — singleton; weight unit, split preference, plate config
MuscleRecoveryState — one row per MuscleGroup; stores fatigueLevel (0–1) + lastUpdated
```

Enums stored as `String` raw values with typed computed accessors. `exercises.json` (in `resources/` at repo root) is seeded on first launch via `SeedDataService`.

### Services

- **RecoveryEngine** — deterministic fatigue model: `tanh(volume/5000) × 0.85`, exponential decay with half-life proportional to muscle size. Secondary muscles receive 50% of volume. Updates are additive.
- **WorkoutEngine** — generates workout suggestions from recovery state and split preference; scores exercises by compound bonus, recency, and difficulty
- **NotificationManager** — daily workout reminders and rest-timer background notifications
- **ExportService / ImportService** — full JSON backup & restore

### Views (5-tab navigation)

- **Workout** — template picker → active workout flow (set logging, rest timer, plate calculator, workout summary). Smart Workout tab generates a session from current recovery state. `ActiveWorkoutCoordinator` maintains session state across all tabs and surfaces a persistent mini-bar via `tabViewBottomAccessory`.
- **Recovery** — per-muscle recovery cards with color-coded status, progress bars, and an interactive `MuscleMap` silhouette heatmap
- **History** — chronological session list with detail view; toolbar icon opens the Analytics screen (weekly volume, muscle volume, 1RM trend, 12-week activity heatmap, personal records, workout frequency)
- **Exercises** — searchable, filterable library with exercise detail (muscle targets, difficulty, media images, per-exercise history)
- **Settings** — weight unit, default rest time, training split, plate setup, notification preferences, accent theme, data export/import

### Design system

- `AppStyle.swift` — dark-theme color palette, spacing tokens (xxs–xxxl), radius tokens, typography helpers; `AppStyle.Colors.brand` is dynamic (delegates to `ThemeManager`)
- Three accent themes: **Forge** (orange), **Carbon** (slate), **Pulse** (green) — selectable in Settings, persisted via `ThemeManager`
- `ButtonStyles.swift` — `PrimaryActionButtonStyle`, `ScaleButtonStyle`
- `ViewModifiers.swift` — `.cardStyle()`, `.statusCardStyle()`, `.badgePill()`, `.sectionHeader()`

## Getting started

```bash
# 1. Clone the repo
git clone https://github.com/dexwritescode/Workout.git
cd Workout

# 2. Set up code signing (required once before opening in Xcode)
cp Config/Signing.xcconfig.example Config/Signing.xcconfig
# Fill in DEVELOPMENT_TEAM and BUNDLE_ID_PREFIX in the new file

# 3. Open in Xcode
open Workout.xcodeproj
```

`Config/Signing.xcconfig` is gitignored — your developer credentials stay local. CI uses `CODE_SIGNING_ALLOWED=NO`.

## Build & test

```bash
# Build (no signing required)
xcodebuild -scheme Workout -configuration Debug -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO build -project Workout.xcodeproj

# Run tests (always use clean to avoid stale derived data masking failures)
xcodebuild clean test -scheme Workout \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO -project Workout.xcodeproj
```

~1400 lines of tests in `WorkoutTests/WorkoutTests.swift` (Swift Testing framework). Suites: `EnumTests`, `ExerciseModelTests`, `RecoveryEngineTests`, `WorkoutEngineTests`, `ExportServiceTests`, `ImportServiceTests`. All tests run against pure logic — no SwiftData container required.

## Repo layout

```
Workout/
├── Workout.xcodeproj/
├── Workout/                iOS app source
│   ├── Models/Domain/      Exercise, WorkoutTemplate (all 9 @Model classes)
│   ├── Models/Recovery/    MuscleRecoveryState
│   ├── Models/Enums.swift  MuscleGroup, DifficultyLevel, WeightUnit, SplitType
│   ├── Services/           RecoveryEngine, WorkoutEngine, SeedDataService, Export/Import
│   ├── Views/              one subfolder per tab + shared ActiveWorkout flow
│   ├── Design/             AppStyle, ThemeManager, ButtonStyles, ViewModifiers
│   └── Resources/
├── WorkoutTests/
├── WorkoutUITests/
├── Config/                 Signing.xcconfig (gitignored), .example committed
├── resources/
│   ├── exercises.json      exercise database
│   └── media/              exercise images, one folder per exercise
├── CONTRIBUTING.md
└── README.md
```
