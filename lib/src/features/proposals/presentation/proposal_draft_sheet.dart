import 'package:flutter/material.dart';

import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_schedule_editor.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// Opens an adaptive draft editor for a pending proposal.
Future<void> showProposalDraftEditor({
  required List<MedicationScheduleView> confirmedSchedules,
  required BuildContext context,
  required Future<void> Function() onCancelProposal,
  required Future<void> Function(List<ProposalActionView> actions)
  onConfirmProposal,
  required ProposalView proposal,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 720) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _ProposalDraftEditorSurface(
          confirmedSchedules: confirmedSchedules,
          onCancelProposal: onCancelProposal,
          onConfirmProposal: onConfirmProposal,
          proposal: proposal,
        );
      },
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _ProposalDraftEditorSurface(
            confirmedSchedules: confirmedSchedules,
            onCancelProposal: onCancelProposal,
            onConfirmProposal: onConfirmProposal,
            proposal: proposal,
          ),
        ),
      );
    },
  );
}

class _EditableProposalAction {
  const _EditableProposalAction({
    required this.actionId,
    required this.draft,
    required this.type,
    this.missingFields = const <String>[],
    this.targetScheduleId,
  });

  factory _EditableProposalAction.fromProposalAction(
    ProposalActionView action, {
    required List<MedicationScheduleView> confirmedSchedules,
  }) {
    final existingSchedule = _findSchedule(
      confirmedSchedules,
      action.targetScheduleId,
      action.medicationName,
    );
    final baseDraft = existingSchedule == null
        ? null
        : MedicationScheduleDraft.fromSchedule(existingSchedule);
    return _EditableProposalAction(
      actionId: action.actionId,
      draft:
          (baseDraft ??
                  MedicationScheduleDraft(
                    medicationName: action.medicationName ?? '',
                    startDate: action.startDate ?? DateTime.now(),
                    times: action.times,
                  ))
              .copyWith(
                doseAmount: action.doseAmount ?? baseDraft?.doseAmount,
                doseSchedule: action.doseSchedule.isNotEmpty
                    ? action.doseSchedule
                    : baseDraft?.doseSchedule,
                doseUnit: action.doseUnit ?? baseDraft?.doseUnit,
                endDate: action.endDate ?? baseDraft?.endDate,
                medicationName:
                    (action.medicationName ?? baseDraft?.medicationName ?? '')
                        .trim(),
                notes: action.notes ?? baseDraft?.notes,
                route: action.route ?? baseDraft?.route,
                startDate: action.startDate ?? baseDraft?.startDate,
                times: action.times.isNotEmpty
                    ? action.times
                    : baseDraft?.times,
              ),
      missingFields: action.missingFields,
      targetScheduleId: action.targetScheduleId,
      type: action.type,
    );
  }

  final String actionId;
  final MedicationScheduleDraft draft;
  final List<String> missingFields;
  final String? targetScheduleId;
  final ProposalActionType type;

  ProposalActionType get effectiveType {
    if (type == ProposalActionType.requestMissingInfo) {
      return ProposalActionType.addMedicationSchedule;
    }
    return type;
  }

  bool get isValid {
    return switch (effectiveType) {
      ProposalActionType.stopMedicationSchedule =>
        targetScheduleId != null && draft.medicationName.trim().isNotEmpty,
      ProposalActionType.addMedicationSchedule ||
      ProposalActionType.requestMissingInfo ||
      ProposalActionType.updateMedicationSchedule => draft.isValid,
    };
  }

  _EditableProposalAction copyWith({
    MedicationScheduleDraft? draft,
    List<String>? missingFields,
    ProposalActionType? type,
  }) {
    return _EditableProposalAction(
      actionId: actionId,
      draft: draft ?? this.draft,
      missingFields: missingFields ?? this.missingFields,
      targetScheduleId: targetScheduleId,
      type: type ?? this.type,
    );
  }

  ProposalActionView toProposalAction() {
    return ProposalActionView(
      actionId: actionId,
      doseAmount: draft.doseAmount,
      doseSchedule: draft.doseSchedule,
      doseUnit: draft.doseUnit,
      endDate: draft.endDate,
      medicationName: draft.medicationName.trim(),
      missingFields: const <String>[],
      notes: draft.notes,
      route: draft.route,
      startDate: draft.startDate,
      targetScheduleId: targetScheduleId,
      times: draft.times,
      type: effectiveType,
    );
  }

  static MedicationScheduleView? _findSchedule(
    List<MedicationScheduleView> schedules,
    String? targetScheduleId,
    String? medicationName,
  ) {
    if (targetScheduleId != null) {
      for (final schedule in schedules) {
        if (schedule.scheduleId == targetScheduleId) {
          return schedule;
        }
      }
    }
    if (medicationName == null || medicationName.trim().isEmpty) {
      return null;
    }
    final normalizedName = medicationName.trim().toLowerCase();
    final matches = schedules
        .where((schedule) {
          return schedule.medicationName.trim().toLowerCase() == normalizedName;
        })
        .toList(growable: false);
    if (matches.length == 1) {
      return matches.single;
    }
    return null;
  }
}

