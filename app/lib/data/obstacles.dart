import '../l10n/app_language.dart';

/// What the glasses can warn about. Each value owns a voice-clip number: the
/// glasses store one short recorded clip per number (in LittleFS) and the
/// phone only sends numbers, so alerts play instantly and need no audio
/// streaming. The firmware's clip table must use these same numbers.
enum ObstacleKind {
  // Falls first: with no white cane, a missed drop is the worst outcome.
  dropOff(1, 'انخفاض', 'Drop', ObstacleRisk.fall),
  stairsDown(2, 'درج نازل', 'Stairs going down', ObstacleRisk.fall),
  hole(3, 'حفرة', 'Hole', ObstacleRisk.fall),
  curb(4, 'رصيف', 'Curb', ObstacleRisk.fall),
  // Seen by the camera, which can't tell up from down; the downward sensor
  // is what catches the drop.
  stairs(5, 'درج', 'Stairs', ObstacleRisk.fall),
  // Things that move.
  car(10, 'سيارة', 'Car', ObstacleRisk.moving),
  motorcycle(11, 'دراجة نارية', 'Motorcycle', ObstacleRisk.moving),
  bicycle(12, 'دراجة', 'Bicycle', ObstacleRisk.moving),
  bus(13, 'حافلة', 'Bus', ObstacleRisk.moving),
  person(14, 'شخص', 'Person', ObstacleRisk.moving),
  dog(15, 'كلب', 'Dog', ObstacleRisk.moving),
  // Things that stand still.
  obstacle(20, 'عائق', 'Obstacle', ObstacleRisk.still),
  stairsUp(21, 'درج صاعد', 'Stairs going up', ObstacleRisk.still),
  door(22, 'باب', 'Door', ObstacleRisk.still),
  wall(23, 'جدار', 'Wall', ObstacleRisk.still),
  pole(24, 'عمود', 'Pole', ObstacleRisk.still),
  tree(25, 'شجرة', 'Tree', ObstacleRisk.still),
  chair(26, 'كرسي', 'Chair', ObstacleRisk.still),
  table(27, 'طاولة', 'Table', ObstacleRisk.still),
  bench(28, 'مقعد', 'Bench', ObstacleRisk.still);

  const ObstacleKind(this.clip, this.arabic, this.english, this.risk);

  final int clip;
  final String arabic;
  final String english;
  final ObstacleRisk risk;

  String label(AppLanguage language) => language.isArabic ? arabic : english;
}

/// The warning for an obstacle-model label. Baseera's own model is trained
/// with these enum names as labels (ml/obstacle/classes.py); the aliases let
/// a stock COCO model work too, before the custom one is trained.
ObstacleKind? obstacleKindForLabel(String label) {
  final name = label.trim().toLowerCase();
  return ObstacleKind.values.asNameMap()[name] ?? _labelAliases[name];
}

const _labelAliases = {
  'dining table': ObstacleKind.table,
  'truck': ObstacleKind.car,
  'motorbike': ObstacleKind.motorcycle,
  'street light': ObstacleKind.pole,
  'potted plant': ObstacleKind.obstacle,
  'fire hydrant': ObstacleKind.obstacle,
  'couch': ObstacleKind.obstacle,
  'bed': ObstacleKind.obstacle,
  'suitcase': ObstacleKind.obstacle,
  'parking meter': ObstacleKind.pole,
  'stop sign': ObstacleKind.pole,
};

/// Higher risk interrupts lower risk and ignores the repeat cooldown sooner.
enum ObstacleRisk { still, moving, fall }

enum ObstacleDirection {
  ahead(50, 'أمامك', 'ahead'),
  left(51, 'على يسارك', 'on your left'),
  right(52, 'على يمينك', 'on your right');

  const ObstacleDirection(this.clip, this.arabic, this.english);

  final int clip;
  final String arabic;
  final String english;
}

/// Vibration patterns sent to the glasses: on/off times in ms, starting with
/// "on". The glasses have one motor, so the pattern says how urgent a warning
/// is; the phone's voice says what and where.
abstract final class GlassesVibration {
  /// Stairs and drops: two long buzzes.
  static const fall = [500, 150, 500];

  /// Anything very close: three quick pulses.
  static const veryClose = [120, 80, 120, 80, 120];

  /// People, vehicles, animals: two buzzes.
  static const moving = [180, 120, 180];

  /// Furniture, doors, poles: one buzz.
  static const still = [250];

  /// Repeated while something stays very close ahead.
  static const closeAhead = [90];

  static const connected = [120];
  static const alertsOn = [300];
  static const alertsOff = [120, 120, 120];
  static const test = [400];
}

/// Clips that are not an object or a direction.
abstract final class GlassesClips {
  static const veryClose = 60;
  static const connected = 80;
  static const disconnected = 81;
  static const batteryLow = 82;
  static const alertsOff = 83;
  static const alertsOn = 84;
}

/// One warning: "كرسي على يمينك، قريب جداً".
class ObstacleAlert {
  const ObstacleAlert({
    required this.kind,
    required this.direction,
    required this.veryClose,
    required this.time,
  });

  final ObstacleKind kind;
  final ObstacleDirection direction;
  final bool veryClose;
  final DateTime time;

  /// How the glasses vibrate for it.
  List<int> get vibration => kind.risk == ObstacleRisk.fall
      ? GlassesVibration.fall
      : veryClose
      ? GlassesVibration.veryClose
      : kind.risk == ObstacleRisk.moving
      ? GlassesVibration.moving
      : GlassesVibration.still;

  /// The clips the glasses play, in order.
  List<int> get clips => [
    kind.clip,
    direction.clip,
    if (veryClose) GlassesClips.veryClose,
  ];

  String text(AppLanguage language) {
    if (language.isArabic) {
      return '${kind.arabic} ${direction.arabic}${veryClose ? '، قريب جداً' : ''}';
    }
    return '${kind.english} ${direction.english}${veryClose ? ', very close' : ''}';
  }
}
