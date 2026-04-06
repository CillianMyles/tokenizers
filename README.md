# Tokenizers

Tokenizers is a Flutter application exploring reliable, offline-first
medication capture.

The current codebase is implementing the v0 architecture in
[docs/plans/v0.md](docs/plans/v0.md): a chat-first app shell with explicit
proposal review, confirmation-gated medication changes, and an event-sourced
local data model.

## Current Status

- Routed app shell with `Chat`, `Calendar`, and `History` surfaces
- Pure-Dart event and proposal types for the v0 workflow
- Native Drift-backed `event_log` plus projection tables
- Gemini-backed `ModelProvider` available in the new shell when
  `GEMINI_API_KEY` is configured in a local `.env`
- Unit tests covering projection rebuilds and chat command orchestration
- GitHub Actions CI running format, analyze, and test checks on pushes and PRs
- Pending proposals remain separate from confirmed medication schedules
- Confirmed schedules project into a day-based medication calendar

## Project Structure

```text
lib/
├── main.dart
├── env/
│   └── env.dart
└── src/
    ├── app/                       # App shell, routing, theme, scope
    ├── bootstrap/                 # Service/bootstrap wiring
    ├── core/                      # Shared event and model contracts
    ├── data/                      # Drift + in-memory persistence layers
    └── features/
        ├── calendar/
        ├── chat/
        ├── history/
        └── proposals/
```

## Running the App

```bash
flutter run -d chrome
```

The current default experience is a Gemini-backed medication capture flow.
Type a medication change in chat, review the generated proposal, and confirm it
to project the schedule into the calendar.

The event log and read models are stored locally in SQLite via Drift on native
platforms and on the web.

## Environment

Each developer should keep their own Gemini key in a local `.env` file that is
ignored by git.

1. Copy `.env.example` to `.env`.
2. Set `GEMINI_API_KEY=your_key_here`.

When `GEMINI_API_KEY` is present, the new v0 shell uses the live
`GeminiModelProvider`.

Without the key, the app now shows a configuration error banner and disables
medication submission instead of falling back to a local demo model.

The `.env` file is bundled as a local Flutter asset for your machine at build
time, so no `--dart-define` flag is required.

## Development

Format and analyze:

```bash
dart format .
flutter analyze
```

Run tests:

```bash
flutter test
```

Regenerate Drift code after changing the database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerate AI tool rules and then reapply the Codex Flutter MCP approval block:

```bash
make rules-generate
```

## Next Steps

1. Add widget and integration coverage for proposal review and calendar flows.
2. Add attachment, image, and voice ingestion to the event-sourced workflow.
3. Improve the web persistence setup and worker asset maintenance workflow.
