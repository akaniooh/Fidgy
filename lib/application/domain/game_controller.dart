import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/presentation/presentation.dart';
import '../data/session_record.dart';
import '../ui/dialogs/game_over_dialog.dart';
import '../ui/dialogs/level_completed_dialog.dart';
import 'feedback_service.dart';
import 'game_clock.dart';
import 'game_config.dart';
import 'game_data.dart';
import 'general_manager.dart';
import 'session_recorder.dart';

class GameController extends AppViewModel {
  final GameConfig config;
  final GameClock clock;
  final Random _random;

  /// One key per finger circle, used to locate it on screen for tap detection.
  final fingerKeys = {for (final f in Finger.values) f: GlobalKey()};
  DateTime? _lastTapAt;
  late final SessionRecorder _recorder = SessionRecorder(config);
  final _pointersDown = <int>{};

  // Critical hits: a run of consecutive hits with no miss.
  int _streak = 0;
  int _bestStreak = 0;
  int _criticalHits = 0;
  int _criticalPulse = 0;
  bool _criticalFlash = false;
  Timer? _flashTimer;

  int get streak => _streak;
  int get criticalHits => _criticalHits;

  /// True while the critical-hit animation should be on screen.
  bool get criticalFlash => _criticalFlash;

  /// Changes every time a critical hit lands, so the animation restarts.
  int get criticalPulse => _criticalPulse;

  GameController(this.config)
      : clock = GameClock(
          config.gameTime,
          config.gameWarningTime,
        ),
        _random = Random(config.randomnessSeed),
        _currentTurn = 0,
        _remainingLives = config.maxFailureAllowed;

  int _currentTurn;
  Finger? _currentFinger;
  int _remainingLives;

  // Live Meter data
  int get remainingLives => _remainingLives;
  int get numberOfLives => config.maxFailureAllowed;

  // Progress Meter data
  int get currentRawScore => _currentTurn;
  int get displayScore => currentRawScore * 2;
  int get maxScore => config.maximumScore;
  int get firstStarScore => config.passMark;
  int get secondStarScore => firstStarScore + (maxScore - firstStarScore) ~/ 2;
  Finger? get fingerToTap => _currentFinger;

  void startPlaying() {
    _recorder.start();
    _currentTurn = -1;
    _correctFingerTouched();
    clock.addListener(_timerListener);
    clock.start();
  }

  void _timerListener() async {
    if (clock.remainingTime == Duration.zero) {
      clock.removeListener(_timerListener);
      clock.stop();
      _endSession(SessionOutcome.timeUp);

      if (currentRawScore >= config.passMark) {
        GeneralManager.i.gameWon(displayScore);
        FeedbackService.i.levelComplete();
        LevelCompletedDialog.timeUp(levelVm: this).open();
      } else {
        FeedbackService.i.gameOver();
        GameOverDialog.timeUp().open();
      }
    }
  }

  void touchFinger(Finger finger) {
    if (finger == _currentFinger) {
      _correctFingerTouched();
    } else {
      _wrongSpaceTouched();
    }
  }

  void touchOpenSpace() => _wrongSpaceTouched();

  /// A touch landed on the play area. Only the first finger of a touch counts,
  /// so a resting palm or second finger is not scored as a wrong tap.
  void pointerDown(int pointer, Offset globalPosition) {
    final alreadyTouching = _pointersDown.isNotEmpty;
    _pointersDown.add(pointer);
    if (alreadyTouching) return;
    handleTap(globalPosition);
  }

  void pointerUp(int pointer) => _pointersDown.remove(pointer);

