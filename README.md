# CarePal

CarePal is a Flutter medication tracker with a local event-sourced data
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

Run the app:

```bash
flutter run -d ios
```

Or:

```bash
flutter run -d chrome
```

If `GEMINI_API_KEY` is missing, the assistant remains visible but live
assistant submission is disabled. Manual calendar and adherence flows still
work.

## Local Data

All app data is stored locally.

- native platforms use Drift on SQLite
- web uses Drift with the bundled SQLite worker/wasm assets
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

Regenerate generated database code after schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerate repo rules:

```bash
make rules-generate
```

## Current Focus

- tighten temporal modeling around scheduled, taken, and recorded times
- keep history readable while preserving a correct event log
- improve assistant/media input flows without bypassing review
