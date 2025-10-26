import java.util.Properties
import java.io.File
import java.io.FileInputStream

fun flutterSdkPath(): String {
    val localProperties = Properties()
    val localPropertiesFile = File(rootDir, "local.properties")
    if (localPropertiesFile.exists()) {
        FileInputStream(localPropertiesFile).use { localProperties.load(it) }
    }
    return localProperties.getProperty("flutter.sdk")
        ?: System.getenv("FLUTTER_SDK")
        ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file or with the FLUTTER_SDK environment variable.")
}

pluginManagement {
    includeBuild(File(flutterSdkPath(), "packages/flutter_tools/gradle").path)
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
