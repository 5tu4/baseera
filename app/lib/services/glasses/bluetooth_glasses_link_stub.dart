import 'simulated_glasses_link.dart';
import 'glasses_link.dart';

/// The web preview build has no Bluetooth link; it only ever shows the demo.
GlassesLink createBluetoothGlassesLink() => SimulatedGlassesLink();
