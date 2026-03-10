plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.erpnext_stock_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.erpnext_stock_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

val flutterApkDir = layout.buildDirectory.dir("outputs/flutter-apk")
val debugApkDir = layout.buildDirectory.dir("outputs/apk/debug")
val releaseApkDir = layout.buildDirectory.dir("outputs/apk/release")

tasks.register<Copy>("copyAccordDebugApk") {
    from(debugApkDir.map { it.file("app-debug.apk") })
    into(flutterApkDir)
}

tasks.register<Copy>("copyAccordDebugAliasApk") {
    from(debugApkDir.map { it.file("app-debug.apk") })
    into(flutterApkDir)
    rename { "accord-debug.apk" }
}

tasks.register<Copy>("copyAccordReleaseApk") {
    from(releaseApkDir.map { it.file("app-release.apk") })
    into(flutterApkDir)
}

tasks.register<Copy>("copyAccordReleaseAliasApk") {
    from(releaseApkDir.map { it.file("app-release.apk") })
    into(flutterApkDir)
    rename { "accord.apk" }
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy("copyAccordDebugApk", "copyAccordDebugAliasApk")
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("copyAccordReleaseApk", "copyAccordReleaseAliasApk")
}
