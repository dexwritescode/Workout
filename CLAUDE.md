# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

**Build**: Open `Workout.xcodeproj` in Xcode and press Cmd+B, or:
```bash
xcodebuild -scheme Workout -configuration Debug -sdk iphonesimulator build
```

**Run all tests** (Cmd+U in Xcode):
```bash
xcodebuild test -scheme Workout -destination 'platform=iOS Simulator,OS=latest'
```

**Run a specific test suite**:
```bash
xcodebuild test -scheme Workout -destination 'platform=iOS Simulator,OS=latest' \
  -only-testing WorkoutTests/RecoveryEngineTests
```

**Run a single test**:
```bash
xcodebuild test -scheme Workout -destination 'platform=iOS Simulator,OS=latest' \
  -only-testing 'WorkoutTests/RecoveryEngineTests/currentFatigueDecaysCorrectly'
```

No linter is configured.

## Git workflow

`main` is a protected branch — direct pushes and force pushes are blocked. All changes must go through a branch and PR:

```bash
git checkout -b <type>/<short-description>   # e.g. feat/rest-timer-adjustments
# ... make changes, commit ...
git push -u origin <branch>
gh pr create --title "..." --body "..."
```

- Branch directly off `main`; keep branches short-lived
- CI runs build + tests on every PR — do not merge a PR with failing checks

## Architecture

**Pattern**: MVVM + Services — `SwiftData Models → Services → ViewModels → SwiftUI Views`

**Zero external dependencies** — pure Swift/SwiftUI, no CocoaPods/SPM packages.

### Data Layer (SwiftData)
- All persistence via SwiftData. Schema is registered in `WorkoutApp.swift`.
- 8 core models live in `Models/Domain/`: `Exercise`, `WorkoutTemplate`, `TemplateExercise`, `WorkoutSession`, `CompletedExercise`, `ExerciseSet`, `UserSettings`, `MuscleRecoveryState`.
- **Enum storage**: SwiftData can't persist enums natively, so enum fields are stored as `String` raw values with a computed property providing the typed accessor. Example in `Exercise.swift`: `var difficultyLevel: String` backed by `var difficulty: DifficultyLevel { DifficultyLevel(rawValue: difficultyLevel) ?? .intermediate }`.
- Delete rules matter: templates cascade-delete their `TemplateExercise` join records; deleting an `Exercise` nullifies references in templates.

### Service Layer
- **`RecoveryEngine`** (`Services/Recovery/RecoveryEngine.swift`): Deterministic fatigue model. Volume = weight × reps, normalized via `tanh()`, then decays exponentially with a half-life of `recoveryHours / 2.5`. Recovery times vary by muscle size (small: 24h, medium: 48h, large: 72h). Primary muscles receive full volume; secondary muscles receive 50%. Time is a parameter so historical calculations are possible.
- **`WorkoutEngine`** (`Services/Recovery/WorkoutEngine.swift`): Generates workout suggestions. Selects target muscles based on split type and recovery state, scores exercise candidates (compound +2.0, not recently done +1.5), then recommends sets/reps based on exercise order and type.
- **`SeedDataService`**: Loads `exercises.json` from the bundle on first launch. Custom exercises created at runtime coexist alongside seeded ones.
- **`ExportService` / `ImportService`**: JSON serialization for data backup/restore.

### View Layer
- 5-tab navigation in `ContentView.swift`: Workout, Recovery, History, Exercises, Settings.
- Active workout flow is managed by `ActiveWorkoutViewModel` (`@Observable`, iOS 17+), which owns the session state machine: `notStarted → inProgress → finished`.
- Design tokens (colors, spacing, radii) are all in `Design/AppStyle.swift` as `AppStyle.Colors`, `AppStyle.Spacing`, `AppStyle.Radius`. Use these — no magic numbers.

### Tests
- All unit tests in one file: `WorkoutTests/WorkoutTests.swift` (~1400 lines).
- Organized into `@Suite` structs (Swift Testing framework, not XCTest): `EnumTests`, `ExerciseModelTests`, `RecoveryEngineTests`, `WorkoutEngineTests`, `ExportServiceTests`, `ImportServiceTests`, etc.
- `RecoveryEngineTests` and `WorkoutEngineTests` cover the core business logic — run these when touching either service.
