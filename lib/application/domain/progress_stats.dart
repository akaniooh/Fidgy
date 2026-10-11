import 'dart:math';

import '../data/session_record.dart';

/// Metrics for one session.
class SessionStats {
  SessionStats(this.session);

  final SessionRecord session;

  int get tapCount => session.taps.length;
  int get correctCount => session.taps.where((t) => t.correct).length;

  /// Share of taps that hit the highlighted finger (0..1).
  double? get accuracy => tapCount == 0 ? null : correctCount / tapCount;

  /// Average time from the finger lighting up to a correct tap.
  double? get meanReactionMs {
    final times = session.taps.where((t) => t.correct).map((t) => t.reactionMs);
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Average distance of touches from the target's centre, in radii of the
  /// standard circle.
  double? get meanOffset {
    if (session.taps.isEmpty) return null;
    final sum = session.taps
        .map((t) => sqrt(t.dx * t.dx + t.dy * t.dy))
        .reduce((a, b) => a + b);
    return sum / session.taps.length;
  }
}

/// Metrics for one finger (as the target).
class FingerStats {
  const FingerStats({
    required this.index,
    required this.attempts,
    required this.hits,
    required this.meanReactionMs,
  });

  final int index;
  final int attempts;
  final int hits;
  final double? meanReactionMs;

  double? get accuracy => attempts == 0 ? null : hits / attempts;
}

/// Everything the progress screen shows, for a set of sessions.
class ProgressSummary {
  ProgressSummary(List<SessionRecord> records)
      : sessions = (records.toList()
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt)))
            .map(SessionStats.new)
            .toList();

  /// Oldest first.
  final List<SessionStats> sessions;

  bool get isEmpty => sessions.isEmpty;
  int get sessionCount => sessions.length;

  Iterable<TapEvent> get _taps => sessions.expand((s) => s.session.taps);

  double? get accuracy {
    final taps = _taps.toList();
    if (taps.isEmpty) return null;
    return taps.where((t) => t.correct).length / taps.length;
  }

  double? get meanReactionMs {
    final times = _taps.where((t) => t.correct).map((t) => t.reactionMs).toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length;
  }

  double? get meanOffset {
    final taps = _taps.toList();
    if (taps.isEmpty) return null;
    final sum = taps
        .map((t) => sqrt(t.dx * t.dx + t.dy * t.dy))
        .reduce((a, b) => a + b);
    return sum / taps.length;
  }

  List<FingerStats> perFinger(int fingerCount) {
    return List.generate(fingerCount, (i) {
      final targeted = _taps.where((t) => t.targetFinger == i).toList();
      final hits = targeted.where((t) => t.correct).toList();
      return FingerStats(
        index: i,
        attempts: targeted.length,
        hits: hits.length,
        meanReactionMs: hits.isEmpty
            ? null
            : hits.map((t) => t.reactionMs).reduce((a, b) => a + b) /
                hits.length,
      );
    });
  }
}
