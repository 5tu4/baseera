import 'dart:async';
import 'dart:math';

import '../../data/obstacles.dart';
import 'glasses_link.dart';

/// Pretend stage 1 glasses (camera and vibration only) for demos before the
/// hardware exists: a person walking around, the battery slowly draining and
/// the obstacle model naming the odd object, now and then very close ahead.
class SimulatedGlassesLink implements GlassesLink {
  SimulatedGlassesLink({
    Random? random,
    this.tick = const Duration(milliseconds: 700),
    this.connectDelay = const Duration(milliseconds: 1200),
  }) : _random = random ?? Random();

  final Random _random;
  final Duration tick;
  final Duration connectDelay;

  final _events = StreamController<GlassesEvent>.broadcast();
  Timer? _timer;
  bool _online = false;
  double _battery = 86;
  double _frontCm = 240;
  int _nextSighting = 6;
  ObstacleKind? _ahead;

  /// Commands the app sent, newest last (shown nowhere; handy in tests).
  final List<Map<String, Object?>> sent = [];

  static const _demoKinds = [
    ObstacleKind.person,
    ObstacleKind.chair,
    ObstacleKind.door,
    ObstacleKind.car,
    ObstacleKind.pole,
    ObstacleKind.table,
    ObstacleKind.bicycle,
    ObstacleKind.tree,
    ObstacleKind.stairs,
  ];

  @override
  Stream<GlassesEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_online) return;
    _events.add(const GlassesLinkChanged(GlassesConnection.connecting));
    await Future<void>.delayed(connectDelay);
    if (_events.isClosed) return;
    _online = true;
    _events.add(const GlassesLinkChanged(GlassesConnection.connected));
    _timer = Timer.periodic(tick, (_) => _step());
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    if (!_online) return;
    _online = false;
    if (!_events.isClosed) {
      _events.add(const GlassesLinkChanged(GlassesConnection.disconnected));
    }
  }

  @override
  void send(Map<String, Object?> command) {
    if (_online) sent.add(command);
  }

  void _step() {
    // Walking: the next thing ahead gets closer, then the way opens up.
    _frontCm -= 15 + _random.nextDouble() * 25;
    if (_frontCm < 35) _frontCm = 160 + _random.nextDouble() * 160;
    _battery = max(5, _battery - 0.04);

    _events.add(
      GlassesStatus(
        battery: _battery.round(),
        firmware: 'demo',
        caps: GlassesCaps.stage1,
      ),
    );

    if (--_nextSighting <= 0) {
      _nextSighting = 8 + _random.nextInt(8);
      _ahead = _demoKinds[_random.nextInt(_demoKinds.length)];
      final direction = ObstacleDirection
          .values[_random.nextInt(ObstacleDirection.values.length)];
      _events.add(
        GlassesSighting(
          kind: _ahead!,
          direction: direction,
          veryClose: _frontCm < 80,
        ),
      );
      if (direction != ObstacleDirection.ahead) _ahead = null;
    } else if (_ahead != null && _frontCm < 80) {
      // The model keeps seeing it while it stays right in front.
      _events.add(
        GlassesSighting(
          kind: _ahead!,
          direction: ObstacleDirection.ahead,
          veryClose: true,
        ),
      );
    } else if (_frontCm > 150) {
      _ahead = null;
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}
