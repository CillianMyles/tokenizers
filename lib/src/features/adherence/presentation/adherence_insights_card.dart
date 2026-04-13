import 'package:flutter/material.dart';
import 'package:tokenizers/src/features/adherence/domain/adherence_models.dart';

/// Card displaying a 7-day adherence summary on the Today screen.
class AdherenceInsightsCard extends StatelessWidget {
  /// Creates an adherence insights card.
  const AdherenceInsightsCard({required this.summary, super.key});

  /// The computed adherence summary.
  final AdherenceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

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
                    'Adherence insights',
                    style: textTheme.titleLarge,
                  ),
                ),
                Text(
                  'Last ${summary.lookbackDays} days',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OverallAdherenceMeter(summary: summary),
            const SizedBox(height: 18),
            if (summary.dailyBreakdown.isNotEmpty) ...<Widget>[
              Text('Week at a glance', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              _WeeklyHeatmap(days: summary.dailyBreakdown),
              const SizedBox(height: 18),
            ],
            Text('By medication', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            ...summary.byMedication.map(
              (stats) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MedicationAdherenceRow(stats: stats),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationAdherenceRow extends StatelessWidget {
  const _MedicationAdherenceRow({required this.stats});

  final MedicationAdherenceStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percentage = (stats.adherenceRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(stats.medicationName, style: textTheme.titleMedium),
            ),
            Text('$percentage%', style: textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: stats.adherenceRate,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${stats.takenDoses} of ${stats.scheduledDoses} doses',
          style: textTheme.bodySmall,
        ),
        if (stats.currentStreak > 0) ...<Widget>[
          const SizedBox(height: 6),
          _StreakBadge(days: stats.currentStreak),
        ],
      ],
    );
  }
}

class _OverallAdherenceMeter extends StatelessWidget {
  const _OverallAdherenceMeter({required this.summary});

  final AdherenceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percentage = (summary.overallRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: summary.overallRate,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$percentage% overall'
          ' • ${summary.totalTakenDoses} of '
          '${summary.totalScheduledDoses} doses',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$days-day streak',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyHeatmap extends StatelessWidget {
  const _WeeklyHeatmap({required this.days});

  final List<AdherenceDayStats> days;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final rawWidth =
            (constraints.maxWidth - (spacing * (days.length - 1))) /
            days.length;
        final cellWidth = rawWidth < 40
            ? 40.0
            : rawWidth > 88
            ? 88.0
            : rawWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (var index = 0; index < days.length; index++)
              SizedBox(
                width: cellWidth,
                child: _HeatmapCell(
                  day: days[index],
                  isLatest: index == days.length - 1,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day, required this.isLatest});

  final AdherenceDayStats day;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = _backgroundColor(colorScheme, day);
    final foregroundColor = _foregroundColor(colorScheme, day);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLatest
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _weekdayLabel(day.date),
              style: textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
            const SizedBox(height: 8),
            Text(
              day.isEmpty ? '—' : '${day.takenDoses}/${day.scheduledDoses}',
              style: textTheme.labelLarge?.copyWith(color: foregroundColor),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.date.day}',
              style: textTheme.bodySmall?.copyWith(
                color: foregroundColor.withValues(alpha: 0.84),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _backgroundColor(ColorScheme colorScheme, AdherenceDayStats day) {
  if (day.isEmpty) {
    return colorScheme.surfaceContainerHighest;
  }
  final intensity = switch (day.adherenceRate) {
    >= 1 => 0.95,
    >= 0.75 => 0.78,
    >= 0.5 => 0.62,
    > 0 => 0.42,
    _ => 0.22,
  };
  return Color.alphaBlend(
    colorScheme.primary.withValues(alpha: intensity),
    colorScheme.surfaceContainerLow,
  );
}

Color _foregroundColor(ColorScheme colorScheme, AdherenceDayStats day) {
  if (day.isEmpty) {
    return colorScheme.onSurfaceVariant;
  }
  return day.adherenceRate >= 0.5
      ? colorScheme.onPrimary
      : colorScheme.onSurface;
}

String _weekdayLabel(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}
