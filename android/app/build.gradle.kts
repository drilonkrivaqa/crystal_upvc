import java.io.File
import java.io.IOException

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun File.safeCanonicalFile(): File {
    val canonical = try {
        canonicalFile
    } catch (_: IOException) {
        absoluteFile
    }

    if (!System.getProperty("os.name", "").startsWith("Windows")) {
        return canonical
    }

    val shortPath = runCatching {
        val process = ProcessBuilder(
            "cmd",
            "/c",
            "for %I in (\"${canonical.path}\") do @echo %~sI"
        )
            .redirectErrorStream(true)
            .start()
            .apply { waitFor() }

        process.inputStream.bufferedReader().use { it.readLine() }
            ?.takeIf { it.isNotBlank() }
    }.getOrNull()

    return shortPath?.let { File(it) } ?: canonical
}

val sanitizedBuildDir = projectDir.safeCanonicalFile().resolve("build")

buildDir = sanitizedBuildDir
layout.buildDirectory.set(sanitizedBuildDir)

android {
    namespace = "com.example.crystal_upvc"
    compileSdk = flutter.compileSdkVersion
    // Override the default Flutter NDK with the version required by
    // image_picker and related plugins.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.crystal_upvc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion.coerceAtLeast(21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
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
