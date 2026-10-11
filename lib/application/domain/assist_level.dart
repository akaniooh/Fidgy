/// Tremor-friendly presets. Each preset changes how forgiving the game is
/// without changing the exercise itself.
enum AssistLevel {
  standard(
    label: 'Standard',
    description: 'Default game',
    hitScale: 1.2,
    visualScale: 1.0,
    lives: 5,
    timeMultiplier: 1.0,
    tapCooldown: Duration.zero,
  ),
  relaxed(
    label: 'Relaxed',
    description: 'Bigger targets, 7 lives, 50% more time',
    hitScale: 1.5,
    visualScale: 1.15,
    lives: 7,
    timeMultiplier: 1.5,
    tapCooldown: Duration(milliseconds: 150),
  ),
  extraRelaxed(
    label: 'Extra relaxed',
    description: 'Largest targets, 10 lives, double time',
    hitScale: 1.9,
    visualScale: 1.3,
    lives: 10,
    timeMultiplier: 2.0,
    tapCooldown: Duration(milliseconds: 250),
  );

  const AssistLevel({
    required this.label,
    required this.description,
    required this.hitScale,
    required this.visualScale,
    required this.lives,
    required this.timeMultiplier,
    required this.tapCooldown,
  });

  final String label;
  final String description;

  /// Tap radius around a finger's centre, relative to the standard circle.
  final double hitScale;

  /// How much larger the finger circles are drawn.
  final double visualScale;

  final int lives;

  /// Multiplier applied to the level timer.
  final double timeMultiplier;

  /// Taps arriving sooner than this after the previous one are ignored,
  /// so one shaky press is not counted twice.
  final Duration tapCooldown;

  AssistLevel get next => AssistLevel.values[(index + 1) % AssistLevel.values.length];
}
