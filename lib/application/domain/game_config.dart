import 'assist_level.dart';

class GameConfig {
  final int level;
  final Difficulty difficulty;
  final AssistLevel assist;
  final int maxFailureAllowed;
  final int randomnessSeed;
  final Hand hand;
  final int passMark;
  final int maximumScore;
  Duration get gameTime => difficulty.gameTime * assist.timeMultiplier;
  Duration get gameWarningTime =>
      difficulty.gameWarningTime * assist.timeMultiplier;
  /// Consecutive hits (no misses) needed for a critical hit: 8 on level 1,
  /// rising to 20 on level 15. Independent of assist level so results stay
  /// comparable.
  int get criticalStreak => 8 + (level - 1) * 6 ~/ 7;
  int get secondStarScore => passMark + (maximumScore - passMark) ~/ 2;

  GameConfig({
    required this.level,
    required this.hand,
    required this.difficulty,
    this.assist = AssistLevel.standard,
  })  : passMark = 15 + (level - 1) * 2,
        maximumScore = 25 + (level - 1) * 3,
        maxFailureAllowed = assist.lives,
        randomnessSeed = difficulty.randomnessSeed,
        assert(level >= 1 && level <= 15);

  int computeScoreStars(int score) {
    final currentRawScore = score ~/ 2;
    if (currentRawScore == maximumScore) return 3;
    if (currentRawScore >= secondStarScore) return 2;
    if (currentRawScore >= passMark) return 1;
    return 0;
  }
}

enum Hand {
  left('Left Hand'),
  right('Right Hand');

  final String description;
  const Hand(this.description);
}

enum Difficulty {
  easy(10, Duration(minutes: 6), Duration(minutes: 1, seconds: 30)),
  normal(100, Duration(minutes: 4), Duration(minutes: 1)),
  hard(200, Duration(minutes: 2), Duration(seconds: 15));

  final int randomnessSeed;
  final Duration gameTime;
  final Duration gameWarningTime;
  const Difficulty(this.randomnessSeed, this.gameTime, this.gameWarningTime);
}

enum Finger {
  thumb,
  pointing,
  middle,
  ring,
  pinky;
}
