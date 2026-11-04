// TFLite needs dart:ffi, which the web preview build does not have.
export 'recognizer_factory_stub.dart'
    if (dart.library.ffi) 'recognizer_factory_native.dart';
