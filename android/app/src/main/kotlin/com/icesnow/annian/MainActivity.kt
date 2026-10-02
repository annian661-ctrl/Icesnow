package com.icesnow.annian

import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.icesnow.annian/cookies"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCookies" -> {
                        val url = call.argument<String>("url") ?: ""
                        try {
                            val cookieManager = CookieManager.getInstance()
                            val cookies = cookieManager.getCookie(url) ?: ""
                            result.success(cookies)
                        } catch (e: Exception) {
                            result.success("")
                        }
                    }
                    "getCookiesForUrls" -> {
                        val urls = call.argument<List<String>>("urls") ?: emptyList()
                        try {
                            val cookieManager = CookieManager.getInstance()
                            val map = mutableMapOf<String, String>()
                            for (url in urls) {
                                val c = cookieManager.getCookie(url) ?: ""
                                if (c.isNotEmpty()) {
                                    for (kv in c.split(";")) {
                                        val trimmed = kv.trim()
                                        val eq = trimmed.indexOf("=")
                                        if (eq > 0) {
                                            val name = trimmed.substring(0, eq)
                                            if (!map.containsKey(name)) {
                                                map[name] = trimmed.substring(eq + 1)
                                            }
                                        }
                                    }
                                }
                            }
                            val resultStr = map.entries.joinToString("; ") { "${it.key}=${it.value}" }
                            result.success(resultStr)
                        } catch (e: Exception) {
                            result.success("")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
