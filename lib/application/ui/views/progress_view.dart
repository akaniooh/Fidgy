import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../data/csv_exporter.dart';
import '../../data/session_record.dart';
import '../../data/session_repository.dart';
import '../../domain/assist_level.dart';
import '../../domain/game_config.dart';
import '../../domain/game_data.dart';
import '../../domain/progress_stats.dart';
import '../components/button_widget.dart';
import '../dialogs/delete_data_dialog.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  late Future<List<SessionRecord>> _future =
      SessionRepository.instance.loadAll();

  /// null = all assist levels.
  AssistLevel? _filter;

  void _reload() {
    setState(() => _future = SessionRepository.instance.loadAll());
  }

  Future<void> _export(List<SessionRecord> sessions) async {
    final ok = await CsvExporter.shareAll(sessions);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare the export.')),
      );
    }
  }

  void _confirmDelete() {
    DeleteDataDialog(
      onConfirmed: () async {
        await SessionRepository.instance.deleteAll();
        await GameData.i.clearAll();
        await CsvExporter.purge();
        if (mounted) _reload();
      },
    ).open();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 120.h,
        title: Text(
          'My progress',
          style: TextStyle(fontSize: 50.t, fontWeight: FontWeight.w600),
        ),
        backgroundColor: c.surface,
        foregroundColor: c.textStrong,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: FutureBuilder<List<SessionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const <SessionRecord>[];
          if (all.isEmpty) return const _EmptyState();

          final shown = _filter == null
              ? all
              : all.where((s) => s.assist == _filter!.name).toList();
          final summary = ProgressSummary(shown);

          return ListView(
            padding: EdgeInsets.fromLTRB(80.r, 40.r, 80.r, 80.r),
            children: [
              _FilterBar(
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              SizedBox(height: 32.r),
              if (summary.isEmpty)
                const _NoMatches()
              else ...[
                _SummaryRow(summary: summary),
                SizedBox(height: 32.r),
                _ChartsRow(summary: summary),
                SizedBox(height: 32.r),
                _FingerCard(summary: summary),
                SizedBox(height: 32.r),
                _RecentCard(summary: summary),
              ],
              SizedBox(height: 32.r),
              _YourDataCard(
                onExport: () => _export(all),
                onDelete: _confirmDelete,
              ),
              SizedBox(height: 40.r),
              Center(
                child: Text(
                  'Your results are stored encrypted on this phone.',
                  style: TextStyle(fontSize: 28.t, color: c.textMute),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- states

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, size: 140.r, color: c.textMute),
          SizedBox(height: 24.r),
          Text(
            'No sessions yet',
            style: TextStyle(fontSize: 50.t, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.r),
          Text(
            'Play a game and your results will appear here.\n'
            'They stay on this phone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34.t, color: c.textMedium),
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 120.r),
      child: Center(
        child: Text(
          'No sessions at this assist level yet.',
          style: TextStyle(
            fontSize: 38.t,
            color: AppColors.of(context).textMedium,
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- filters

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final AssistLevel? selected;
  final ValueChanged<AssistLevel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20.r,
      runSpacing: 12.r,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Assist level',
          style: TextStyle(
            fontSize: 32.t,
            color: AppColors.of(context).textMedium,
          ),
        ),
        _Chip(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final level in AssistLevel.values)
          _Chip(
            label: level.label,
            selected: selected == level,
            onTap: () => onSelected(level),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(40.r);
    return Material(
      color: selected ? c.accent : c.surfaceAlt,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.r, vertical: 14.r),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 32.t,
              fontWeight: FontWeight.w500,
              color: selected ? c.onAccent : c.textMedium,
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- summary

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: padding ?? EdgeInsets.all(36.r),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: c.outline),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final accuracy = summary.accuracy;
    final reaction = summary.meanReactionMs;
    final offset = summary.meanOffset;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tile(
          label: 'Sessions played',
          value: '${summary.sessionCount}',
          note: 'with taps recorded',
        ),
        SizedBox(width: 24.r),
        _Tile(
          label: 'Accuracy',
          value: accuracy == null ? '-' : '${(accuracy * 100).round()}%',
          note: 'taps on the lit finger',
        ),
        SizedBox(width: 24.r),
        _Tile(
          label: 'Reaction time',
          value: reaction == null ? '-' : '${reaction.round()} ms',
          note: 'correct taps',
        ),
        SizedBox(width: 24.r),
        _Tile(
          label: 'Aim offset',
          value: offset == null ? '-' : '${(offset * 100).round()}%',
          note: 'of circle radius',
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: _Card(
        padding: EdgeInsets.all(30.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 30.t, color: c.textMedium),
            ),
            SizedBox(height: 8.r),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 64.t,
                  fontWeight: FontWeight.w700,
                  color: c.textStrong,
                ),
              ),
            ),
            if (note != null)
              Text(note!, style: TextStyle(fontSize: 24.t, color: c.textMute)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- charts

class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final recent = summary.sessions.length > 20
        ? summary.sessions.sublist(summary.sessions.length - 20)
        : summary.sessions;

    final accuracy = [
      for (final s in recent)
        if (s.accuracy != null) s.accuracy! * 100,
    ];
    final reaction = [
      for (final s in recent)
        if (s.meanReactionMs != null) s.meanReactionMs!,
    ];
    final reactionMax = reaction.isEmpty
        ? 1000.0
        : ((reaction.reduce((a, b) => a > b ? a : b) * 1.15) / 100).ceil() *
            100.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ChartCard(
            title: 'Accuracy per session',
            unit: '%',
            values: accuracy,
            minY: 0,
            maxY: 100,
            color: c.mainGreen,
          ),
        ),
        SizedBox(width: 24.r),
        Expanded(
          child: _ChartCard(
            title: 'Reaction time per session',
            unit: ' ms',
            values: reaction,
            minY: 0,
            maxY: reactionMax,
            color: c.accent,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.unit,
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  final String title;
  final String unit;
  final List<double> values;
  final double minY;
  final double maxY;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 34.t, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20.r),
          SizedBox(
            height: 300.r,
            width: double.infinity,
            child: values.isEmpty
                ? Center(
                    child: Text(
                      'Not enough data yet',
                      style: TextStyle(fontSize: 30.t, color: c.textMute),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendPainter(
                      values: values,
                      minY: minY,
                      maxY: maxY,
                      unit: unit,
                      lineColor: color,
                      gridColor: c.outline,
                      labelColor: c.textMute,
                    ),
                  ),
          ),
          SizedBox(height: 8.r),
          Text(
            'Last ${values.length} session${values.length == 1 ? '' : 's'}, oldest to newest',
            style: TextStyle(fontSize: 24.t, color: c.textMute),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.unit,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<double> values;
  final double minY;
  final double maxY;
  final String unit;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = (size.height * 0.075).clamp(9.0, 16.0);
    final left = (size.width * 0.14).clamp(34.0, 72.0);
    const top = 10.0;
    const right = 10.0;
    final bottom = fontSize + 8;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    if (chartW <= 0 || chartH <= 0) return;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartH * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
    }

    void label(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: labelColor,
            fontSize: fontSize,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - 8, y - tp.height / 2));
    }

    label('${maxY.round()}$unit', top);
    label('${minY.round()}$unit', top + chartH);

    final range = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    Offset point(int i) {
      final x = values.length == 1
          ? left + chartW / 2
          : left + chartW * i / (values.length - 1);
      final norm = ((values[i] - minY) / range).clamp(0.0, 1.0);
      return Offset(x, top + chartH * (1 - norm));
    }

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    if (values.length > 1) {
      final fill = Path.from(line)
        ..lineTo(point(values.length - 1).dx, top + chartH)
        ..lineTo(point(0).dx, top + chartH)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.25),
              lineColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(left, top, chartW, chartH)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final dot = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(point(i), 4.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor ||
      old.maxY != maxY;
}

// ---------------------------------------------------------------- fingers

class _FingerCard extends StatelessWidget {
  const _FingerCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final stats = summary.perFinger(Finger.values.length);

    // Weakest finger: lowest accuracy among fingers with enough attempts.
    int? weakest;
    double lowest = 2;
    for (final s in stats) {
      final a = s.accuracy;
      if (s.attempts >= 5 && a != null && a < lowest) {
        lowest = a;
        weakest = s.index;
      }
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By finger',
            style: TextStyle(fontSize: 34.t, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.r),
          Text(
            'How often each finger was hit when it lit up',
            style: TextStyle(fontSize: 26.t, color: c.textMute),
          ),
          SizedBox(height: 24.r),
          for (final s in stats) ...[
            _FingerRow(
              name: Finger.values[s.index].name,
              stats: s,
              highlight: s.index == weakest,
            ),
            SizedBox(height: 18.r),
          ],
        ],
      ),
    );
  }
}

class _FingerRow extends StatelessWidget {
  const _FingerRow({
    required this.name,
    required this.stats,
    required this.highlight,
  });

  final String name;
  final FingerStats stats;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accuracy = stats.accuracy;
    final reaction = stats.meanReactionMs;
    return Row(
      children: [
        SizedBox(
          width: 190.r,
          child: Text(
            name,
            style: TextStyle(fontSize: 32.t, color: c.textStrong),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 26.r,
              color: c.neutralFill,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (accuracy ?? 0).clamp(0.0, 1.0),
                child: Container(
                  color: highlight ? c.mainOrange : c.accent,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 130.r,
          child: Text(
            accuracy == null ? '-' : '${(accuracy * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 32.t, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 190.r,
          child: Text(
            reaction == null ? '-' : '${reaction.round()} ms',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 30.t, color: c.textMedium),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- recent

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.summary});

  final ProgressSummary summary;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _date(DateTime t) {
    final d = t.toLocal();
    return '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  static String _outcome(SessionRecord s) {
    switch (s.outcome) {
      case SessionOutcome.completed:
        return 'Completed';
      case SessionOutcome.timeUp:
        return s.passed ? 'Time up, passed' : 'Time up';
      case SessionOutcome.outOfLives:
        return s.passed ? 'Out of lives, passed' : 'Out of lives';
      case SessionOutcome.abandoned:
        return 'Stopped early';
    }
  }

  static String _assist(String name) {
    for (final level in AssistLevel.values) {
      if (level.name == name) return level.label;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final recent = summary.sessions.reversed.take(8).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent sessions',
            style: TextStyle(fontSize: 34.t, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16.r),
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) Divider(color: c.outline, height: 28.r),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _date(recent[i].session.startedAt),
                    style: TextStyle(fontSize: 28.t, color: c.textMedium),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Level ${recent[i].session.level}, ${recent[i].session.difficulty}, '
                    '${recent[i].session.hand} hand',
                    style: TextStyle(fontSize: 28.t),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _assist(recent[i].session.assist),
                    style: TextStyle(fontSize: 28.t, color: c.textMedium),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _outcome(recent[i].session),
                    style: TextStyle(fontSize: 28.t, color: c.textMedium),
                  ),
                ),
                SizedBox(
                  width: 110.r,
                  child: Text(
                    recent[i].accuracy == null
                        ? '-'
                        : '${(recent[i].accuracy! * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 30.t, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- your data

class _YourDataCard extends StatelessWidget {
  const _YourDataCard({required this.onExport, required this.onDelete});

  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your data',
            style: TextStyle(fontSize: 34.t, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.r),
          Text(
            'Export your results to share with your clinician, or delete '
            'everything from this phone for good.',
            style: TextStyle(fontSize: 26.t, color: c.textMute),
          ),
          SizedBox(height: 24.r),
          Row(
            children: [
              Expanded(
                child: ButtonWidget(
                  onTap: onExport,
                  label: 'Export results (CSV)',
                ),
              ),
              SizedBox(width: 24.r),
              Expanded(
                child: ButtonWidget(
                  onTap: onDelete,
                  label: 'Delete all my data',
                  color: c.mainRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
