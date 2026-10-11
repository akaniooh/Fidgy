import '../../common/presentation/presentation.dart';
import '../ui/dialogs/select_level_dialog.dart';
import '../ui/views/game_view.dart';
import '../ui/views/score_board_view.dart';
import '../ui/views/select_difficulty_view.dart';
import '../ui/views/select_hand_view.dart';
import 'app_settings.dart';
import 'game_config.dart';
import 'game_controller.dart';
import 'game_data.dart';

class GeneralManager {
  GeneralManager._();
  static final i = GeneralManager._();

  Difficulty? _difficulty;
  Hand? _hand;
  int? _level;

  void goHome() {
    AppNavigator.main.popUntilRoute('HomeView');
  }

  void play() {
    AppNavigator.main.push(const SelectHandView());
  }

  void selectHand(Hand hand) {
    _hand = hand;
    AppNavigator.main.push(const SelectDifficultyView());
  }

  void selectDifficulty(Difficulty difficulty) {
    _difficulty = difficulty;
    SelectLevelDialog(difficulty: difficulty, hand: _hand!).open();
  }

  void selectLevel(int i) {
    assert(i >= 1 && i <= 15);
    _level = i;

    final config = GameConfig(
      level: _level!,
      hand: _hand!,
      difficulty: _difficulty!,
      assist: AppSettings.i.assistLevel,
    );
    _beginGame(config);
  }

  void nextLevel() {
    if (_level == null || _level == 15) return;
    final nextLevel = _level! + 1;
    selectLevel(nextLevel);
  }

  void replayLevel() {
    if (_level == null) return;
    selectLevel(_level!);
  }

  void _beginGame(GameConfig config) {
    final game = GameController(config);
    AppNavigator.main.push(GameView(game));
  }

  void gameWon(int score) {
    final record = GameRecord(_hand!, _difficulty!, _level!, score);
    GameData.i.recordScore(record);
  }

  void openScoreBoard() {
    AppNavigator.main.push(const ScoreBoardView());
  }
}
