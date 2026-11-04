plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fablab.baseera"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fablab.baseera"
        // flutter_tts needs Android 7.0+.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config before handing the APK over.
            signingConfig = signingConfigs.getByName("debug")
            // R8 strips classes MediaPipe and TFLite look up by name, which breaks
            // sign recognition in release builds only (found in Ishara). Leave
            // the code whole — it costs a few MB and nothing else.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Hand + pose landmarks for sign recognition (see LandmarkChannel.kt).
    implementation("com.google.mediapipe:tasks-vision:0.10.35")
}
