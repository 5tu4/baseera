# MediaPipe Tasks and TFLite load classes via JNI/reflection; R8 must keep them
# or sign recognition crashes in release builds.
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class org.tensorflow.** { *; }
-dontwarn com.google.mediapipe.**
-dontwarn com.google.protobuf.**
-dontwarn org.tensorflow.**
-dontwarn javax.lang.model.**
-dontwarn com.google.auto.value.**