class _ProposalDraftEditorSurface extends StatefulWidget {
  const _ProposalDraftEditorSurface({
    required this.confirmedSchedules,
    required this.onCancelProposal,
    required this.onConfirmProposal,
    required this.proposal,
  });

  final List<MedicationScheduleView> confirmedSchedules;
  final Future<void> Function() onCancelProposal;
  final Future<void> Function(List<ProposalActionView> actions)
  onConfirmProposal;
  final ProposalView proposal;

  @override
  State<_ProposalDraftEditorSurface> createState() =>
      _ProposalDraftEditorSurfaceState();
}

class _ProposalDraftEditorSurfaceState
    extends State<_ProposalDraftEditorSurface> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<_EditableProposalAction> _actions;
  bool _isSubmitting = false;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _actions = widget.proposal.actions
        .map(
          (action) => _EditableProposalAction.fromProposalAction(
            action,
            confirmedSchedules: widget.confirmedSchedules,
          ),
        )
        .toList(growable: true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Review Draft',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Nothing changes until you accept this draft.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    label: Text(
                      '${_actions.length} action${_actions.length == 1 ? '' : 's'}',
                    ),
                  ),
                  Chip(
                    label: Text(formatDayAndTime(widget.proposal.createdAt)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.proposal.assistantText),
              const SizedBox(height: 16),
              ..._actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ProposalActionEditorCard(
                    key: ValueKey(action.actionId),
                    action: action,
                    onChanged: (updatedAction) {
                      setState(() {
                        final index = _actions.indexWhere(
                          (item) => item.actionId == updatedAction.actionId,
                        );
                        _actions[index] = updatedAction;
                      });
                    },
                    onRemove: () {
                      setState(() {
                        _actions.removeWhere(
                          (item) => item.actionId == action.actionId,
                        );
                      });
                    },
                    showValidation: _showValidation,
                  ),
                );
              }),
              if (_actions.isEmpty)
                Text(
                  'Keep at least one action in the draft to accept it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() {
                                _isSubmitting = true;
                              });
                              await widget.onCancelProposal();
                              if (!mounted) {
                                return;
                              }
                              Navigator.of(this.context).pop();
                            },
                      child: const Text('Cancel Proposal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept Draft'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _showValidation = true;
    });
    final isValid =
        _actions.isNotEmpty &&
        _actions.every((action) => action.isValid) &&
        _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    await widget.onConfirmProposal(
      _actions.map((action) => action.toProposalAction()).toList(),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ProposalActionEditorCard extends StatelessWidget {
  const _ProposalActionEditorCard({
    required this.action,
    required this.onChanged,
    required this.onRemove,
    required this.showValidation,
    super.key,
  });

  final _EditableProposalAction action;
  final ValueChanged<_EditableProposalAction> onChanged;
  final VoidCallback onRemove;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Chip(label: Text(_titleForType(action.type))),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove action',
                ),
              ],
            ),
            if (action.missingFields.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Missing details: ${action.missingFields.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            if (action.effectiveType ==
                ProposalActionType.stopMedicationSchedule)
              _StopMedicationActionFields(
                action: action,
                onChanged: onChanged,
                showValidation: showValidation,
              )
            else
              MedicationScheduleDraftFormSection(
                initialDraft: action.draft,
                onChanged: (draft) {
                  onChanged(action.copyWith(draft: draft));
                },
                showValidation: showValidation,
              ),
          ],
        ),
      ),
    );
  }

  String _titleForType(ProposalActionType type) {
    return switch (type) {
      ProposalActionType.addMedicationSchedule => 'Add medication',
      ProposalActionType.requestMissingInfo => 'Complete draft',
      ProposalActionType.stopMedicationSchedule => 'Remove medication',
      ProposalActionType.updateMedicationSchedule => 'Update medication',
    };
  }
}

class _StopMedicationActionFields extends StatelessWidget {
  const _StopMedicationActionFields({
    required this.action,
    required this.onChanged,
    required this.showValidation,
  });

  final _EditableProposalAction action;
  final ValueChanged<_EditableProposalAction> onChanged;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          initialValue: action.draft.medicationName,
          decoration: const InputDecoration(
            labelText: 'Medication',
            hintText: 'Metformin',
          ),
          onChanged: (value) {
            onChanged(
              action.copyWith(
                draft: action.draft.copyWith(medicationName: value.trim()),
              ),
            );
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a medication name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pickStopDate(context),
          icon: const Icon(Icons.event_busy_outlined),
          label: Text('Stop ${formatShortDate(action.draft.startDate)}'),
        ),
        if (showValidation && action.targetScheduleId == null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'This draft is missing a target schedule.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _pickStopDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      initialDate: action.draft.startDate,
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) {
      return;
    }
    onChanged(
      action.copyWith(draft: action.draft.copyWith(startDate: selectedDate)),
    );
  }
}
