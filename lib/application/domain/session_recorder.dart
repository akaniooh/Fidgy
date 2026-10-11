import 'dart:math';

import '../data/session_record.dart';
import '../data/session_repository.dart';
import 'game_config.dart';
import 'game_data.dart';
import 'suggestions.dart';

/// Collects the taps of one game and saves the finished session.
class SessionRecorder {
  SessionRecorder(this.config) : _id = _newId();

  final GameConfig config;
  final String _id;
  final _taps = <TapEvent>[];
  final _clock = Stopwatch();
  DateTime? _startedAt;
  int _targetShownAtMs = 0;
  bool _finished = false;

  bool get isFinished => _finished;

  void start() {
    _startedAt = DateTime.now().toUtc();
    _clock.start();
  }

  /// Call whenever a new finger is highlighted.
  void targetShown() => _targetShownAtMs = _clock.elapsedMilliseconds;

  void recordTap({
    required Finger target,
    required Finger? tapped,
    required double dx,
    required double dy,
  }) {
    if (_finished) return;
    final now = _clock.elapsedMilliseconds;
    _taps.add(
      TapEvent(
        tMs: now,
        targetFinger: target.index,
        tappedFinger: tapped?.index,
        correct: tapped == target,
        reactionMs: now - _targetShownAtMs,
        dx: dx,
        dy: dy,
      ),
    );
  }

  /// Saves the session once. Later calls do nothing.
  void finish({
    required SessionOutcome outcome,
    required bool passed,
    required int score,
    required int stars,
    required int livesLost,
    int bestStreak = 0,
    int criticalHits = 0,
  }) {
    if (_finished) return;
    _finished = true;
    _clock.stop();

    // A session abandoned before any touch is not worth keeping.
    if (outcome == SessionOutcome.abandoned && _taps.isEmpty) return;

    final record = SessionRecord(
      id: _id,
      startedAt: _startedAt ?? DateTime.now().toUtc(),
      durationMs: _clock.elapsedMilliseconds,
      hand: config.hand.name,
      difficulty: config.difficulty.name,
      level: config.level,
      assist: config.assist.name,
      outcome: outcome,
      passed: passed,
      score: score,
      stars: stars,
      lives: config.maxFailureAllowed,
      livesLost: livesLost,
      taps: List.unmodifiable(_taps),
      bestStreak: bestStreak,
      criticalHits: criticalHits,
    );
    // Count towards today's goal (quitting early does not count).
    if (outcome != SessionOutcome.abandoned) GameData.i.recordSessionDay();

    // Fire and forget; the repository handles its own errors. Once saved,
    // look again at whether a suggestion is due.
    SessionRepository.instance
        .save(record)
        .then((_) => Suggestions.i.refresh());
  }

  static String _newId() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }
}
