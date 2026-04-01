# Tokenizers

Tokenizers is a Flutter application exploring AI-powered health and medical
tracking workflows.

The current focus is a GenUI proof of concept: a prompt-driven prototype that
renders dynamic UI surfaces in Flutter using the
[`genui`](https://pub.dev/packages/genui) package. The app now supports two
execution modes:

- local mock mode for deterministic prototype iteration with no credentials
- live Gemini mode via the Gemini REST API and a compile-time API key

## Current Status

- Flutter project scaffolded for `macos`, `ios`, `android`, `web`, `linux`,
  and `windows`
- `genui` added and integrated into the app shell
- direct Gemini REST integration added through `http`
- prompt-driven prototype screen implemented
- runtime-generated UI surface rendered from GenUI component definitions
- local mock mode still available as a fallback when no API key is configured
- live mode can send prompts and UI interaction events to Gemini

## Project Structure

- `lib/main.dart`: app entrypoint
- `lib/src/genui_prototype_page.dart`: current GenUI proof of concept
- `pubspec.yaml`: Flutter and package dependencies

## macOS Setup

These steps are the baseline for running the app locally on macOS.

### Prerequisites

- macOS
- Flutter SDK installed and available on `PATH`
- Xcode installed
- CocoaPods installed

### Configure macOS Tooling

1. Point command-line tools at Xcode and finish first-run setup:

```bash
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
```

2. Accept Xcode licenses:

```bash
sudo xcodebuild -license
```

3. Install CocoaPods if it is not already installed:

```bash
sudo gem install cocoapods
```

4. Verify the environment:

```bash
flutter doctor -v
flutter devices
```

If `macos` is not listed in `flutter devices`, enable desktop support:

```bash
flutter config --enable-macos-desktop
```

## Getting Started

From the project root:

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app on macOS:

```bash
flutter run -d macos
```

3. Run the live Gemini-backed mode on macOS:

```bash
flutter run -d macos --dart-define=GEMINI_API_KEY=your_api_key_here
```

4. Optional: run it in Chrome instead:

```bash
flutter run -d chrome
```

## Using the Prototype

The current app can run in mock or live mode.

### Mock Mode

Mock mode is active when no Gemini API key is supplied.

- enter or edit the prototype prompt
- switch between the quick-start workflow presets
- generate a surface
- interact with the generated buttons and text field
- watch the app update the GenUI data model and surface status in response

### Live Gemini Mode

Live mode is active when you launch the app with:

```bash
flutter run -d macos --dart-define=GEMINI_API_KEY=your_api_key_here
```

In live mode:

- the prompt is sent to Gemini
- the response is parsed as GenUI A2UI messages
- the rendered surface updates from the live model output
- subsequent UI interaction events are forwarded back into the live model loop

## Notes

- Adding `genui` pulls in native plugin dependencies, so the first macOS build
  may take longer while CocoaPods resolves dependencies.
- The upstream `genui_google_generative_ai` package does not currently resolve
  against `genui 0.8.0`, so this project uses the Gemini REST API directly
  instead.
- The live path is intended as a prototype integration, not a hardened
  production architecture.
- The project is experimental and the GenUI package itself is explicitly
  upstream experimental.

## Next Step

The next milestone is improving the live model contract and prompt strategy so
the generated health workflows are more stable, more domain-specific, and less
dependent on generic component layouts.