  void _registerHit() {
    _streak++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    if (_streak < config.criticalStreak) return;

    // Critical hit: celebrate, count it, and start a fresh run.
    _streak = 0;
    _criticalHits++;
    _criticalPulse++;
    _criticalFlash = true;
    GameData.i.addCriticalHit();
    FeedbackService.i.criticalHit();
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1700), () {
      _criticalFlash = false;
      setState();
    });
  }

  void _endSession(SessionOutcome outcome) {
    _flashTimer?.cancel();
    _criticalFlash = false;
    _recorder.finish(
      outcome: outcome,
      passed: currentRawScore >= config.passMark,
      score: displayScore,
      stars: numberOfStars,
      livesLost: config.maxFailureAllowed - _remainingLives,
      bestStreak: _bestStreak,
      criticalHits: _criticalHits,
    );
  }

  /// Resolves one touch to a finger (or open space), records it and scores it.
  /// The nearest finger within the assist tap radius wins; anything else
  /// counts as a tap on open space.
  void handleTap(Offset globalPosition) {
    if (_recorder.isFinished) return;

    final now = DateTime.now();
    final last = _lastTapAt;
    if (last != null && now.difference(last) < config.assist.tapCooldown) {
      return;
    }
    _lastTapAt = now;

    final spots = _fingerSpots();
    final finger = _fingerAt(spots, globalPosition);
    _recordTap(spots, globalPosition, finger);

    if (finger != null && finger == _currentFinger) {
      _registerHit();
    } else {
      _streak = 0;
    }

    if (finger == null) {
      touchOpenSpace();
    } else {
      touchFinger(finger);
    }
  }

  /// Current on-screen centre and standard radius of every finger circle.
  Map<Finger, _FingerSpot> _fingerSpots() {
    final spots = <Finger, _FingerSpot>{};
    for (final entry in fingerKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      spots[entry.key] = _FingerSpot(
        center: box.localToGlobal(box.size.center(Offset.zero)),
        // The circle is drawn at visualScale; this is the unscaled radius.
        standardRadius: box.size.width / 2 / config.assist.visualScale,
      );
    }
    return spots;
  }

  Finger? _fingerAt(Map<Finger, _FingerSpot> spots, Offset position) {
    Finger? nearest;
    var nearestDistance = double.infinity;
    for (final entry in spots.entries) {
      final radius = entry.value.standardRadius * config.assist.hitScale;
      final distance = (entry.value.center - position).distance;
      if (distance <= radius && distance < nearestDistance) {
        nearest = entry.key;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  void _recordTap(
    Map<Finger, _FingerSpot> spots,
    Offset position,
    Finger? tapped,
  ) {
    final target = _currentFinger;
    final spot = target == null ? null : spots[target];
    if (target == null || spot == null) return;
    _recorder.recordTap(
      target: target,
      tapped: tapped,
      dx: (position.dx - spot.center.dx) / spot.standardRadius,
      dy: (position.dy - spot.center.dy) / spot.standardRadius,
    );
  }

  void _correctFingerTouched() {
    // Last turn - End game with win
    if (_currentTurn == config.maximumScore) {
      GeneralManager.i.gameWon(displayScore);
      clock.removeListener(_timerListener);
      clock.stop();
      _endSession(SessionOutcome.completed);
      FeedbackService.i.levelComplete();
      LevelCompletedDialog(levelVm: this).open();
    }
    // Continue game - next turn
    else {
      _currentTurn++;
      if (_currentTurn > 0) FeedbackService.i.correct();
      _currentFinger = Finger.values[_random.nextInt(5)];
      _recorder.targetShown();
      setState();
    }
  }

  void _wrongSpaceTouched() {
    _remainingLives--;
    if (_remainingLives > 0) FeedbackService.i.wrong();
    setState();

    if (_remainingLives == 0) {
      clock.removeListener(_timerListener);
      clock.stop();
      _endSession(SessionOutcome.outOfLives);
      if (currentRawScore >= config.passMark) {
        GeneralManager.i.gameWon(displayScore);
        FeedbackService.i.levelComplete();
        LevelCompletedDialog(levelVm: this).open();
      } else {
        FeedbackService.i.gameOver();
        GameOverDialog.outOfLives().open();
      }
    }
  }

  int get numberOfStars => config.computeScoreStars(displayScore);

  void finish() {
    clock.removeListener(_timerListener);
    clock.stop();
    _endSession(SessionOutcome.abandoned);
    GeneralManager.i.goHome();
  }
}

class _FingerSpot {
  const _FingerSpot({required this.center, required this.standardRadius});
  final Offset center;
  final double standardRadius;
}
