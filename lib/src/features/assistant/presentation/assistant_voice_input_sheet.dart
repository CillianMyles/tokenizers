import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';
import 'package:tokenizers/src/features/assistant/application/voice_input_controller.dart';

/// Opens the assistant voice input sheet and returns the chosen transcript.
Future<String?> showAssistantVoiceInputSheet(
  BuildContext context, {
  required SpeechToTextService speechToTextService,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return AssistantVoiceInputSheet(speechToTextService: speechToTextService);
    },
  );
}

/// Modal sheet that records a local-only speech transcript.
class AssistantVoiceInputSheet extends StatefulWidget {
  /// Creates the assistant voice input sheet.
  const AssistantVoiceInputSheet({
    required this.speechToTextService,
    super.key,
  });

  /// Local speech-to-text service used by this sheet.
  final SpeechToTextService speechToTextService;

  @override
  State<AssistantVoiceInputSheet> createState() =>
      _AssistantVoiceInputSheetState();
}

class _AssistantVoiceInputSheetState extends State<AssistantVoiceInputSheet> {
  late final VoiceInputController _controller = VoiceInputController(
    speechToTextService: widget.speechToTextService,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_controller.start());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 8,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _controller.isListening
                            ? Icons.graphic_eq
                            : Icons.mic_none_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Record audio',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Speech stays on this device until you insert the transcript.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _controller.errorMessage ?? _controller.helperMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _controller.errorMessage == null
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                if (_controller.isPreparing || _controller.isProcessing)
                  const LinearProgressIndicator(),
                if (_controller.isPreparing || _controller.isProcessing)
                  const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 168),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _controller.transcript.isEmpty
                        ? 'Speak normally. The local transcript will appear here.'
                        : _controller.transcript,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _controller.transcript.isEmpty
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(_controller.canInsert ? 'Close' : 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _primaryAction,
                        icon: Icon(_primaryIcon),
                        label: Text(_primaryLabel),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _primaryAction() async {
    if (_controller.canInsert) {
      Navigator.of(context).pop(_controller.transcript.trim());
      return;
    }
    if (_controller.isListening) {
      await _controller.stop();
      return;
    }
    await _controller.start();
  }

  IconData get _primaryIcon {
    if (_controller.canInsert) {
      return Icons.arrow_downward_rounded;
    }
    if (_controller.isListening) {
      return Icons.stop_rounded;
    }
    return Icons.mic_rounded;
  }

  String get _primaryLabel {
    if (_controller.canInsert) {
      return 'Insert transcript';
    }
    if (_controller.isListening) {
      return 'Stop listening';
    }
    if (_controller.errorMessage != null) {
      return 'Try again';
    }
    return 'Start listening';
  }
}
