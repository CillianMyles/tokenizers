# Tokenizers

Tokenizers is a Flutter application exploring reliable, offline-first
medication capture.

The current codebase is moving from a prompt-driven GenUI prototype toward the
v0 architecture in [docs/plans/v0.md](docs/plans/v0.md): a chat-first app shell
with explicit proposal review, confirmation-gated medication changes, and an
event-sourced local data model.

## Current Status

- Routed app shell with `Chat`, `Calendar`, and `History` surfaces
- Pure-Dart event and proposal types for the v0 workflow
- Native Drift-backed `event_log` plus projection tables
- Web fallback still uses the in-memory event store until Drift web assets are
  added
- Gemini-backed `ModelProvider` available in the new shell when
  `GEMINI_API_KEY` is configured
- Unit tests covering projection rebuilds and chat command orchestration
- GitHub Actions CI running format, analyze, and test checks on pushes and PRs
- Deterministic demo model provider behind a `ModelProvider` interface
- Pending proposals remain separate from confirmed medication schedules
- Confirmed schedules project into a day-based medication calendar
- Legacy GenUI prototype code is still present in `lib/src/genui_prototype_page.dart`
  while the new shell is being built out

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

The current default experience is a local demo flow. Type a medication change
in chat, review the generated proposal, and confirm it to project the schedule
into the calendar.

On native platforms, the event log and read models are stored locally in
SQLite via Drift. On web, the app currently falls back to the in-memory demo
store until the required Drift web assets are added.

## Environment

Gemini configuration uses a compile-time define:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

When `GEMINI_API_KEY` is present, the new v0 shell uses the live
`GeminiModelProvider`. Without the key, the app falls back to the deterministic
demo provider.

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

At the moment there is no `test/` directory yet, so `flutter test` exits with
`Test directory "test" not found.` until the first test slice lands.

Regenerate Drift code after changing the database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Next Steps

1. Replace the web fallback with real Drift web persistence assets and setup.
2. Add widget and integration coverage for proposal review and calendar flows.
3. Add attachment, image, and voice ingestion to the event-sourced workflow.
