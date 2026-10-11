import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'app_settings.dart';

/// Plays sounds and haptic feedback, respecting [AppSettings].
/// Failures are swallowed so feedback can never break the game.
class FeedbackService {
  FeedbackService._();
  static final i = FeedbackService._();

  final _players = <String, AudioPlayer>{};

  void correct() {
    _haptic(HapticFeedback.lightImpact);
    _play('correct');
  }

  void wrong() {
    _haptic(HapticFeedback.heavyImpact);
    _play('wrong');
  }

  void levelComplete() {
    _haptic(HapticFeedback.mediumImpact);
    _play('complete');
  }

  void criticalHit() {
    _haptic(HapticFeedback.heavyImpact);
    Future.delayed(const Duration(milliseconds: 130), () {
      _haptic(HapticFeedback.heavyImpact);
    });
    _play('critical');
  }

  void gameOver() {
    _haptic(HapticFeedback.heavyImpact);
    _play('gameover');
  }

  void _haptic(Future<void> Function() impact) {
    if (!AppSettings.i.hapticsEnabled) return;
    try {
      impact();
    } catch (_) {}
  }

  Future<void> _play(String name) async {
    if (!AppSettings.i.soundEnabled) return;
    try {
      final player = _players.putIfAbsent(name, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'));
    } catch (_) {}
  }
}
