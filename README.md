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
- Drift-backed `event_log` plus projection tables across native and web
- Gemini-backed `ModelProvider` available in the new shell when
  `GEMINI_API_KEY` is configured in a local `.env`
- Mobile-first draft review launched from the chat composer instead of a
  disconnected side panel
- Direct manual medication add, edit, and remove flows in the calendar screen
- Day-grouped activity history built from the event log
- Medication taken events recorded from the daily schedule view
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
    ├── data/                      # Drift persistence, projections, providers
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
Type a medication change in chat, tap the pending draft above the composer,
edit it if needed, and accept it to project the schedule into the calendar.

Confirmed schedules can also be managed directly from the calendar screen
without going through chat.

The History tab now shows a day-grouped event timeline across assistant,
proposal, medication, and adherence activity.

The event log and read models are stored locally in SQLite via Drift on native
platforms and on the web via the bundled Drift worker + `sqlite3.wasm` assets.

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
time, so no extra launch-time configuration flag is required.

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

1. Add widget and integration coverage for the new draft editor and manual
   medication flows.
2. Add reminder scheduling and delivery events on top of the new activity
   timeline and adherence model.
3. Turn the visible photo and voice affordances into full event-sourced input
   pipelines.
4. Add explicit maintenance docs for the bundled web Drift worker assets.
