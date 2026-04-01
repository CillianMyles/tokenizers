import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

const _surfaceId = 'prototype-surface';

/// Material app shell for the local GenUI proof of concept.
class GenUiPrototypeApp extends StatelessWidget {
  /// Creates the application shell.
  const GenUiPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0C7A6C),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tokenizers GenUI Prototype',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        appBarTheme: AppBarThemeData(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const GenUiPrototypePage(),
    );
  }
}

/// Interactive page that demonstrates a local `genui` workflow prototype.
class GenUiPrototypePage extends StatefulWidget {
  /// Creates the GenUI prototype page.
  const GenUiPrototypePage({super.key});

  @override
  State<GenUiPrototypePage> createState() => _GenUiPrototypePageState();
}

class _GenUiPrototypePageState extends State<GenUiPrototypePage> {
  late final SurfaceController _controller;
  late final TextEditingController _promptController;
  StreamSubscription<ChatMessage>? _submitSubscription;

  final List<String> _activityLog = <String>[];
  _PrototypeBlueprint _activeBlueprint = _PrototypeBlueprint.intake();

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: _PrototypeBlueprint.intake().suggestedPrompt,
    );
    _controller = SurfaceController(catalogs: [BasicCatalogItems.asCatalog()]);
    _controller.handleMessage(
      const CreateSurface(
        surfaceId: _surfaceId,
        catalogId: basicCatalogId,
        sendDataModel: true,
      ),
    );
    _submitSubscription = _controller.onSubmit.listen(_handleGeneratedEvent);
    _generatePrototype(_promptController.text, origin: 'Loaded default demo');
  }

  @override
  void dispose() {
    _submitSubscription?.cancel();
    _promptController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _generatePrototype(String prompt, {required String origin}) {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return;
    }

    final blueprint = _PrototypeBlueprint.fromPrompt(trimmedPrompt);
    _controller.handleMessage(
      UpdateDataModel(surfaceId: _surfaceId, value: blueprint.initialData),
    );
    _controller.handleMessage(
      UpdateComponents(
        surfaceId: _surfaceId,
        components: _buildComponents(blueprint),
      ),
    );

    setState(() {
      _activeBlueprint = blueprint;
      _activityLog.insert(
        0,
        '$origin: generated "${blueprint.label}" from "$trimmedPrompt".',
      );
      if (_activityLog.length > 8) {
        _activityLog.removeLast();
      }
    });
  }

  List<Component> _buildComponents(_PrototypeBlueprint blueprint) {
    return <Component>[
      const Component(
        id: 'root',
        type: 'Column',
        properties: {
          'children': <String>[
            'hero_card',
            'notes_field',
            'action_row',
            'explain_card',
          ],
        },
      ),
      const Component(
        id: 'hero_card',
        type: 'Card',
        properties: {'child': 'hero_content'},
      ),
      const Component(
        id: 'hero_content',
        type: 'Column',
        properties: {
          'children': <String>[
            'title_text',
            'subtitle_text',
            'status_title_text',
            'status_body_text',
          ],
        },
      ),
      const Component(
        id: 'title_text',
        type: 'Text',
        properties: {
          'text': {'path': '/title'},
          'variant': 'h2',
        },
      ),
      const Component(
        id: 'subtitle_text',
        type: 'Text',
        properties: {
          'text': {'path': '/subtitle'},
        },
      ),
      const Component(
        id: 'status_title_text',
        type: 'Text',
        properties: {
          'text': {'path': '/statusHeadline'},
          'variant': 'h4',
        },
      ),
      const Component(
        id: 'status_body_text',
        type: 'Text',
        properties: {
          'text': {'path': '/statusBody'},
        },
      ),
      const Component(
        id: 'notes_field',
        type: 'TextField',
        properties: {
          'label': {'path': '/noteLabel'},
          'value': {'path': '/notes'},
          'variant': 'longText',
          'onSubmittedAction': {
            'event': {
              'name': 'notes_submitted',
              'context': {
                'notes': {'path': '/notes'},
              },
            },
          },
        },
      ),
      const Component(
        id: 'action_row',
        type: 'Row',
        properties: {
          'children': <String>['primary_button', 'secondary_button'],
        },
      ),
      Component(
        id: 'primary_button',
        type: 'Button',
        properties: <String, Object>{
          'child': 'primary_button_text',
          'action': <String, Object>{
            'event': <String, Object>{'name': blueprint.primaryActionEvent},
          },
        },
      ),
      const Component(
        id: 'primary_button_text',
        type: 'Text',
        properties: {
          'text': {'path': '/primaryActionLabel'},
        },
      ),
      Component(
        id: 'secondary_button',
        type: 'Button',
        properties: <String, Object>{
          'child': 'secondary_button_text',
          'action': <String, Object>{
            'event': <String, Object>{'name': blueprint.secondaryActionEvent},
          },
        },
      ),
      const Component(
        id: 'secondary_button_text',
        type: 'Text',
        properties: {
          'text': {'path': '/secondaryActionLabel'},
        },
      ),
      const Component(
        id: 'explain_card',
        type: 'Card',
        properties: {'child': 'explain_content'},
      ),
      const Component(
        id: 'explain_content',
        type: 'Column',
        properties: {
          'children': <String>[
            'explain_title',
            'explain_body',
            'last_action_title',
            'last_action_body',
          ],
        },
      ),
      const Component(
        id: 'explain_title',
        type: 'Text',
        properties: {
          'text': {'path': '/explanationTitle'},
          'variant': 'h4',
        },
      ),
      const Component(
        id: 'explain_body',
        type: 'Text',
        properties: {
          'text': {'path': '/explanationBody'},
        },
      ),
      const Component(
        id: 'last_action_title',
        type: 'Text',
        properties: {
          'text': {'path': '/lastActionTitle'},
          'variant': 'h5',
        },
      ),
      const Component(
        id: 'last_action_body',
        type: 'Text',
        properties: {
          'text': {'path': '/lastActionBody'},
        },
      ),
    ];
  }

  void _handleGeneratedEvent(ChatMessage message) {
    if (message.parts.uiInteractionParts.isEmpty) {
      return;
    }

    final UiInteractionPart part = message.parts.uiInteractionParts.first;
    final Map<String, Object?> payload =
        jsonDecode(part.interaction) as Map<String, Object?>;
    final Map<String, Object?> action =
        payload['action']! as Map<String, Object?>;
    final String actionName = action['name']! as String;
    final Map<String, Object?> context =
        (action['context'] as Map?)?.cast<String, Object?>() ??
        <String, Object?>{};

    switch (actionName) {
      case 'notes_submitted':
        final String notes = (context['notes'] as String?)?.trim() ?? '';
        _updateSurfaceStatus(
          headline: 'Notes captured',
          body: notes.isEmpty
              ? 'The generated surface submitted an empty note payload.'
              : 'Captured note: "$notes"',
          activity:
              'Submitted notes from generated UI${notes.isEmpty ? '.' : ': "$notes".'}',
        );
      case 'book_follow_up':
        _updateSurfaceStatus(
          headline: 'Follow-up visit queued',
          body:
              'The prototype loop reacted to the generated action and moved '
              'the workflow into scheduling.',
          activity: 'Triggered generated action: book follow-up.',
        );
      case 'escalate_case':
        _updateSurfaceStatus(
          headline: 'Escalated to clinical review',
          body:
              'GenUI signalled a high-risk branch and the host app updated the '
              'surface state immediately.',
          activity: 'Triggered generated action: escalate case.',
        );
      case 'send_reminder':
        _updateSurfaceStatus(
          headline: 'Adherence reminder scheduled',
          body:
              'The generated screen requested a medication reminder flow for '
              'the patient.',
          activity: 'Triggered generated action: send reminder.',
        );
      case 'connect_pharmacist':
        _updateSurfaceStatus(
          headline: 'Pharmacist consult requested',
          body:
              'The prototype routed the interaction toward pharmacist support.',
          activity: 'Triggered generated action: connect pharmacist.',
        );
      case 'start_rehab_checkin':
        _updateSurfaceStatus(
          headline: 'Rehab check-in opened',
          body:
              'The generated recovery plan asked the host app to begin the '
              'next guided session.',
          activity: 'Triggered generated action: start rehab check-in.',
        );
      case 'share_progress':
        _updateSurfaceStatus(
          headline: 'Progress summary prepared',
          body:
              'The prototype assembled a clinician-friendly update request from '
              'the generated UI.',
          activity: 'Triggered generated action: share progress.',
        );
    }
  }

  void _updateSurfaceStatus({
    required String headline,
    required String body,
    required String activity,
  }) {
    _controller.handleMessage(
      UpdateDataModel(
        surfaceId: _surfaceId,
        path: DataPath('/statusHeadline'),
        value: headline,
      ),
    );
    _controller.handleMessage(
      UpdateDataModel(
        surfaceId: _surfaceId,
        path: DataPath('/statusBody'),
        value: body,
      ),
    );
    _controller.handleMessage(
      UpdateDataModel(
        surfaceId: _surfaceId,
        path: DataPath('/lastActionBody'),
        value: activity,
      ),
    );

    setState(() {
      _activityLog.insert(0, activity);
      if (_activityLog.length > 8) {
        _activityLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tokenizers GenUI Prototype')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth >= 980;
          final EdgeInsets pagePadding = EdgeInsets.symmetric(
            horizontal: wide ? 28 : 16,
            vertical: 20,
          );

          if (wide) {
            return Padding(
              padding: pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 360,
                    child: _ControlPane(
                      promptController: _promptController,
                      activeBlueprint: _activeBlueprint,
                      activityLog: _activityLog,
                      onGenerate: () => _generatePrototype(
                        _promptController.text,
                        origin: 'Manual prompt',
                      ),
                      onPickBlueprint: (blueprint) {
                        _promptController.text = blueprint.suggestedPrompt;
                        _generatePrototype(
                          blueprint.suggestedPrompt,
                          origin: 'Template switch',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _PreviewPane(controller: _controller)),
                ],
              ),
            );
          }

          return Padding(
            padding: pagePadding,
            child: ListView(
              children: [
                _ControlPane(
                  promptController: _promptController,
                  activeBlueprint: _activeBlueprint,
                  activityLog: _activityLog,
                  onGenerate: () => _generatePrototype(
                    _promptController.text,
                    origin: 'Manual prompt',
                  ),
                  onPickBlueprint: (blueprint) {
                    _promptController.text = blueprint.suggestedPrompt;
                    _generatePrototype(
                      blueprint.suggestedPrompt,
                      origin: 'Template switch',
                    );
                  },
                ),
                const SizedBox(height: 20),
                _PreviewPane(controller: _controller),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ControlPane extends StatelessWidget {
  const _ControlPane({
    required this.promptController,
    required this.activeBlueprint,
    required this.activityLog,
    required this.onGenerate,
    required this.onPickBlueprint,
  });

  final TextEditingController promptController;
  final _PrototypeBlueprint activeBlueprint;
  final List<String> activityLog;
  final VoidCallback onGenerate;
  final ValueChanged<_PrototypeBlueprint> onPickBlueprint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD9E4E1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt-driven UI prototype',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This demo uses `genui` locally. The "agent" step is mocked, '
                  'but the surface rendering, event submission, and data-model '
                  'updates are real.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: promptController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Prototype prompt',
                    hintText:
                        'Describe a health workflow you want the UI to build.',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onGenerate,
                    child: const Text('Generate surface'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD9E4E1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick starts', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _PrototypeBlueprint.all.map((blueprint) {
                    final bool selected =
                        blueprint.label == activeBlueprint.label;
                    return FilledButton.tonal(
                      onPressed: () => onPickBlueprint(blueprint),
                      style: FilledButton.styleFrom(
                        backgroundColor: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      child: Text(blueprint.label),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD9E4E1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interaction log', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final entry in activityLog.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(entry),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.controller});

  final SurfaceController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 720,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD9E4E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12073B33),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rendered GenUI surface', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'The right-hand panel is rendered from `genui` components and '
                'a runtime data model, not hand-authored Flutter layout '
                'widgets.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Surface(
                          surfaceContext: controller.contextFor(_surfaceId),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeBlueprint {
  const _PrototypeBlueprint({
    required this.label,
    required this.suggestedPrompt,
    required this.initialData,
    required this.primaryActionEvent,
    required this.secondaryActionEvent,
  });

  final String label;
  final String suggestedPrompt;
  final Map<String, Object?> initialData;
  final String primaryActionEvent;
  final String secondaryActionEvent;

  static List<_PrototypeBlueprint> get all => <_PrototypeBlueprint>[
    intake(),
    adherence(),
    recovery(),
  ];

  static _PrototypeBlueprint fromPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    if (normalized.contains('medication') ||
        normalized.contains('adherence') ||
        normalized.contains('reminder')) {
      return adherence();
    }
    if (normalized.contains('recovery') ||
        normalized.contains('rehab') ||
        normalized.contains('discharge')) {
      return recovery();
    }
    return intake();
  }

  static _PrototypeBlueprint intake() {
    return const _PrototypeBlueprint(
      label: 'Symptom Intake',
      suggestedPrompt:
          'Build a symptom intake surface for a remote clinic triage flow.',
      primaryActionEvent: 'book_follow_up',
      secondaryActionEvent: 'escalate_case',
      initialData: <String, Object?>{
        'title': 'Remote symptom intake',
        'subtitle':
            'GenUI assembled a care surface for triage, note capture, and '
            'escalation decisions.',
        'statusHeadline': 'Awaiting triage decision',
        'statusBody':
            'Patient symptoms are captured, but no escalation path has been '
            'triggered yet.',
        'noteLabel': 'Patient notes',
        'notes':
            'Shortness of breath is worse after walking upstairs for 2 days.',
        'primaryActionLabel': 'Book follow-up',
        'secondaryActionLabel': 'Escalate to nurse',
        'explanationTitle': 'Why this proves the concept',
        'explanationBody':
            'The app is rendering a runtime-defined surface instead of a fixed '
            'Flutter page. Prompt selection changes the generated component '
            'tree and seeded data model.',
        'lastActionTitle': 'Latest host reaction',
        'lastActionBody':
            'No generated action has fired yet. Tap one of the buttons below.',
      },
    );
  }

  static _PrototypeBlueprint adherence() {
    return const _PrototypeBlueprint(
      label: 'Medication Adherence',
      suggestedPrompt:
          'Create a medication adherence check-in with reminders and support '
          'actions.',
      primaryActionEvent: 'send_reminder',
      secondaryActionEvent: 'connect_pharmacist',
      initialData: <String, Object?>{
        'title': 'Medication adherence check-in',
        'subtitle':
            'This surface focuses on missed doses, friction points, and the '
            'next best intervention.',
        'statusHeadline': 'Adherence risk is moderate',
        'statusBody':
            'The patient missed two evening doses this week and asked for a '
            'simpler routine.',
        'noteLabel': 'Barrier notes',
        'notes': 'Evening dose often gets skipped after late work shifts.',
        'primaryActionLabel': 'Send reminder plan',
        'secondaryActionLabel': 'Connect pharmacist',
        'explanationTitle': 'What changes with the prompt',
        'explanationBody':
            'The component structure stays reusable, but the runtime data and '
            'action semantics shift to a medication-focused workflow.',
        'lastActionTitle': 'Latest host reaction',
        'lastActionBody':
            'No generated action has fired yet. Submit notes or trigger a '
            'support action.',
      },
    );
  }

  static _PrototypeBlueprint recovery() {
    return const _PrototypeBlueprint(
      label: 'Recovery Plan',
      suggestedPrompt:
          'Prototype a post-discharge recovery dashboard with rehab and '
          'progress sharing actions.',
      primaryActionEvent: 'start_rehab_checkin',
      secondaryActionEvent: 'share_progress',
      initialData: <String, Object?>{
        'title': 'Post-discharge recovery plan',
        'subtitle':
            'A runtime-generated recovery surface can adapt to the patient’s '
            'current milestone and care team needs.',
        'statusHeadline': 'Recovery trend is improving',
        'statusBody':
            'Mobility is up 14% week over week, but fatigue remains a watch '
            'item.',
        'noteLabel': 'Recovery notes',
        'notes': 'Patient completed 3 of 4 prescribed rehab sessions.',
        'primaryActionLabel': 'Start rehab check-in',
        'secondaryActionLabel': 'Share progress update',
        'explanationTitle': 'Why this matters',
        'explanationBody':
            'Generated surfaces are useful when workflows change frequently or '
            'must be tuned per condition, program, or clinician preference.',
        'lastActionTitle': 'Latest host reaction',
        'lastActionBody':
            'No generated action has fired yet. The host app is waiting for '
            'surface events.',
      },
    );
  }
}
