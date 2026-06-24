plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStoreFile = providers.environmentVariable("ATMA_ANDROID_KEYSTORE_PATH").orNull
val releaseStorePassword = providers.environmentVariable("ATMA_ANDROID_KEYSTORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("ATMA_ANDROID_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("ATMA_ANDROID_KEY_PASSWORD").orNull
val demoReleaseSigningAllowed =
    providers.environmentVariable("ATMA_ANDROID_DEMO_RELEASE").orNull == "true"
val releaseTaskRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }
val hasReleaseSigning =
    !releaseStoreFile.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.atmacoffee.atma_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.atmacoffee.atma_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (!releaseTaskRequested) {
                signingConfig = signingConfigs.getByName("debug")
            } else if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (demoReleaseSigningAllowed) {
                signingConfig = signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Production release signing is not configured. " +
                        "Set ATMA_ANDROID_KEYSTORE_PATH, ATMA_ANDROID_KEYSTORE_PASSWORD, " +
                        "ATMA_ANDROID_KEY_ALIAS, and ATMA_ANDROID_KEY_PASSWORD. " +
                        "Use ATMA_ANDROID_DEMO_RELEASE=true only for explicit non-production demo release builds."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
