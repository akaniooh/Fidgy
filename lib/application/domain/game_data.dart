import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../common/presentation/presentation.dart';
import 'game_config.dart';
import 'suggestions.dart';

class GameData extends AppViewModel {
  GameData._();
  static final i = GameData._();
  static const dataKey = 'DATA_KEY';
  static const gameCountKey = 'GAME_COUNT';
  static const criticalKey = 'CRITICAL_HITS';
  static const countDayKey = 'DAILY_COUNT_DAY';
  static const dailyCountKey = 'DAILY_COUNT';
  static const lastDayKey = 'DAILY_LAST_DAY';
  static const dayStreakKey = 'DAILY_STREAK';

  int _gameCount = 0;
  int _criticalHits = 0;

  // Daily goal and day streak. Days are local calendar days (yyyy-mm-dd).
  String _countDay = '';
  int _dailyCount = 0;
  String _lastActiveDay = '';
  int _dayStreak = 0;
  var _data = <Hand, Map<Difficulty, Map<int, int>>>{
    Hand.left: {
      Difficulty.easy: {},
      Difficulty.normal: {},
      Difficulty.hard: {},
    },
    Hand.right: {
      Difficulty.easy: {},
      Difficulty.normal: {},
      Difficulty.hard: {},
    }
  };

  int get gameCount => _gameCount;
  int get criticalHits => _criticalHits;

  static String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  String get _today => _dayKey(DateTime.now());

  String get _yesterday {
    final n = DateTime.now();
    return _dayKey(DateTime(n.year, n.month, n.day - 1));
  }

  /// Finished sessions played today.
  int get dailyCount => _countDay == _today ? _dailyCount : 0;

  /// Days in a row with at least one finished session. Stays alive until the
  /// end of the day after the last session.
  int get dayStreak =>
      (_lastActiveDay == _today || _lastActiveDay == _yesterday)
          ? _dayStreak
          : 0;

  /// Call once for every finished (not abandoned) session.
  Future<void> recordSessionDay() async {
    final today = _today;
    if (_countDay != today) {
      _countDay = today;
      _dailyCount = 0;
    }
    _dailyCount++;
    if (_lastActiveDay != today) {
      _dayStreak = _lastActiveDay == _yesterday ? _dayStreak + 1 : 1;
      _lastActiveDay = today;
    }
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(countDayKey, _countDay);
      await sp.setInt(dailyCountKey, _dailyCount);
      await sp.setString(lastDayKey, _lastActiveDay);
      await sp.setInt(dayStreakKey, _dayStreak);
    } catch (_) {}
  }

  void initialise() async {
    final sp = await SharedPreferences.getInstance();
    final gameCount = sp.getInt(gameCountKey);
    _gameCount = gameCount ?? 0;
    _criticalHits = sp.getInt(criticalKey) ?? 0;
    _countDay = sp.getString(countDayKey) ?? '';
    _dailyCount = sp.getInt(dailyCountKey) ?? 0;
    _lastActiveDay = sp.getString(lastDayKey) ?? '';
    _dayStreak = sp.getInt(dayStreakKey) ?? 0;
    setState();
    final rawString = sp.getString(dataKey);
    if (rawString == null) return;
    final decodedData = jsonDecode(rawString);

    final parsedData = (decodedData as Map).map(
      (handi, rec) => MapEntry(
        Hand.values[int.parse(handi)],
        (rec as Map).map(
          (difficultyi, details) => MapEntry(
            Difficulty.values[int.parse(difficultyi)],
            (details as Map).map(
              (key, value) => MapEntry(
                int.parse(key),
                value as int,
              ),
            ),
          ),
        ),
      ),
    );

    _data = parsedData;
  }

  Future<void> addCriticalHit() async {
    _criticalHits++;
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(criticalKey, _criticalHits);
    } catch (_) {}
  }

  /// Wipes scores, unlocked levels, game count and critical hits.
  Future<void> clearAll() async {
    _gameCount = 0;
    _criticalHits = 0;
    _countDay = '';
    _dailyCount = 0;
    _lastActiveDay = '';
    _dayStreak = 0;
    Suggestions.i.clear();
    _data = <Hand, Map<Difficulty, Map<int, int>>>{
      Hand.left: {
        Difficulty.easy: {},
        Difficulty.normal: {},
        Difficulty.hard: {},
      },
      Hand.right: {
        Difficulty.easy: {},
        Difficulty.normal: {},
        Difficulty.hard: {},
      }
    };
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(gameCountKey);
      await sp.remove(dataKey);
      await sp.remove(criticalKey);
      await sp.remove(countDayKey);
      await sp.remove(dailyCountKey);
      await sp.remove(lastDayKey);
      await sp.remove(dayStreakKey);
    } catch (_) {}
    setState();
  }

  int getUnlockedLevel(Difficulty difficulty, Hand hand) {
    try {
      final records = _data[hand]![difficulty]!;
      final levels = records.keys;
      if (levels.isEmpty) return 1;
      final unlocked = levels.reduce(max);
      return unlocked + 1;
    } catch (_) {}
    return 1;
  }

  void recordScore(GameRecord record) {
    final dataRecord = _data[record.hand]![record.difficulty]!;
    final lastScore = dataRecord[record.level];
    _gameCount++;
    if (lastScore == null || lastScore < record.score) {
      dataRecord[record.level] = record.score;
    }
    _updateDb();
  }

  int getScore(GameConfig config) {
    final score = _data[config.hand]?[config.difficulty]?[config.level] ?? 0;
    return score;
  }

  Future<void> _updateDb() async {
    final sp = await SharedPreferences.getInstance();
    sp.setInt(gameCountKey, _gameCount);

    final cleanedData = _data.map(
      (hand, rec) => MapEntry(
        hand.index.toString(),
        rec.map(
          (difficulty, details) => MapEntry(
            difficulty.index.toString(),
            details.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        ),
      ),
    );
    final encodedData = jsonEncode(cleanedData);
    sp.setString(
      dataKey,
      encodedData,
    );
    setState();
  }
}

class GameRecord {
  final Hand hand;
  final Difficulty difficulty;
  final int level;
  final int score;

  GameRecord(this.hand, this.difficulty, this.level, this.score);
}
