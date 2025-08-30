package com.prasadSanap.learnify_rewards

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // For Android 15+ (API 35+), edge-to-edge is enabled by default
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } else {
            // For older versions, manually enable edge-to-edge
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        
        super.onCreate(savedInstanceState)
    }
}
