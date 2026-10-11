import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../common/presentation/presentation.dart';
import '../data/session_record.dart';
import '../data/session_repository.dart';
import 'app_settings.dart';
import 'assist_level.dart';
import 'progress_stats.dart';

/// A gentle, dismissible nudge shown on the home screen.
class Suggestion {
  const Suggestion({required this.message, this.opensSettings = false});

  final String message;

  /// Whether the nudge is about a setting (shows a Settings button).
  final bool opensSettings;
}

/// Looks at the last few finished sessions and offers a nudge. It never
/// changes anything by itself: the patient (or clinician) decides.
class Suggestions extends AppViewModel {
  Suggestions._();
  static final i = Suggestions._();

  static const _dismissedKey = 'SUGGESTION_DISMISSED_AT';

  /// After dismissing, wait for this many more sessions before nudging again.
  static const _quietSessions = 3;

  Suggestion? _current;
  int _sessionCount = 0;
  int _dismissedAt = -1000;

  Suggestion? get current =>
      _sessionCount >= _dismissedAt + _quietSessions ? _current : null;

  Future<void> refresh() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _dismissedAt = sp.getInt(_dismissedKey) ?? -1000;

      final all = await SessionRepository.instance.loadAll();
      final done = all
          .where((s) => s.outcome != SessionOutcome.abandoned)
          .toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      _sessionCount = done.length;
      _current = _compute(done);
    } catch (_) {
      _current = null;
    }
    setState();
  }

  Future<void> dismiss() async {
    _dismissedAt = _sessionCount;
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_dismissedKey, _dismissedAt);
    } catch (_) {}
  }

  /// Forgets everything (used when the patient deletes their data).
  Future<void> clear() async {
    _current = null;
    _sessionCount = 0;
    _dismissedAt = -1000;
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_dismissedKey);
    } catch (_) {}
  }

  Suggestion? _compute(List<SessionRecord> done) {
    if (done.length < 3) return null;
    final recent = done.sublist(done.length - 3);
    final accuracy = [
      for (final s in recent) SessionStats(s).accuracy ?? 0.0,
    ];
    final average = accuracy.reduce((a, b) => a + b) / accuracy.length;
    final assist = AppSettings.i.assistLevel;

    final allPassed = recent.every((s) => s.passed);
    if (allPassed && accuracy.every((a) => a >= 0.90)) {
      if (assist != AssistLevel.standard) {
        return const Suggestion(
          message: 'Your last 3 games went really well. Ready for a bigger '
              'challenge? You could try a lower assist setting.',
          opensSettings: true,
        );
      }
      final top = recent.map((s) => s.level).reduce(max);
      if (top < 15) {
        return Suggestion(
          message: 'Your last 3 games went really well. '
              'Ready for level ${top + 1}?',
        );
      }
      return null;
    }

    final struggled = recent.where((s) => !s.passed).length;
    if (average <= 0.55 || struggled >= 2) {
      if (assist != AssistLevel.extraRelaxed) {
        return const Suggestion(
          message: 'These last few games looked tough. A more relaxed assist '
              'setting can make things easier. Small steps count.',
          opensSettings: true,
        );
      }
      return const Suggestion(
        message: 'These last few games looked tough. Short sessions are fine, '
            'and rest helps. Small steps count.',
      );
    }
    return null;
  }
}
