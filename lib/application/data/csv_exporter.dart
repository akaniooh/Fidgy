import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/game_config.dart';
import '../domain/progress_stats.dart';
import 'session_record.dart';

/// Turns saved sessions into CSV files the patient can share.
///
/// Exported files are plain text, so they are kept in a temporary folder that
/// is cleared before every export, when the app starts, and when the patient
/// deletes their data.
class CsvExporter {
  static const _folder = 'fidgy_export';

  static Future<Directory> _dir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}${Platform.pathSeparator}$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Removes any export files left over from earlier exports.
  static Future<void> purge() async {
    if (kIsWeb) return;
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}${Platform.pathSeparator}$_folder');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Writes two CSV files (one row per session, one row per tap) and opens
  /// the share sheet. Returns false if anything went wrong.
  static Future<bool> shareAll(List<SessionRecord> sessions) async {
    if (kIsWeb || sessions.isEmpty) return false;
    try {
      await purge();
      final dir = await _dir();
      final stamp = _stamp(DateTime.now());
      final sep = Platform.pathSeparator;
      final sessionsFile = File('${dir.path}${sep}fidgy_sessions_$stamp.csv');
      final tapsFile = File('${dir.path}${sep}fidgy_taps_$stamp.csv');
      await sessionsFile.writeAsString(sessionsCsv(sessions));
      await tapsFile.writeAsString(tapsCsv(sessions));

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(sessionsFile.path, mimeType: 'text/csv'),
            XFile(tapsFile.path, mimeType: 'text/csv'),
          ],
          subject: 'Fidgy results',
          text: 'Fidgy session results (CSV).',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }

  static String sessionsCsv(List<SessionRecord> sessions) {
    final rows = <List<Object?>>[
      [
        'session_id',
        'started_at_utc',
        'duration_ms',
        'hand',
        'difficulty',
        'level',
        'assist',
        'outcome',
        'passed',
        'score',
        'stars',
        'lives',
        'lives_lost',
        'taps',
        'correct_taps',
        'accuracy',
        'mean_reaction_ms',
        'mean_offset_radii',
        'best_streak',
        'critical_hits',
      ],
    ];
    for (final r in _sorted(sessions)) {
      final st = SessionStats(r);
      rows.add([
        r.id,
        r.startedAt.toUtc().toIso8601String(),
        r.durationMs,
        r.hand,
        r.difficulty,
        r.level,
        r.assist,
        r.outcome.name,
        r.passed,
        r.score,
        r.stars,
        r.lives,
        r.livesLost,
        st.tapCount,
        st.correctCount,
        _num(st.accuracy),
        _num(st.meanReactionMs),
        _num(st.meanOffset),
        r.bestStreak,
        r.criticalHits,
      ]);
    }
    return _toCsv(rows);
  }

  static String tapsCsv(List<SessionRecord> sessions) {
    final rows = <List<Object?>>[
      [
        'session_id',
        'tap_index',
        't_ms',
        'target_finger',
        'tapped_finger',
        'correct',
        'reaction_ms',
        'dx_radii',
        'dy_radii',
      ],
    ];
    for (final r in _sorted(sessions)) {
      for (var i = 0; i < r.taps.length; i++) {
        final t = r.taps[i];
        rows.add([
          r.id,
          i + 1,
          t.tMs,
          _finger(t.targetFinger),
          t.tappedFinger == null ? 'open_space' : _finger(t.tappedFinger!),
          t.correct,
          t.reactionMs,
          _num(t.dx),
          _num(t.dy),
        ]);
      }
    }
    return _toCsv(rows);
  }

  static List<SessionRecord> _sorted(List<SessionRecord> sessions) =>
      [...sessions]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  static String _finger(int index) =>
      index >= 0 && index < Finger.values.length
          ? Finger.values[index].name
          : 'unknown';

  static String _num(double? v) => v == null ? '' : v.toStringAsFixed(3);

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}';
  }

  static String _cell(Object? value) {
    const q = '"';
    final s = value?.toString() ?? '';
    final needsQuotes = s.contains(',') ||
        s.contains(q) ||
        s.contains('\n') ||
        s.contains('\r');
    return needsQuotes ? '$q${s.replaceAll(q, '$q$q')}$q' : s;
  }

  static String _toCsv(List<List<Object?>> rows) =>
      '${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}
