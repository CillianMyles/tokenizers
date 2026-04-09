import 'package:flutter/material.dart';

import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
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
                            _draft.resolvedDoseSchedule.isNotEmpty;
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
  late final TextEditingController _routeController;
  late final TextEditingController _notesController;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<_DoseTimeDraftRow> _rows;

  @override
  void initState() {
    super.initState();
    _medicationNameController = TextEditingController(
      text: widget.initialDraft.medicationName,
    );
    _routeController = TextEditingController(text: widget.initialDraft.route);
    _notesController = TextEditingController(text: widget.initialDraft.notes);
    _startDate = widget.initialDraft.startDate;
    _endDate = widget.initialDraft.endDate;
    _rows = widget.initialDraft.resolvedDoseSchedule
        .map(
          (entry) => _DoseTimeDraftRow(
            doseAmountController: TextEditingController(
              text: entry.doseAmount ?? '',
            ),
            doseUnitController: TextEditingController(
              text: entry.doseUnit ?? '',
            ),
            time: entry.time,
          ),
        )
        .toList(growable: true);

    for (final controller in <TextEditingController>[
      _medicationNameController,
      _routeController,
      _notesController,
    ]) {
      controller.addListener(_notifyChanged);
    }
    for (final row in _rows) {
      _attachRow(row);
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _routeController.dispose();
    _notesController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
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
            hintText: 'Tacrolimus',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a medication name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text('Times and doses', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Set each time with its own dose.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          Text(
            'No timed doses yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ..._rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DoseTimeRowEditor(
                onDelete: _rows.length == 1
                    ? null
                    : () {
                        setState(() {
                          _detachRow(row);
                          _rows.remove(row);
                        });
                        _notifyChanged();
                      },
                onPickTime: () => _pickTimeForRow(context, row),
                row: row,
              ),
            );
          }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Add time and dose'),
          onPressed: () => _addTime(context),
        ),
        if (widget.showValidation && _rows.isEmpty) ...<Widget>[
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

  void _attachRow(_DoseTimeDraftRow row) {
    row.doseAmountController.addListener(_notifyChanged);
    row.doseUnitController.addListener(_notifyChanged);
  }

  Future<void> _addTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (selectedTime == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final formatted = _formatTimeOfDay(selectedTime);
    if (_hasTimeConflict(formatted)) {
      _showDuplicateTimeMessage(context);
      return;
    }
    final previous = _rows.isEmpty ? null : _rows.last;
    final row = _DoseTimeDraftRow(
      doseAmountController: TextEditingController(
        text: previous?.doseAmountController.text ?? '',
      ),
      doseUnitController: TextEditingController(
        text: previous?.doseUnitController.text ?? '',
      ),
      time: formatted,
    );
    _attachRow(row);
    setState(() {
      _rows = <_DoseTimeDraftRow>[..._rows, row]..sort(_compareRows);
    });
    _notifyChanged();
  }

  int _compareRows(_DoseTimeDraftRow left, _DoseTimeDraftRow right) {
    return left.time.compareTo(right.time);
  }

  void _detachRow(_DoseTimeDraftRow row) {
    row.doseAmountController.removeListener(_notifyChanged);
    row.doseUnitController.removeListener(_notifyChanged);
    row.dispose();
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  bool _hasTimeConflict(String time, {_DoseTimeDraftRow? excluding}) {
    for (final row in _rows) {
      if (!identical(row, excluding) && row.time == time) {
        return true;
      }
    }
    return false;
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

  Future<void> _pickTimeForRow(
    BuildContext context,
    _DoseTimeDraftRow row,
  ) async {
    final current = row.time.split(':');
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(current[0]),
        minute: int.parse(current[1]),
      ),
    );
    if (selectedTime == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final formatted = _formatTimeOfDay(selectedTime);
    if (_hasTimeConflict(formatted, excluding: row)) {
      _showDuplicateTimeMessage(context);
      return;
    }
    setState(() {
      row.time = formatted;
      _rows.sort(_compareRows);
    });
    _notifyChanged();
  }

  void _showDuplicateTimeMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('That time is already in the schedule.')),
    );
  }

  void _notifyChanged() {
    final doseSchedule = _rows
        .map(
          (row) => MedicationDoseScheduleEntry(
            doseAmount: _trimToNull(row.doseAmountController.text),
            doseUnit: _trimToNull(row.doseUnitController.text),
            time: row.time,
          ),
        )
        .toList(growable: false);
    final first = doseSchedule.isEmpty ? null : doseSchedule.first;
    final hasUniformDoses =
        doseSchedule.isNotEmpty && !hasVariableMedicationDoses(doseSchedule);

    widget.onChanged(
      MedicationScheduleDraft(
        doseAmount: hasUniformDoses ? first?.doseAmount : null,
        doseSchedule: List<MedicationDoseScheduleEntry>.unmodifiable(
          doseSchedule,
        ),
        doseUnit: hasUniformDoses ? first?.doseUnit : null,
        endDate: _endDate,
        medicationName: _medicationNameController.text.trim(),
        notes: _trimToNull(_notesController.text),
        route: _trimToNull(_routeController.text),
        startDate: _startDate,
        times: List<String>.unmodifiable(
          doseSchedule.map((entry) => entry.time),
        ),
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

class _DoseTimeRowEditor extends StatelessWidget {
  const _DoseTimeRowEditor({
    required this.onPickTime,
    required this.row,
    this.onDelete,
  });

  final VoidCallback onPickTime;
  final _DoseTimeDraftRow row;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onPickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(row.time),
                ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove time',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: row.doseAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Dose amount',
                      hintText: '1.2',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: row.doseUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Dose unit',
                      hintText: 'mg',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseTimeDraftRow {
  _DoseTimeDraftRow({
    required this.doseAmountController,
    required this.doseUnitController,
    required this.time,
  });

  final TextEditingController doseAmountController;
  final TextEditingController doseUnitController;
  String time;

  void dispose() {
    doseAmountController.dispose();
    doseUnitController.dispose();
  }
}
