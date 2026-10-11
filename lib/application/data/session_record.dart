/// How a session ended.
enum SessionOutcome { completed, timeUp, outOfLives, abandoned }

double _round3(double v) => double.parse(v.toStringAsFixed(3));

/// One touch during a session.
class TapEvent {
  const TapEvent({
    required this.tMs,
    required this.targetFinger,
    required this.tappedFinger,
    required this.correct,
    required this.reactionMs,
    required this.dx,
    required this.dy,
  });

  /// Milliseconds since the session started.
  final int tMs;

  /// Index of the finger that was highlighted.
  final int targetFinger;

  /// Index of the finger that was hit, or null for a tap on open space.
  final int? tappedFinger;

  final bool correct;

  /// Milliseconds between the target appearing and this touch.
  final int reactionMs;

  /// Touch position relative to the target's centre, measured in radii of the
  /// standard finger circle (0 = dead centre, 1 = edge of the standard circle).
  final double dx;
  final double dy;

  Map<String, dynamic> toJson() => {
        't': tMs,
        'target': targetFinger,
        'tapped': tappedFinger,
        'ok': correct,
        'rt': reactionMs,
        'dx': _round3(dx),
        'dy': _round3(dy),
      };

  factory TapEvent.fromJson(Map<String, dynamic> json) => TapEvent(
        tMs: json['t'] as int,
        targetFinger: json['target'] as int,
        tappedFinger: json['tapped'] as int?,
        correct: json['ok'] as bool,
        reactionMs: json['rt'] as int,
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
      );
}

/// One played game. Enum values are stored by name so they survive reordering.
class SessionRecord {
  static const currentSchemaVersion = 1;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.durationMs,
    required this.hand,
    required this.difficulty,
    required this.level,
    required this.assist,
    required this.outcome,
    required this.passed,
    required this.score,
    required this.stars,
    required this.lives,
    required this.livesLost,
    required this.taps,
    this.bestStreak = 0,
    this.criticalHits = 0,
    this.schemaVersion = currentSchemaVersion,
  });

  final String id;
  final int schemaVersion;
  final DateTime startedAt;
  final int durationMs;
  final String hand;
  final String difficulty;
  final int level;
  final String assist;
  final SessionOutcome outcome;
  final bool passed;
  final int score;
  final int stars;
  final int lives;
  final int livesLost;
  final List<TapEvent> taps;

  /// Longest run of consecutive hits in this session.
  final int bestStreak;

  /// Critical hits earned in this session.
  final int criticalHits;

  Map<String, dynamic> toJson() => {
        'id': id,
        'v': schemaVersion,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationMs': durationMs,
        'hand': hand,
        'difficulty': difficulty,
        'level': level,
        'assist': assist,
        'outcome': outcome.name,
        'passed': passed,
        'score': score,
        'stars': stars,
        'lives': lives,
        'livesLost': livesLost,
        'taps': taps.map((t) => t.toJson()).toList(),
        'best': bestStreak,
        'crit': criticalHits,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        schemaVersion: json['v'] as int? ?? 1,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationMs: json['durationMs'] as int,
        hand: json['hand'] as String,
        difficulty: json['difficulty'] as String,
        level: json['level'] as int,
        assist: json['assist'] as String,
        outcome: SessionOutcome.values.firstWhere(
          (o) => o.name == json['outcome'],
          orElse: () => SessionOutcome.abandoned,
        ),
        passed: json['passed'] as bool,
        score: json['score'] as int,
        stars: json['stars'] as int,
        lives: json['lives'] as int,
        livesLost: json['livesLost'] as int,
        bestStreak: json['best'] as int? ?? 0,
        criticalHits: json['crit'] as int? ?? 0,
        taps: (json['taps'] as List)
            .map((t) => TapEvent.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
      );
}
