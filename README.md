# Tokenizers

Tokenizers is a Flutter application exploring AI-powered health and medical
tracking workflows.

The current focus is a GenUI proof of concept: a prompt-driven prototype that
renders dynamic UI surfaces in Flutter using the
[`genui`](https://pub.dev/packages/genui) package. Right now, the app uses a
local mock generation step to demonstrate the rendering loop, data model, and
surface event handling without requiring a live AI backend.

## Current Status

- Flutter project scaffolded for `macos`, `ios`, `android`, `web`, `linux`,
  and `windows`
- `genui` added and integrated into the app shell
- prompt-driven prototype screen implemented
- runtime-generated UI surface rendered from GenUI component definitions
- generated UI events routed back into the host app and reflected in the
  surface state

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

3. Optional: run it in Chrome instead:

```bash
flutter run -d chrome
```

## Using the Prototype

The current app is a local GenUI demo, not a production workflow yet.

- enter or edit the prototype prompt
- switch between the quick-start workflow presets
- generate a surface
- interact with the generated buttons and text field
- watch the app update the GenUI data model and surface status in response

## Notes

- The current generation step is mocked locally. It does not yet call a live
  model backend.
- Adding `genui` pulls in native plugin dependencies, so the first macOS build
  may take longer while CocoaPods resolves dependencies.
- The project is experimental and the GenUI package itself is explicitly
  upstream experimental.

## Next Step

The next milestone is replacing the local mock blueprint mapping with a real
AI-backed generation flow while keeping the same rendered GenUI surface model.
