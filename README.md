# Tokenizers

Tokenizers is a Flutter application exploring AI-powered health and medical
tracking workflows.

The current focus is a GenUI proof of concept: a prompt-driven prototype that
renders dynamic UI surfaces in Flutter using the
[`genui`](https://pub.dev/packages/genui) package. The app supports two
execution modes:

- **local mock mode** for deterministic prototype iteration with no credentials
- **live Gemini mode** via the Gemini REST API with API key loaded from `.env`

## Current Status

- Flutter project scaffolded for `macos`, `ios`, `android`, `web`, `linux`,
  and `windows`
- `genui` added and integrated into the app shell
- Direct Gemini REST integration added through `http` package
- Prompt-driven prototype screen implemented
- Runtime-generated UI surface rendered from GenUI component definitions
- API key managed via `envied` package (compile-time injection from `.env`)
- Local mock mode available as fallback when no API key is configured
- Live mode sends prompts and UI interaction events to Gemini

## Project Structure

```
lib/
├── main.dart                      # App entrypoint
├── env/
│   ├── env.dart                   # Envied configuration class
│   └── env.g.dart                  # Generated (gitignored, contains API key)
└── src/
    ├── genui_prototype_page.dart   # GenUI proof of concept screen
    └── gemini_genui_service.dart   # Gemini REST integration
```

## Setup

### Prerequisites

- Flutter SDK installed and available on `PATH`
- For macOS: Xcode and CocoaPods installed
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/)

### Environment Configuration

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Add your Gemini API key to `.env`:

```
GEMINI_API_KEY=your_actual_api_key_here
```

3. Generate the envied code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Note**: The generated `lib/env/env.g.dart` file contains your API key and is
> gitignored. Never commit this file or your `.env` file to version control.

### Platform Setup

#### macOS

Requires Xcode command-line tools and CocoaPods:

```bash
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
sudo xcodebuild -license
sudo gem install cocoapods
flutter doctor -v
```

Enable macOS desktop support:

```bash
flutter config --enable-macos-desktop
```

> **Known issue**: macOS sandbox restricts network access. For now, use Chrome
> (web) for live mode testing. macOS entitlements need further configuration for
> outgoing network connections.

## Running the App

### Web (Recommended for Live Mode)

```bash
flutter run -d chrome
```

Web doesn't have sandbox restrictions and works immediately with live Gemini
mode.

### macOS

```bash
flutter run -d macos
```

Mock mode works on macOS. Live mode requires network entitlements (pending).

### Other Platforms

```bash
flutter devices  # List available devices
flutter run -d <device_id>
```

## Using the Prototype

### Mock Mode (Default)

Active when no valid Gemini API key is configured:

- Enter or edit the prototype prompt
- Switch between quick-start workflow presets (Symptom Intake, Medication
  Adherence, Recovery Plan)
- Generate a surface using deterministic mock data
- Interact with generated buttons and text fields
- Watch the app update the GenUI data model and surface status

### Live Gemini Mode

Active when a valid API key is configured:

- Prompts are sent to Gemini REST API
- Responses parsed as GenUI A2UI messages
- Rendered surface updates from live model output
- UI interaction events forwarded into the live model loop
- Interaction log shows request/response status

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GenUiPrototypePage                       │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │    _ControlPane     │    │       _PreviewPane          │ │
│  │  - Prompt input     │    │  - Surface widget           │ │
│  │  - Quick starts     │    │  - Renders GenUI components  │ │
│  │  - Status display   │    │                             │ │
│  │  - Activity log     │    │                             │ │
│  └─────────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │ GeminiGenUiService │
                    │  - REST API calls  │
                    │  - A2UI parsing    │
                    └────────────────────┘
```

## Development

### Code Generation

After modifying `lib/env/env.dart` or adding new envied fields:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Format and Analyze

```bash
dart format .
flutter analyze
```

## Notes

- Adding `genui` pulls in native plugin dependencies; first macOS build may take
  longer while CocoaPods resolves dependencies.
- The upstream `genui_google_generative_ai` package doesn't resolve against
  `genui 0.8.0`, so this project uses the Gemini REST API directly.
- The live path is intended as a prototype integration, not a hardened production
  architecture.
- The project is experimental; the GenUI package itself is explicitly upstream
  experimental.

## Next Steps

1. **Improve live model contract**: Refine prompt strategy so generated health
   workflows are more stable, domain-specific, and less dependent on generic
   component layouts.

2. **Fix macOS network entitlements**: Configure proper code signing and
   entitlements for outgoing network connections in release builds.

3. **Add error handling UI**: Surface API errors more gracefully with retry
   options and clearer status indicators.

4. **Persist surfaces locally**: Cache generated surfaces for offline review and
   comparison.