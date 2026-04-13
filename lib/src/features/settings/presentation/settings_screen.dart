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
  static final Uri _googleAiEdgeUri = Uri.parse(
    'https://ai.google.dev/gemma/docs/integrations/mobile',
  );

  final TextEditingController _apiKeyController = TextEditingController();
  bool _isDeletingData = false;
  bool _obscureApiKey = true;
  GeminiModel? _selectedGeminiModel;
  LocalGemmaModel? _selectedLocalModel;

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
        final selectedGeminiModel =
            _selectedGeminiModel ?? settings.geminiModel;
        final selectedLocalModel = _selectedLocalModel ?? settings.localModel;
        final hasSavedApiKey = settings.apiKeySource == ApiKeySource.stored;
        final isLocalModelInstalled = controller.installedLocalModels.contains(
          selectedLocalModel,
        );
        final localDownloadProgress = controller.localModelDownloadProgress;

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
                      const _SettingsInfoNote(
                        title: 'Bring Your Own AI',
                        message:
                            'Your data stays local. Choose between Gemini with '
                            'your own API key or a Gemma 4 model downloaded '
                            'directly to this device.',
                      ),
                      const SizedBox(height: 16),
                      if (controller.errorMessage case final message?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SettingsErrorBanner(message: message),
                        ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Assistant Engine',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Switch the live assistant between cloud Gemini '
                                'and an offline Gemma 4 model.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              SegmentedButton<AiProvider>(
                                selected: <AiProvider>{settings.provider},
                                showSelectedIcon: false,
                                onSelectionChanged: controller.isSavingModel
                                    ? null
                                    : (selection) {
                                        _saveProvider(
                                          context,
                                          controller: controller,
                                          provider: selection.first,
                                        );
                                      },
                                segments: AiProvider.values
                                    .map((provider) {
                                      return ButtonSegment<AiProvider>(
                                        value: provider,
                                        label: Text(provider.label),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                settings.provider.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProviderCard(
                        isActive: settings.provider == AiProvider.gemini,
                        title: 'Gemini',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Configure Google's Gemini model usage with your "
                              'own API key.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                _openUri(
                                  context,
                                  uri: _geminiAboutUri,
                                  failureMessage:
                                      'Could not open the Gemini link.',
                                );
                              },
                              child: const Text('Learn more'),
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 20),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _apiKeyController,
                              builder: (context, value, child) {
                                final hasPendingApiKey = value.text
                                    .trim()
                                    .isNotEmpty;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: <Widget>[
                                    FilledButton.icon(
                                      onPressed:
                                          controller.isSavingApiKey ||
                                              !hasPendingApiKey
                                          ? null
                                          : () {
                                              _saveGeminiSettings(
                                                context,
                                                controller: controller,
                                                geminiModel:
                                                    selectedGeminiModel,
                                              );
                                            },
                                      icon: controller.isSavingApiKey
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.save_outlined),
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
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Remove key'),
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
                              selected: <GeminiModel>{selectedGeminiModel},
                              showSelectedIcon: false,
                              onSelectionChanged: controller.isSavingModel
                                  ? null
                                  : (selection) {
                                      _saveGeminiModelSelection(
                                        context,
                                        controller: controller,
                                        model: selection.first,
                                      );
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
                              selectedGeminiModel.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProviderCard(
                        isActive: settings.provider == AiProvider.localGemma,
                        title: 'Offline Gemma 4',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Download a Gemma 4 checkpoint from Hugging Face '
                              'and keep the assistant fully offline on this '
                              'device. The flow is inspired by Google AI Edge '
                              'Gallery.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    _openUri(
                                      context,
                                      uri: _googleAiEdgeUri,
                                      failureMessage:
                                          'Could not open the AI Edge Gallery reference.',
                                    );
                                  },
                                  child: const Text('AI Edge Gallery'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _openUri(
                                      context,
                                      uri: selectedLocalModel.repositoryUri,
                                      failureMessage:
                                          'Could not open the Hugging Face repository.',
                                    );
                                  },
                                  child: const Text('Hugging Face'),
                                ),
                              ],
                            ),
                            if (controller.localGemmaError case final message?)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  message,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Model',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<LocalGemmaModel>(
                              selected: <LocalGemmaModel>{selectedLocalModel},
                              showSelectedIcon: false,
                              onSelectionChanged: controller.isSavingModel
                                  ? null
                                  : (selection) {
                                      _saveLocalModelSelection(
                                        context,
                                        controller: controller,
                                        model: selection.first,
                                      );
                                    },
                              segments: LocalGemmaModel.values
                                  .map((model) {
                                    return ButtonSegment<LocalGemmaModel>(
                                      value: model,
                                      label: Text(model.label),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${selectedLocalModel.description} '
                              '${selectedLocalModel.sizeLabel}.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            _LocalModelStatusRow(
                              isInstalled: isLocalModelInstalled,
                              model: selectedLocalModel,
                            ),
                            if (controller.isDownloadingLocalModel &&
                                localDownloadProgress != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Downloading ${selectedLocalModel.label}: '
                                      '$localDownloadProgress%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: localDownloadProgress / 100,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                FilledButton.icon(
                                  onPressed:
                                      controller.isDownloadingLocalModel ||
                                          controller.isRemovingLocalModel ||
                                          controller.localGemmaError != null
                                      ? null
                                      : () {
                                          _downloadLocalModel(
                                            context,
                                            controller: controller,
                                            model: selectedLocalModel,
                                          );
                                        },
                                  icon: controller.isDownloadingLocalModel
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          isLocalModelInstalled
                                              ? Icons
                                                    .download_for_offline_outlined
                                              : Icons.download_outlined,
                                        ),
                                  label: Text(
                                    isLocalModelInstalled
                                        ? 'Re-download model'
                                        : 'Download model',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      controller.isDownloadingLocalModel ||
                                          controller.isRemovingLocalModel ||
                                          !isLocalModelInstalled
                                      ? null
                                      : () {
                                          _deleteLocalModel(
                                            context,
                                            controller: controller,
                                            model: selectedLocalModel,
                                          );
                                        },
                                  icon: controller.isRemovingLocalModel
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.delete_outline),
                                  label: const Text('Remove model'),
                                ),
                                TextButton.icon(
                                  onPressed:
                                      controller.isDownloadingLocalModel ||
                                          controller.isRemovingLocalModel
                                      ? null
                                      : () {
                                          _refreshLocalModelStatus(
                                            context,
                                            controller: controller,
                                          );
                                        },
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('Refresh status'),
                                ),
                              ],
                            ),
                          ],
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
      _selectedGeminiModel = null;
      _selectedLocalModel = null;

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

  Future<void> _deleteLocalModel(
    BuildContext context, {
    required AiSettingsController controller,
    required LocalGemmaModel model,
  }) async {
    await controller.deleteLocalGemmaModel(model);
    if (!context.mounted) {
      return;
    }
    if (controller.errorMessage != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${model.label} removed from this device.')),
    );
  }

  Future<void> _downloadLocalModel(
    BuildContext context, {
    required AiSettingsController controller,
    required LocalGemmaModel model,
  }) async {
    await controller.downloadLocalGemmaModel(model);
    if (!context.mounted) {
      return;
    }
    if (controller.errorMessage != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${model.label} is ready for offline use.')),
    );
  }

  String _helperText(AiSettings settings) {
    return switch (settings.apiKeySource) {
      ApiKeySource.none => 'No Gemini key is configured yet.',
      ApiKeySource.stored => 'An API key is already available.',
      ApiKeySource.debugEnv => 'An API key is already available.',
    };
  }

  Future<void> _openUri(
    BuildContext context, {
    required String failureMessage,
    required Uri uri,
  }) async {
    final didLaunch = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (didLaunch || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  Future<void> _refreshLocalModelStatus(
    BuildContext context, {
    required AiSettingsController controller,
  }) async {
    await controller.refreshLocalGemmaStatus();
    if (!context.mounted || controller.errorMessage != null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local model status refreshed.')),
    );
  }

  Future<void> _saveGeminiModelSelection(
    BuildContext context, {
    required AiSettingsController controller,
    required GeminiModel model,
  }) async {
    setState(() {
      _selectedGeminiModel = model;
    });
    await controller.saveGeminiModel(model);
    if (!context.mounted || controller.errorMessage == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
  }

  Future<void> _saveGeminiSettings(
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
    ).showSnackBar(const SnackBar(content: Text('Gemini settings saved.')));
  }

  Future<void> _saveLocalModelSelection(
    BuildContext context, {
    required AiSettingsController controller,
    required LocalGemmaModel model,
  }) async {
    setState(() {
      _selectedLocalModel = model;
    });
    await controller.saveLocalGemmaModel(model);
    if (!context.mounted || controller.errorMessage == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
  }

  Future<void> _saveProvider(
    BuildContext context, {
    required AiProvider provider,
    required AiSettingsController controller,
  }) async {
    await controller.saveProvider(provider);
    if (!context.mounted || controller.errorMessage == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
  }
}

class _LocalModelStatusRow extends StatelessWidget {
  const _LocalModelStatusRow({required this.isInstalled, required this.model});

  final bool isInstalled;
  final LocalGemmaModel model;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isInstalled
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isInstalled
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isInstalled ? Icons.check_circle_outline : Icons.download_outlined,
            size: 18,
            color: foregroundColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isInstalled
                  ? '${model.label} is downloaded and ready.'
                  : '${model.label} is not on this device yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.child,
    required this.isActive,
    required this.title,
  });

  final Widget child;
  final bool isActive;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isActive)
                  Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Active'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsErrorBanner extends StatelessWidget {
  const _SettingsErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
