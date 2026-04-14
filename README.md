# CarePal

A local-first medication coordination app that helps people with
high-consequence treatment routines stay on top of daily medicines.

CarePal combines reminders, calendar management, adherence tracking, and an
AI assistant with an explicit human review step before any change is applied.
The result is a safer bridge between clinical instructions and what actually
happens at home, where a missed or misunderstood dose can have serious
consequences.

**Chat naturally, review carefully, track reliably.**

## Value Proposition

- People think and speak in plain language, not rigid forms
- Medication changes are high-stakes and need reviewable structure
- The assistant is useful without ever silently mutating schedules
- Local-first storage keeps the core experience private, fast, and resilient

## Core Workflow

There are two ways to change medication state:

1. **Manual calendar edits** — add, edit, or remove confirmed schedules directly
2. **Assistant proposals** — ask for a change in natural language, or attach a
   prescription photo for Gemini to interpret, review the generated draft, and
   confirm it before the change affects confirmed schedules

Adherence is tracked separately from schedule editing:

- Mark a scheduled dose as taken from `Today` or `Calendar`
- Choose both the scheduled dose being completed and the actual taken time
- History keeps the latest correction for a dose while preserving the audit
  trail in events

## Product Shape

The app has four top-level surfaces:

| Surface | Purpose |
| --- | --- |
| **Today** | Upcoming, due-now, overdue, and taken reminders for the selected day; daily progress summary; pending review card when the assistant has prepared a draft |
| **Assistant** | Chat-first interface for proposing medication changes; optional on-device voice input; supports text prompts and prescription/script photos as draft inputs |
| **Calendar** | Direct manual add, edit, and remove for confirmed medication schedules; per-time dosing support; explicit “mark taken” flow |
| **History** | Day-grouped activity feed built from the event log; adherence heatmap and streak insights; entries can be corrected by tapping and editing the taken time |

## Architecture

The app uses a local event log as the source of truth.

- Events are appended to a Drift-backed store
- Projections build the read models used by each surface
- Assistant-generated drafts stay separate from confirmed schedules until
  explicit confirmation
- History is derived from events but filtered to read like a user-facing
  activity feed rather than a raw event trace

Relevant planning docs:

- [docs/plans/v0.md](docs/plans/v0.md) — event-sourced foundation
- [docs/plans/v1.md](docs/plans/v1.md) — mobile-first draft review and manual management

## Project Structure

```text
lib/
├── main.dart
├── seed_demo_main.dart
├── env/
│   └── env.dart
└── src/
    ├── app/                       # Shell, router, theme, scope
    ├── bootstrap/                 # App bootstrap wiring
    ├── core/                      # Shared contracts and utilities
    ├── data/                      # Drift persistence, projections, model providers
    └── features/
        ├── adherence/             # Insights dashboard, heatmap, streaks
        ├── assistant/             # Chat + voice + image input
        ├── calendar/              # Manual schedule management
        ├── chat/                  # Chat coordination and domain
        ├── history/               # Activity timeline
        ├── home/                  # Home domain models
        ├── proposals/             # Draft review and confirmation
        ├── settings/              # BYO-AI config, danger zone
        └── today/                 # Daily reminders and progress
```

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- A Gemini API key (optional — see below)

### Install Dependencies

```bash
flutter pub get
```

### Environment Setup

Create a local environment file for development:

```bash
cp .env.example .env
```

Set your Gemini API key:

```
GEMINI_API_KEY=your_key_here
```

This is optional. The app supports a **BYO-AI** flow in `Settings`, where
users can save their own Gemini API key and choose the model used for
assistant requests. The current UI exposes `Gemini 2.5 Flash`, `Gemini 3 Flash`,
and `Gemini 3.1 Pro`.

If neither a saved key nor a `.env` key is available, the assistant remains
visible but live submission is disabled. Manual calendar and adherence flows
still work.

### Run the App

All platforms need `--dart-define-from-file=.env` because the `.env` file is
not bundled as an asset.

```bash
make run-web       # Chrome
make run-macos     # macOS
```

For mobile targets, pass a device ID (use `flutter devices` to list them):

```bash
flutter run --dart-define-from-file=.env -d <device_id>
```

Run `make help` for the full command list.

### Seed Demo Data

