import 'package:flutter/material.dart';

import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Opens an adaptive medication schedule editor.
Future<MedicationScheduleDraft?> showMedicationScheduleEditor({
  required BuildContext context,
  required MedicationScheduleDraft initialDraft,
  required String title,
  String submitLabel = 'Save',
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 720) {
    return showModalBottomSheet<MedicationScheduleDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _MedicationScheduleEditorSurface(
          initialDraft: initialDraft,
          submitLabel: submitLabel,
          title: title,
        );
      },
    );
  }
  return showDialog<MedicationScheduleDraft>(
    context: context,
    builder: (context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _MedicationScheduleEditorSurface(
            initialDraft: initialDraft,
            submitLabel: submitLabel,
            title: title,
          ),
        ),
      );
    },
  );
}

class _MedicationScheduleEditorSurface extends StatefulWidget {
  const _MedicationScheduleEditorSurface({
    required this.initialDraft,
    required this.submitLabel,
    required this.title,
  });

  final MedicationScheduleDraft initialDraft;
  final String submitLabel;
  final String title;

  @override
  State<_MedicationScheduleEditorSurface> createState() =>
      _MedicationScheduleEditorSurfaceState();
}

class _MedicationScheduleEditorSurfaceState
    extends State<_MedicationScheduleEditorSurface> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late MedicationScheduleDraft _draft;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
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
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              MedicationScheduleDraftFormSection(
                initialDraft: _draft,
                onChanged: (draft) {
                  _draft = draft;
                },
                showValidation: _showValidation,
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _showValidation = true;
                        });
                        final isValid =
                            _formKey.currentState!.validate() &&
                            _draft.times.isNotEmpty;
                        if (!isValid) {
                          return;
                        }
                        Navigator.of(context).pop(_draft);
                      },
                      child: Text(widget.submitLabel),
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
}

/// Shared medication schedule fields used by manual and AI-assisted editing.
class MedicationScheduleDraftFormSection extends StatefulWidget {
  /// Creates a medication schedule draft form section.
  const MedicationScheduleDraftFormSection({
    required this.initialDraft,
    required this.onChanged,
    this.showValidation = false,
    super.key,
  });

  final MedicationScheduleDraft initialDraft;
  final ValueChanged<MedicationScheduleDraft> onChanged;
  final bool showValidation;

  @override
  State<MedicationScheduleDraftFormSection> createState() =>
      _MedicationScheduleDraftFormSectionState();
}

class _MedicationScheduleDraftFormSectionState
    extends State<MedicationScheduleDraftFormSection> {
  late final TextEditingController _medicationNameController;
  late final TextEditingController _doseAmountController;
  late final TextEditingController _doseUnitController;
  late final TextEditingController _routeController;
  late final TextEditingController _notesController;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<String> _times;

  @override
  void initState() {
    super.initState();
    _medicationNameController = TextEditingController(
      text: widget.initialDraft.medicationName,
    );
    _doseAmountController = TextEditingController(
      text: widget.initialDraft.doseAmount ?? '',
    );
    _doseUnitController = TextEditingController(
      text: widget.initialDraft.doseUnit ?? '',
    );
    _routeController = TextEditingController(text: widget.initialDraft.route);
    _notesController = TextEditingController(text: widget.initialDraft.notes);
    _startDate = widget.initialDraft.startDate;
    _endDate = widget.initialDraft.endDate;
    _times = List<String>.from(widget.initialDraft.times);

    for (final controller in <TextEditingController>[
      _medicationNameController,
      _doseAmountController,
      _doseUnitController,
      _routeController,
      _notesController,
    ]) {
      controller.addListener(_notifyChanged);
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _doseAmountController.dispose();
    _doseUnitController.dispose();
    _routeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: _medicationNameController,
          decoration: const InputDecoration(
            labelText: 'Medication',
            hintText: 'Vitamin D',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a medication name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _doseAmountController,
                decoration: const InputDecoration(
                  labelText: 'Dose amount',
                  hintText: '500',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _doseUnitController,
                decoration: const InputDecoration(
                  labelText: 'Dose unit',
                  hintText: 'mg',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Times', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ..._times.map((time) {
              return InputChip(
                label: Text(time),
                onDeleted: () {
                  setState(() {
                    _times.remove(time);
                  });
                  _notifyChanged();
                },
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add time'),
              onPressed: () => _addTime(context),
            ),
          ],
        ),
        if (widget.showValidation && _times.isEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'Add at least one time.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickStartDate(context),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Start ${formatShortDate(_startDate)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickEndDate(context),
                icon: Icon(
                  _endDate == null
                      ? Icons.event_busy_outlined
                      : Icons.event_available_outlined,
                ),
                label: Text(
                  _endDate == null
                      ? 'No end date'
                      : 'End ${formatShortDate(_endDate!)}',
                ),
              ),
            ),
          ],
        ),
        if (_endDate != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _endDate = null;
                });
                _notifyChanged();
              },
              child: const Text('Clear end date'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _routeController,
          decoration: const InputDecoration(
            labelText: 'Route',
            hintText: 'By mouth',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Take with food',
          ),
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Future<void> _addTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (selectedTime == null) {
      return;
    }
    final formatted = _formatTimeOfDay(selectedTime);
    if (_times.contains(formatted)) {
      return;
    }
    setState(() {
      _times = <String>[..._times, formatted]..sort();
    });
    _notifyChanged();
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      initialDate: _endDate ?? _startDate,
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) {
      return;
    }
    setState(() {
      _endDate = selectedDate;
    });
    _notifyChanged();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      initialDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) {
      return;
    }
    setState(() {
      _startDate = selectedDate;
    });
    _notifyChanged();
  }

  void _notifyChanged() {
    widget.onChanged(
      MedicationScheduleDraft(
        doseAmount: _trimToNull(_doseAmountController.text),
        doseUnit: _trimToNull(_doseUnitController.text),
        endDate: _endDate,
        medicationName: _medicationNameController.text.trim(),
        notes: _trimToNull(_notesController.text),
        route: _trimToNull(_routeController.text),
        startDate: _startDate,
        times: List<String>.unmodifiable(_times),
      ),
    );
  }

  String? _trimToNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
