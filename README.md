# Workout

[![iOS Build](https://github.com/dexwritescode/Workout/actions/workflows/ios-build.yml/badge.svg)](https://github.com/dexwritescode/Workout/actions/workflows/ios-build.yml)
[![iOS Test](https://github.com/dexwritescode/Workout/actions/workflows/ios-test.yml/badge.svg)](https://github.com/dexwritescode/Workout/actions/workflows/ios-test.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](LICENSE)

Offline-first workout tracking app for iPhone. No account, no cloud, no subscription — your data stays on your device.

## Features

**Workout planning**
- Create, edit, and delete workout templates with per-set weight and rep targets
- Smart Workout — generates a session from your current recovery state and training split
- Add exercises mid-session without modifying the underlying template

**Active workout**
- Set-by-set logging with weight, reps, and completion tracking
- Persistent mini-bar keeps your session accessible across all tabs
- Rest timer that survives app backgrounding
- Plate calculator for loading the bar

**Recovery**
- Per-muscle fatigue model updated after every session
- Recovery dashboard with color-coded status bars
- Interactive muscle silhouette heatmap

**History & analytics**
- Full session history with per-exercise set breakdown
- Weekly volume, muscle volume, 1RM trend, 12-week activity heatmap, and personal records

**Exercise library**
- 100+ exercises with muscle targets, difficulty ratings, and media images
- Searchable and filterable by muscle group and equipment

**Settings**
- Weight unit (kg / lb)
- Training split preference
- Default rest time
- Plate configuration
- Daily workout reminders
- Accent theme: Forge (orange), Carbon (slate), Pulse (green)
- Full JSON export and import

## Requirements

iOS 17+. No external accounts or network access required.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for architecture, build instructions, and how to run the tests.
