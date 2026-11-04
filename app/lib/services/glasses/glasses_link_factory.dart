// dart:io sockets and Bluetooth are not available in the web preview build.
export 'wifi_glasses_link_stub.dart'
    if (dart.library.io) 'wifi_glasses_link.dart';
export 'bluetooth_glasses_link_stub.dart'
    if (dart.library.io) 'bluetooth_glasses_link.dart';
