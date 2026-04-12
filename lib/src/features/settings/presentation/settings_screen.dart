import 'package:flutter/material.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isDeletingData = false;
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
        final hasSavedApiKey = settings.apiKeySource == ApiKeySource.stored;

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
                              TextField(
                                controller: _apiKeyController,
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _obscureApiKey,
                                decoration: InputDecoration(
                                  labelText: 'Gemini API Key',
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
                                                controller.isSavingApiKey ||
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
                                            icon: controller.isSavingApiKey
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
                                            label: const Text('Save key'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed:
                                                controller.isSavingApiKey ||
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
                                            label: const Text('Remove key'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
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
                                onSelectionChanged: controller.isSavingModel
                                    ? null
                                    : (selection) async {
                                        final nextModel = selection.first;
                                        setState(() {
                                          _selectedModel = nextModel;
                                        });
                                        await controller.saveGeminiModel(
                                          nextModel,
                                        );
                                        if (!context.mounted) {
                                          return;
                                        }
                                        if (controller.errorMessage != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                controller.errorMessage!,
                                              ),
                                            ),
                                          );
                                        }
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DangerZoneCard(
                        isDeletingData: _isDeletingData,
                        onDeletePressed: () {
                          _deleteLocalData(context);
                        },
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
      ApiKeySource.stored => 'An API key is already available.',
      ApiKeySource.debugEnv => 'An API key is already available.',
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

  Future<void> _deleteLocalData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteDataDialog(),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final bootstrap = AppScope.of(context);
    setState(() {
      _isDeletingData = true;
    });

    try {
      await bootstrap.localDataResetService.deleteAllLocalData();
      await bootstrap.aiSettingsController.load();
      _apiKeyController.clear();
      _selectedModel = null;

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local data has been deleted.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete local data. ${error.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingData = false;
        });
      }
    }
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

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({
    required this.isDeletingData,
    required this.onDeletePressed,
  });

  final bool isDeletingData;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Danger Zone',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete all local data from this device. This cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isDeletingData ? null : onDeletePressed,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              icon: isDeletingData
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        color: colorScheme.onError,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDataDialog extends StatefulWidget {
  const _DeleteDataDialog();

  @override
  State<_DeleteDataDialog> createState() => _DeleteDataDialogState();
}

class _DeleteDataDialogState extends State<_DeleteDataDialog> {
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete all local data?'),
      content: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _confirmationController,
        builder: (context, value, child) {
          final canDelete = value.text.trim() == 'delete';

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'This will permanently remove your saved medications, '
                'history, conversations, and local AI settings. This '
                'action cannot be recovered.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmationController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Type delete to confirm',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: canDelete
                        ? () {
                            Navigator.of(context).pop(true);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    child: const Text('Delete Data'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
