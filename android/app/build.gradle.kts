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
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-config-ktx")
    
    // Additional dependencies for app store features
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.5")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
