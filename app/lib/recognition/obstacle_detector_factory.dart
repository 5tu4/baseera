// TFLite needs dart:ffi, which the web preview build does not have.
export 'obstacle_detector_stub.dart'
    if (dart.library.ffi) 'yolo_obstacle_detector.dart';
