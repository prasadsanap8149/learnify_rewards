plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.prasadSanap.learnify_rewards.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-Xno-param-assertions",
            "-Xno-call-assertions",
            "-Xno-receiver-assertions"
        )
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // Unique Application ID for Google Play Store
        applicationId = "com.prasadSanap.learnify_rewards.app"
        // Minimum SDK for modern Android features
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // App store metadata
        setProperty("archivesBaseName", "learnify-rewards-v$versionName")

        // Enable vector drawables support
        vectorDrawables {
            useSupportLibrary = true
        }

        // Proguard configuration for release builds
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // Production release configuration
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // TODO: Add your own signing config for the release build
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug")

            // Firebase Performance monitoring for production
            buildConfigField("boolean", "ENABLE_FIREBASE_PERFORMANCE", "true")
        }

        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            buildConfigField("boolean", "ENABLE_FIREBASE_PERFORMANCE", "false")
        }
    }

    // Configure signing configs for app store release
    signingConfigs {
        // TODO: Configure release signing for Google Play Store
        // create("release") {
        //     keyAlias = "your-key-alias"
        //     keyPassword = "your-key-password"
        //     storeFile = file("path/to/your/keystore.jks")
        //     storePassword = "your-store-password"
        // }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM - manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // Firebase Core - required for all Firebase services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-perf")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-config")

    // Google Mobile Ads dependencies
    implementation("com.google.android.gms:play-services-ads:23.6.0")
    implementation("androidx.browser:browser:1.8.0")

    // Additional dependencies for app store features
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.work:work-runtime-ktx:2.10.0")
}
