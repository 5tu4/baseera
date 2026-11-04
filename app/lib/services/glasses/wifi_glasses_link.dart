import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'glasses_link.dart';

/// The real glasses, over their own Wi-Fi access point (protocol in
/// `glasses_link.dart`).
///
/// For bench testing: join the glasses' Wi-Fi from the phone's settings and
/// turn mobile data off, so Android sends 192.168.4.1 traffic over Wi-Fi.
/// The production version binds to the glasses network natively (and runs
/// in a foreground service) so mobile data can stay on.
class WifiGlassesLink implements GlassesLink {
  WifiGlassesLink({this.url = 'ws://192.168.4.1/ws'});

  final String url;
  final _events = StreamController<GlassesEvent>.broadcast();
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;

  @override
  Stream<GlassesEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    _emit(GlassesConnection.connecting);
    try {
      final socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 5));
      socket.pingInterval = const Duration(seconds: 3);
      _socket = socket;
      _subscription = socket.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object e) {
          debugPrint('Glasses link error: $e');
          _onClosed();
        },
        cancelOnError: true,
      );
      _emit(GlassesConnection.connected);
    } catch (e) {
      debugPrint('Glasses not reachable at $url: $e');
      _onClosed();
    }
  }

  void _onMessage(dynamic message) {
    if (message is List<int>) {
      _events.add(GlassesFrame(Uint8List.fromList(message)));
      return;
    }
    if (message is! String) return;
    try {
      final json = jsonDecode(message);
      if (json is Map<String, Object?> && json['t'] == 'status') {
        _events.add(GlassesStatus.fromJson(json));
      }
    } catch (e) {
      debugPrint('Glasses sent unreadable message: $e');
    }
  }

  void _onClosed() {
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    _emit(GlassesConnection.disconnected);
  }

  void _emit(GlassesConnection state) {
    if (!_events.isClosed) _events.add(GlassesLinkChanged(state));
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    if (socket == null) return;
    await socket.close();
    _onClosed();
  }

  @override
  void send(Map<String, Object?> command) {
    try {
      _socket?.add(jsonEncode(command));
    } catch (e) {
      debugPrint('Glasses command dropped: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}

GlassesLink createWifiGlassesLink() => WifiGlassesLink();
