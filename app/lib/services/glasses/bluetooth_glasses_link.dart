import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_frames.dart';
import 'glasses_link.dart';

/// The Baseera glasses' Bluetooth service (firmware: link.cpp).
abstract final class BaseeraBle {
  static final service = Guid('6b9a0001-3c1e-4f5a-9a2e-b45e1ea5a001');
  static final frame = Guid('6b9a0002-3c1e-4f5a-9a2e-b45e1ea5a001');
  static final status = Guid('6b9a0003-3c1e-4f5a-9a2e-b45e1ea5a001');
  static final command = Guid('6b9a0004-3c1e-4f5a-9a2e-b45e1ea5a001');

  /// One link-layer packet per piece of a camera frame.
  static const mtu = 247;
}

/// The real glasses over Bluetooth Low Energy (protocol in
/// `glasses_link.dart`). Nothing to pair: the app scans for the glasses'
/// service and connects; Android asks for the Bluetooth permission the
/// first time.
class BluetoothGlassesLink implements GlassesLink {
  BluetoothGlassesLink({this.scanFor = const Duration(seconds: 8)});

  final Duration scanFor;
  final _events = StreamController<GlassesEvent>.broadcast();
  final _frames = BleFrameAssembler();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  BluetoothDevice? _device;
  BluetoothCharacteristic? _command;
  bool _connecting = false;

  @override
  Stream<GlassesEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_device != null || _connecting) return;
    _connecting = true;
    _emit(GlassesConnection.connecting);
    BluetoothDevice? device;
    try {
      if (!await FlutterBluePlus.isSupported) {
        throw StateError('this phone has no Bluetooth LE');
      }
      await _bluetoothOn();
      device = await _find();
      if (device == null) throw StateError('glasses not found');

      await device.connect(
        timeout: const Duration(seconds: 10),
        mtu: BaseeraBle.mtu,
      );
      if (Platform.isAndroid) {
        // Faster connection events and the 2M radio: more frames per second.
        await _tryIt(
          () => device!.requestConnectionPriority(
            connectionPriorityRequest: ConnectionPriority.high,
          ),
        );
        await _tryIt(
          () => device!.setPreferredPhy(
            txPhy: Phy.le2m.mask,
            rxPhy: Phy.le2m.mask,
            option: PhyCoding.noPreferred,
          ),
        );
      }

      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == BaseeraBle.service);
      BluetoothCharacteristic find(Guid id) =>
          service.characteristics.firstWhere((c) => c.uuid == id);
      final frame = find(BaseeraBle.frame);
      final status = find(BaseeraBle.status);
      _command = find(BaseeraBle.command);

      _subscriptions
        ..add(frame.onValueReceived.listen(_onFramePiece))
        ..add(status.onValueReceived.listen(_onStatus))
        ..add(
          device.connectionState.listen((state) {
            if (state == BluetoothConnectionState.disconnected) _onClosed();
          }),
        );
      await status.setNotifyValue(true);
      await frame.setNotifyValue(true);
      _device = device;
      _emit(GlassesConnection.connected);
    } catch (e) {
      debugPrint('Glasses not reachable over Bluetooth: $e');
      if (device != null) await _tryIt(device.disconnect);
      _onClosed();
    } finally {
      _connecting = false;
    }
  }

  Future<void> _bluetoothOn() async {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) return;
    // Android shows "allow Bluetooth?"; elsewhere the user turns it on.
    if (Platform.isAndroid) await _tryIt(FlutterBluePlus.turnOn);
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 15));
  }

  /// Scans for the glasses' service; null when none answers in [scanFor].
  Future<BluetoothDevice?> _find() async {
    for (final d in FlutterBluePlus.connectedDevices) {
      if (d.platformName.startsWith('Baseera')) return d;
    }
    final found = Completer<BluetoothDevice?>();
    final results = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty && !found.isCompleted) {
        found.complete(results.first.device);
      }
    });
    try {
      await FlutterBluePlus.startScan(
        withServices: [BaseeraBle.service],
        timeout: scanFor,
      );
      return await Future.any([
        found.future,
        FlutterBluePlus.isScanning
            .where((scanning) => !scanning)
            .first
            .then((_) => null),
      ]);
    } finally {
      await results.cancel();
      await _tryIt(FlutterBluePlus.stopScan);
    }
  }

  void _onFramePiece(List<int> piece) {
    final jpeg = _frames.add(piece);
    if (jpeg != null && !_events.isClosed) _events.add(GlassesFrame(jpeg));
  }

  void _onStatus(List<int> value) {
    try {
      final json = jsonDecode(utf8.decode(value, allowMalformed: true));
      if (json is Map<String, Object?> && json['t'] == 'status') {
        if (!_events.isClosed) _events.add(GlassesStatus.fromJson(json));
      }
    } catch (e) {
      debugPrint('Glasses sent unreadable status: $e');
    }
  }

  void _onClosed() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _frames.reset();
    _command = null;
    _device = null;
    _emit(GlassesConnection.disconnected);
  }

  void _emit(GlassesConnection state) {
    if (!_events.isClosed) _events.add(GlassesLinkChanged(state));
  }

  @override
  Future<void> disconnect() async {
    final device = _device;
    if (device == null) return;
    await _tryIt(device.disconnect);
    _onClosed();
  }

  @override
  void send(Map<String, Object?> command) {
    final characteristic = _command;
    if (characteristic == null) return;
    final bytes = utf8.encode(jsonEncode(command));
    characteristic
        .write(bytes, withoutResponse: bytes.length <= BaseeraBle.mtu - 3)
        .catchError((Object e) => debugPrint('Glasses command dropped: $e'));
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }

  static Future<void> _tryIt(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Bluetooth: $e');
    }
  }
}

GlassesLink createBluetoothGlassesLink() => BluetoothGlassesLink();
