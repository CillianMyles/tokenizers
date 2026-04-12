# Tokenizers

Tokenizers is a Flutter medication tracker with a local event-sourced data
model, an assistant-driven schedule workflow, and explicit review before any
assistant-proposed medication change is applied.

Fresh installs start empty. There is no bootstrap seed data or demo account.

## Product Shape

The app currently has four top-level surfaces:

- `Today`
  - upcoming, due-now, overdue, and taken reminders for the selected day
  - pending review card when the assistant has prepared a draft
- `Assistant`
  - chat-first interface for proposing medication changes
  - pending draft review launched from the conversation area
- `Calendar`
  - direct manual add, edit, and remove for confirmed medication schedules
  - per-time dosing support, including different doses at different times of day
  - explicit "mark taken" flow with scheduled time and actual taken time
- `History`
  - day-grouped activity feed built from the event log
  - adherence items can be corrected by tapping the entry and editing the taken time

## Core Workflow

There are two ways to change medication state:

1. Manual calendar edits
   - add, edit, or remove confirmed schedules directly
2. Assistant proposals
   - ask for a change in natural language
   - review the generated draft
   - confirm it before the change affects confirmed schedules

Adherence is tracked separately from schedule editing:

- you can mark a scheduled dose as taken from `Today` or `Calendar`
- you can choose both the scheduled dose being completed and the actual taken time
- history keeps the latest correction for a dose while preserving the audit trail in events

## Architecture

The app uses a local event log as the source of truth.

- events are appended to a Drift-backed store
- projections build the read models used by `Today`, `Assistant`, `Calendar`, and `History`
- assistant-generated drafts stay separate from confirmed schedules until explicit confirmation
- history is derived from events, but filtered to read like a user-facing activity feed rather than a raw event trace

Relevant planning docs:

- [docs/plans/v0.md](docs/plans/v0.md)
- [docs/plans/v1.md](docs/plans/v1.md)

## Project Structure

```text
lib/
├── main.dart
├── env/
│   └── env.dart
└── src/
    ├── app/                       # Shell, router, theme, scope
    ├── bootstrap/                 # App bootstrap wiring
    ├── core/                      # Shared contracts and utilities
    ├── data/                      # Drift persistence, projections, model providers
    └── features/
        ├── assistant/
        ├── calendar/
        ├── chat/
        ├── history/
        ├── home/
        ├── proposals/
        ├── settings/
        └── today/
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Create a local environment file:

```bash
cp .env.example .env
```

Set:

```bash
GEMINI_API_KEY=your_key_here
```

This is optional. The app now supports a BYO-AI flow in `Settings`, where
users can save their own Gemini API key and choose the Gemini model used for
assistant requests. During desktop development, `.env` can still provide a
debug fallback key if no user key has been saved yet.

Run the app:

```bash
flutter run -d ios
```

Or:

```bash
flutter run -d chrome
```

If neither a saved Gemini key nor a `.env` debug key is available, the
assistant remains visible but live assistant submission is disabled. Manual
calendar and adherence flows still work.

## Local Data

All app data is stored locally.

- native platforms use Drift on SQLite
- web uses Drift with the bundled SQLite worker/wasm assets
- non-sensitive AI settings use shared preferences
- Gemini API keys use secure storage where supported, with shared-preferences
  fallback on unsupported platforms
- `Settings` includes a `Danger Zone` action that clears local schedules,
  history, conversations, and saved AI settings from the current device
- installs are no longer pre-seeded with sample medications, chat messages, or history

## Development

Format:

```bash
dart format .
```

Analyze:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Codemagic CD:

- tag builds run the Codemagic `mobile-workflow`
- iOS builds/signing/TestFlight publishing are enabled
- Android release steps are intentionally commented out until signing and Play
  credentials exist
- the Codemagic App Store Connect integration is assumed to be named
  `tokenizers.p8`

Release Please:

- `.github/workflows/release_please.yml` runs on pushes to `main` and on manual
  dispatch
- it uses `release_please_config.json` with the Dart releaser for the
  `tokenizers` package
- `.github/workflows/release-with-bumped-patch-version.yaml` provides the same
  manual patch-bump release entrypoint as the sibling apps
- both workflows require the `RELEASE_PLEASE_COMMIT_TOKEN` GitHub secret

Regenerate generated database code after schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerate repo rules:

```bash
make rules-generate
```

## Hackathon Demo

### Value Proposition

Tokenizers is a privacy-first medication companion that helps people turn messy real-world instructions into a trustworthy daily medication plan.

The pitch is simple:
- people think and speak in plain language, not rigid forms
- medication changes are high-stakes and need reviewable structure
- the app keeps the assistant useful without letting it silently mutate schedules
- local-first storage keeps the core experience private, fast, and resilient

In one line:
**chat naturally, review carefully, track reliably.**

### Demo Checklist

#### Medication plan setup and schedule management
- [ ] create medications with dosages and times
- [ ] support schedule start and end dates
- [ ] update dosage or timing for an existing medication
- [ ] stop or remove a medication cleanly
- [ ] show that proposed changes stay in draft until manually accepted

#### Today view / adherence loop
- [ ] mark medicines as taken
- [ ] today view clearly shows overdue, due now, upcoming, and taken items
- [ ] show what happens when a dose is recorded late or corrected later
- [ ] confirm that accepted schedule changes are reflected in Today

#### Calendar and history
- [ ] calendar shows medications for a given day
- [ ] calendar supports direct manual edits for confirmed schedules
- [ ] history shows important events such as:
  - medication started
  - medication taken
  - medication stopped
  - dosage updated
  - taken time corrected

#### Assistant workflow
- [ ] chat with the assistant in plain language
- [ ] assistant returns proposed draft events rather than directly changing schedules
- [ ] manually edit proposals before accepting them
- [ ] accept the proposal and show it reflected in Today / Calendar / History

#### Multimodal inputs
- [ ] record a voice note with medication changes
- [ ] take a picture of a prescription to propose changes
- [ ] keep both as proposal-generation inputs, not auto-apply flows

### Admin / Hackathon Readiness
- [ ] pull in all latest files and dependency/runtime versions
- [ ] refresh generated rules and repo conventions
- [ ] verify the end-to-end happy path before polishing edge cases
- [ ] prepare a crisp value proposition for judges/users
- [ ] prepare demo deliverables and fallback assets

### Demo Deliverables
- [ ] live demo path with one clean “magic” scenario
- [ ] README-level feature checklist and narrative
- [ ] short verbal pitch / value proposition
- [ ] screenshots or screen recording backup in case live demo gods are cruel
- [ ] sample prescription / voice-note examples for repeatable demos
- [ ] clear statement of what is already working vs what is stretch

### Stretch Goals
- [ ] integrate a local Gemma 4 model for a fully offline, privacy-first assistant path
- [ ] expand multimodal intake quality for voice and prescription-image parsing
- [ ] tighten proposal UX so review feels like a natural continuation of chat, not admin paperwork

## Current Focus

- tighten temporal modeling around scheduled, taken, and recorded times
- keep history readable while preserving a correct event log
- improve assistant/media input flows without bypassing review
- sharpen the hackathon demo around one end-to-end magical loop
