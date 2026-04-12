import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// User-configurable AI provider settings.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Uri _geminiAboutUri = Uri.parse('https://gemini.google/about/');
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  GeminiModel? _selectedModel;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final shellPalette = Theme.of(context).extension<AppShellPalette>();

    return ListenableBuilder(
      listenable: bootstrap.aiSettingsController,
      builder: (context, child) {
        final controller = bootstrap.aiSettingsController;
        final settings = controller.settings;
        final selectedModel = _selectedModel ?? settings.geminiModel;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                shellPalette?.gradientStart ?? const Color(0xFFF4F8F5),
                shellPalette?.gradientEnd ?? const Color(0xFFE5EEE8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SettingsInfoNote(
                        title: 'Bring Your Own AI',
                        message:
                            'Your data is private and stored locally. Opt in '
                            'to use AI services to interact with your data '
                            'using natural language, voice, and even images.',
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Gemini',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Configure Google's Gemini model usage with "
                                "your API key.",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _openGeminiLearnMore,
                                child: const Text('Learn more'),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Model',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<GeminiModel>(
                                selected: <GeminiModel>{selectedModel},
                                showSelectedIcon: false,
                                onSelectionChanged: controller.isSaving
                                    ? null
                                    : (selection) {
                                        setState(() {
                                          _selectedModel = selection.first;
                                        });
                                      },
                                segments: GeminiModel.values
                                    .map((model) {
                                      return ButtonSegment<GeminiModel>(
                                        value: model,
                                        label: Text(model.label),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                selectedModel.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _apiKeyController,
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _obscureApiKey,
                                decoration: InputDecoration(
                                  labelText: 'Gemini API key',
                                  hintText: settings.hasApiKey
                                      ? 'Leave blank to keep the current key'
                                      : 'Paste your Gemini API key',
                                  helperText: _helperText(settings),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureApiKey = !_obscureApiKey;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureApiKey
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _apiKeyController,
                                builder: (context, value, child) {
                                  final hasPendingApiKey = value.text
                                      .trim()
                                      .isNotEmpty;
                                  final hasSavedApiKey =
                                      settings.apiKeySource ==
                                      ApiKeySource.stored;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      if (controller.errorMessage
                                          case final message?)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Text(
                                            message,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: <Widget>[
                                          FilledButton.icon(
                                            onPressed:
                                                controller.isSaving ||
                                                    !hasPendingApiKey
                                                ? null
                                                : () {
                                                    _saveSettings(
                                                      context,
                                                      controller: controller,
                                                      geminiModel:
                                                          selectedModel,
                                                    );
                                                  },
                                            icon: controller.isSaving
                                                ? const SizedBox.square(
                                                    dimension: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.save_outlined,
                                                  ),
                                            label: const Text('Save settings'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed:
                                                controller.isSaving ||
                                                    !hasSavedApiKey
                                                ? null
                                                : () {
                                                    _clearApiKey(
                                                      context,
                                                      controller: controller,
                                                    );
                                                  },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text(
                                              'Clear saved key',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearApiKey(
    BuildContext context, {
    required AiSettingsController controller,
  }) async {
    await controller.clearGeminiApiKey();
    if (!context.mounted) {
      return;
    }

    final message = switch (controller.settings.apiKeySource) {
      ApiKeySource.none => 'Gemini API key cleared.',
      ApiKeySource.stored => 'Gemini API key updated.',
      ApiKeySource.debugEnv => 'Gemini API key cleared.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _helperText(AiSettings settings) {
    return switch (settings.apiKeySource) {
      ApiKeySource.none => 'No Gemini key is configured yet.',
      ApiKeySource.stored => 'A Gemini key is already saved on this device.',
      ApiKeySource.debugEnv => 'A Gemini key is already available.',
    };
  }

  Future<void> _saveSettings(
    BuildContext context, {
    required AiSettingsController controller,
    required GeminiModel geminiModel,
  }) async {
    await controller.saveGeminiSettings(
      geminiModel: geminiModel,
      replacementApiKey: _apiKeyController.text,
    );
    if (!context.mounted) {
      return;
    }

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      return;
    }

    _apiKeyController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AI settings saved.')));
  }

  Future<void> _openGeminiLearnMore() async {
    final didLaunch = await launchUrl(
      _geminiAboutUri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (didLaunch || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the Gemini link.')),
    );
  }
}

class _SettingsInfoNote extends StatelessWidget {
  const _SettingsInfoNote({required this.message, required this.title});

  final String message;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
