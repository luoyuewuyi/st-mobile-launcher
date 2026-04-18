package com.stmobile.launcher

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.snackbar.Snackbar
import com.stmobile.launcher.databinding.ActivityMainBinding
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    private val localUrl = "http://127.0.0.1:8000"
    private val startScriptPath = "/data/data/com.termux/files/home/sillytavern-mobile/start-st.sh"
    private val pollIntervalMs = 1500L
    private val maxPollAttempts = 30
    private var pollAttempts = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupWebView(binding.webView)

        binding.swipeRefresh.setOnRefreshListener {
            binding.webView.reload()
        }

        binding.retryButton.setOnClickListener {
            launchSillyTavern()
        }

        binding.openTermuxButton.setOnClickListener {
            openTermux()
        }

        launchSillyTavern()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView(webView: WebView) {
        with(webView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            useWideViewPort = true
            loadWithOverviewMode = true
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            mediaPlaybackRequiresUserGesture = false
            builtInZoomControls = false
            displayZoomControls = false
        }

        webView.webChromeClient = WebChromeClient()
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                binding.swipeRefresh.isRefreshing = false
                binding.statusText.text = getString(R.string.status_running)
            }
        }
    }

    private fun launchSillyTavern() {
        binding.statusText.text = getString(R.string.status_starting)
        binding.swipeRefresh.isRefreshing = true
        binding.webView.visibility = WebView.GONE
        binding.launcherPanel.visibility = android.view.View.VISIBLE

        val intent = Intent("com.termux.RUN_COMMAND").apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            putExtra("com.termux.RUN_COMMAND_PATH", startScriptPath)
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
            putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        }

        try {
            startService(intent)
            pollAttempts = 0
            waitForServer()
        } catch (_: SecurityException) {
            binding.swipeRefresh.isRefreshing = false
            showPermissionHelp()
        } catch (_: ActivityNotFoundException) {
            binding.swipeRefresh.isRefreshing = false
            showTermuxMissingDialog()
        } catch (_: IllegalStateException) {
            binding.swipeRefresh.isRefreshing = false
            Snackbar.make(binding.root, R.string.error_failed_to_start, Snackbar.LENGTH_LONG).show()
        }
    }

    private fun waitForServer() {
        executor.execute {
            val available = isServerAvailable()
            handler.post {
                if (available) {
                    binding.launcherPanel.visibility = android.view.View.GONE
                    binding.webView.visibility = android.view.View.VISIBLE
                    binding.webView.loadUrl(localUrl)
                    return@post
                }

                pollAttempts += 1
                if (pollAttempts >= maxPollAttempts) {
                    binding.swipeRefresh.isRefreshing = false
                    binding.statusText.text = getString(R.string.status_timeout)
                    Snackbar.make(binding.root, R.string.error_server_timeout, Snackbar.LENGTH_LONG).show()
                } else {
                    handler.postDelayed({ waitForServer() }, pollIntervalMs)
                }
            }
        }
    }

    private fun isServerAvailable(): Boolean {
        return try {
            val connection = URL(localUrl).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 1000
            connection.readTimeout = 1000
            connection.instanceFollowRedirects = true
            connection.connect()
            connection.responseCode in 200..399
        } catch (_: IOException) {
            false
        }
    }

    private fun showPermissionHelp() {
        AlertDialog.Builder(this)
            .setTitle(R.string.permission_title)
            .setMessage(R.string.permission_message)
            .setPositiveButton(R.string.open_termux) { _, _ -> openTermux() }
            .setNegativeButton(android.R.string.ok, null)
            .show()
    }

    private fun showTermuxMissingDialog() {
        AlertDialog.Builder(this)
            .setTitle(R.string.termux_missing_title)
            .setMessage(R.string.termux_missing_message)
            .setPositiveButton(R.string.open_termux_page) { _, _ ->
                val uri = Uri.parse("https://github.com/termux/termux-app/releases")
                startActivity(Intent(Intent.ACTION_VIEW, uri))
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun openTermux() {
        val launchIntent = packageManager.getLaunchIntentForPackage("com.termux")
        if (launchIntent != null) {
            startActivity(launchIntent)
            return
        }

        startActivity(Intent(Settings.ACTION_SETTINGS))
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        executor.shutdownNow()
        binding.webView.destroy()
        super.onDestroy()
    }
}