Optionally seed demo data before launching the main app. The demo dataset
lives in [assets/demo/demo_seed.txt](assets/demo/demo_seed.txt), so you can
add or tweak records there without changing Dart code:

```bash
flutter run --dart-define-from-file=.env -d chrome -t lib/seed_demo_main.dart
```

If local data already exists, the seed entrypoint stops without changing it.
To replace the current local data with the demo dataset:

```bash
flutter run --dart-define-from-file=.env -d chrome -t lib/seed_demo_main.dart --dart-define=RESET_DEMO_DATA=true
```

After the seed entrypoint reports success, stop it and launch the normal app
again on the same target.

## Local Data

All app data is stored locally.

- Native platforms use Drift on SQLite
- Web uses Drift with the bundled SQLite worker/wasm assets
- Non-sensitive AI settings use shared preferences
- Gemini API keys use secure storage where supported, with shared-preferences
  fallback on unsupported platforms
- Assistant voice input keeps raw audio on-device and only sends the
  user-reviewed transcript to Gemini
- `Settings` includes a `Danger Zone` action that clears local schedules,
  history, conversations, and saved AI settings from the current device
- Fresh installs start empty — there is no bootstrap seed data or demo account

## Development

```bash
make fmt               # Format Dart code
make lint              # Analyze Dart code
make test              # Run Flutter tests
make codegen           # Regenerate Drift database code
make rules-generate    # Regenerate AI agent rules files
```

Run `make help` for the full command list.

## Engineering Practices

### CI / CD

- **GitHub Actions CI** (`.github/workflows/ci.yml`) — runs format, analyze,
  and test checks on every push and PR to `main`
- **Codemagic CD** (`codemagic.yaml`) — tag builds run the `mobile-workflow`;
  iOS builds, signing, and TestFlight publishing are enabled; Android release
  steps are commented out until signing and Play credentials exist

### Automated Release Management

Release Please automates versioning, changelogs, and GitHub releases using
Conventional Commits.

- `.github/workflows/release_please.yml` runs on pushes to `main` and on
  manual dispatch
- Uses `release_please_config.json` with the Dart releaser for the
  `tokenizers` package
- Release metadata is sourced from `pubspec.yaml` and `CHANGELOG.md`
- `.github/workflows/release-with-bumped-patch-version.yaml` provides a
  manual patch-bump release entrypoint
- Both workflows require the `RELEASE_PLEASE_COMMIT_TOKEN` GitHub secret

### Agent Coding Rules

This repo ships structured coding rules and Flutter skills for every major
AI coding agent platform, generated from a single source of truth via
[rulesync](https://github.com/nichochar/rulesync):

| Directory | Platform |
| --- | --- |
| `.agents/` | Claude Code (Anthropic) |
| `.codex/` | Codex CLI (OpenAI) |
| `.cursor/` | Cursor |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `.opencode/` | OpenCode |
| `CLAUDE.md` | Claude Code project instructions |

The canonical rules live in `.rulesync/rules/` and `.rulesync/skills/`. Run
`make rules-generate` to regenerate all platform targets after changes.

### Sensitive Data Protection

- `.gitignore` excludes all `.env` files (`**/.env`) from version control
- `.rulesync/.aiignore` excludes `.env*` files from AI agent context
- API keys are never committed — the repo ships only `.env.example`
- Release builds do not read `.env` files; keys are provided via the in-app
  BYO-AI settings flow or CI secrets

### Test Coverage

The test suite covers unit, widget, and integration-style tests across the
application layers:

```text
test/
├── app/                           # App shell widget tests
├── bootstrap/                     # Demo data seeder tests
├── core/domain/                   # Medication scheduling logic
├── data/                          # API key store, data reset, AI settings
├── env/                           # Environment configuration tests
└── features/
    ├── adherence/                 # Calculator and insights card
    ├── assistant/                 # Voice input controller and screen
    ├── calendar/                  # Command service, time inference, screen
    ├── chat/                      # Chat coordinator
    ├── history/                   # Timeline models and screen
    ├── home/                      # Reminder models
    ├── settings/                  # Settings screen
    └── today/                     # Today screen
```

## Up Next

- Integrate a local Gemma model for a fully offline, privacy-first assistant
- Expand multimodal intake quality for voice and prescription-image parsing
- Tighten proposal UX so review feels like a natural continuation of chat
