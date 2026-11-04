import 'dart:typed_data';

import '../../data/obstacles.dart';

/// Wire protocol between the phone and the glasses. The firmware must match.
///
/// Transport (LINK_BLUETOOTH in the firmware's config.h):
/// - Bluetooth LE (default): the glasses advertise as "Baseera-XXXX" with
///   the service in `bluetooth_glasses_link.dart`. Camera frames come in
///   pieces on the frame characteristic (first piece: `0x80|id` + length,
///   4 bytes little-endian; the others: `id`), the status JSON on the status
///   characteristic; commands are written as JSON to the command one.
/// - Wi-Fi: the glasses run an access point ("Baseera-XXXX") and serve
///   `ws://192.168.4.1/ws`; frames are binary messages, the rest text.
///
/// glasses → phone
/// ```
///   <frame>                 one JPEG camera frame (320×240; ~4 per second
///                           over Bluetooth, ~8 over Wi-Fi)
///   {"t":"status","bat":82,"fw":"0.2.0","mute":false,
///    "caps":{"spk":false,"dist":false,"btn":false},
///    "front":143,"down":61}
///                           battery %, what is fitted, and the distances in
///                           cm when the distance sensors are fitted
///                           (null = no reading)
/// ```
/// phone → glasses
/// ```
///   {"t":"vib","p":[120,80,120]}     vibration pattern: on/off times in ms
///   {"t":"buzz","ms":300}            vibrate once
///   {"t":"say","clips":[26,52,60]}   play these voice clips (speaker fitted)
///   {"t":"config","alertCm":120,"voice":true,"vibrate":true}
/// ```
/// Stage 1 glasses have the camera and the vibration module only: the phone
/// speaks every warning and tells the glasses how to vibrate. With distance
/// sensors fitted, the glasses also vibrate on their own when something is
/// closer than `alertCm`, so the closest warnings keep working if the phone
/// drops out.
enum GlassesConnection { disconnected, connecting, connected }

sealed class GlassesEvent {
  const GlassesEvent();
}

class GlassesLinkChanged extends GlassesEvent {
  const GlassesLinkChanged(this.state);

  final GlassesConnection state;
}

/// What a pair of glasses has fitted (`HAS_*` in the firmware's config.h).
class GlassesCaps {
  const GlassesCaps({
    required this.speaker,
    required this.distance,
    required this.button,
  });

  /// Stage 1: camera and vibration module only.
  static const stage1 = GlassesCaps(
    speaker: false,
    distance: false,
    button: false,
  );

  /// Firmware 0.1, which sent no "caps", had everything.
  static const full = GlassesCaps(speaker: true, distance: true, button: true);

  final bool speaker;
  final bool distance;
  final bool button;

  static GlassesCaps fromJson(Object? json) {
    if (json is! Map) return full;
    return GlassesCaps(
      speaker: json['spk'] == true,
      distance: json['dist'] == true,
      button: json['btn'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassesCaps &&
      other.speaker == speaker &&
      other.distance == distance &&
      other.button == button;

  @override
  int get hashCode => Object.hash(speaker, distance, button);
}

/// Periodic sensor report from the glasses.
class GlassesStatus extends GlassesEvent {
  const GlassesStatus({
    this.battery,
    this.frontCm,
    this.downCm,
    this.firmware,
    this.caps,
  });

  final int? battery;

  /// Forward-looking distance sensor.
  final int? frontCm;

  /// Downward-angled distance sensor: jumps when the floor drops away
  /// (stairs going down, a curb, a hole).
  final int? downCm;
  final String? firmware;

  /// Null when the message doesn't say (keep what is known).
  final GlassesCaps? caps;

  static GlassesStatus fromJson(Map<String, Object?> json) {
    int? whole(Object? v) => v is num ? v.round() : null;
    return GlassesStatus(
      battery: whole(json['bat']),
      frontCm: whole(json['front']),
      downCm: whole(json['down']),
      firmware: json['fw'] is String ? json['fw'] as String : null,
      caps: GlassesCaps.fromJson(json['caps']),
    );
  }
}

/// One camera frame from the glasses.
class GlassesFrame extends GlassesEvent {
  const GlassesFrame(this.jpeg);

  final Uint8List jpeg;
}

/// Something the obstacle model found in a frame (or the demo made up).
class GlassesSighting extends GlassesEvent {
  const GlassesSighting({
    required this.kind,
    required this.direction,
    this.veryClose = false,
  });

  final ObstacleKind kind;
  final ObstacleDirection direction;
  final bool veryClose;
}

/// A connection to a pair of glasses: the real ones (Bluetooth or Wi-Fi), or
/// a demo.
abstract class GlassesLink {
  Stream<GlassesEvent> get events;

  Future<void> connect();

  Future<void> disconnect();

  /// Sends one command map (see the protocol above). Dropped when offline.
  void send(Map<String, Object?> command);

  Future<void> dispose();
}

abstract final class GlassesCommands {
  static Map<String, Object?> say(List<int> clips) => {
    't': 'say',
    'clips': clips,
  };

  static Map<String, Object?> buzz(int ms) => {'t': 'buzz', 'ms': ms};

  /// On/off times in ms, starting with "on".
  static Map<String, Object?> vibrate(List<int> pattern) => {
    't': 'vib',
    'p': pattern,
  };

  static Map<String, Object?> config({
    required int alertCm,
    required bool voice,
    required bool vibrate,
  }) => {'t': 'config', 'alertCm': alertCm, 'voice': voice, 'vibrate': vibrate};
}
