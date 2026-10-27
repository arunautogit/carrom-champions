package com.carrom.champions

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient

class MainActivity : Activity() {

    private lateinit var webView: WebView
    private var vibrator: Vibrator? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep screen on during gameplay & lock to sensor landscape
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE

        hideSystemUI()

        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

        webView = WebView(this).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                databaseEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                mediaPlaybackRequiresUserGesture = false
                loadsImagesAutomatically = true
                cacheMode = WebSettings.LOAD_DEFAULT
            }

            // Native Hardware Acceleration
            setLayerType(View.LAYER_TYPE_HARDWARE, null)
            setBackgroundColor(0xFF140803.toInt())

            // Expose Native Android Bridge to JavaScript for haptics
            addJavascriptInterface(AndroidBridge(), "AndroidBridge")

            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    return false
                }
            }

            webChromeClient = WebChromeClient()

            // Load the HTML5 Carrom game
            loadUrl("file:///android_asset/index.html")
        }

        setContentView(webView)
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
            )
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemUI()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Pass to webview to trigger exit modal or close active overlays
        if (::webView.isInitialized) {
            webView.evaluateJavascript(
                """
                if (typeof closeExitConfirmModal === 'function') {
                    const exitEl = document.getElementById('exit-confirm-overlay');
                    if (exitEl && !exitEl.classList.contains('hidden')) {
                        closeExitConfirmModal();
                    } else if (Game.getState() === 'aiming' || Game.getState() === 'shooting') {
                        openExitConfirmModal();
                    }
                }
                """.trimIndent(),
                null
            )
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    inner class AndroidBridge {
        @JavascriptInterface
        fun vibrate(milliseconds: Long) {
            vibrator?.let { vib ->
                if (vib.hasVibrator()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vib.vibrate(VibrationEffect.createOneShot(milliseconds, VibrationEffect.DEFAULT_AMPLITUDE))
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(milliseconds)
                    }
                }
            }
        }

        @JavascriptInterface
        fun vibratePattern(pattern: LongArray) {
            vibrator?.let { vib ->
                if (vib.hasVibrator()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vib.vibrate(VibrationEffect.createWaveform(pattern, -1))
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(pattern, -1)
                    }
                }
            }
        }
    }
}
