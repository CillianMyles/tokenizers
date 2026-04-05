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
- In-memory event store and projection runner used as the first architecture
  checkpoint
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
    ├── data/                      # In-memory event store and projections
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

The current default experience is a local demo flow. Type a medication change in
chat, review the generated proposal, and confirm it to project the schedule into
the calendar.

## Environment

Gemini configuration now uses a compile-time define:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

The live Gemini-backed provider has not been reconnected to the new v0 shell
yet. The old prototype path still reads the same `GEMINI_API_KEY` value through
`lib/env/env.dart`.

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

## Next Steps

1. Replace the in-memory event store with Drift-backed persistence and
   projection rebuild support.
2. Add unit tests for reducers, command orchestration, and confirmation gates.
3. Add CI for format, analyze, and test checks on pushes and pull requests.
