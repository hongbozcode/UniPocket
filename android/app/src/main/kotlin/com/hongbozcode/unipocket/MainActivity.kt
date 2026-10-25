package com.hongbozcode.unipocket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.os.Build
import android.content.Intent
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unipocket/notifications")
            .setMethodCallHandler { call, result ->
                try {
                    val reminders = AndroidReminders(this)
                    when (call.method) {
                        "enabled" -> result.success(reminders.enabled())
                        "replace" -> {
                            reminders.replace(call.argument<String>("scope")!!,
                                call.argument<List<Map<String, Any>>>("reminders")!!)
                            result.success(null)
                        }
                        "requestPermission" -> {
                            if (Build.VERSION.SDK_INT >= 33 && !reminders.enabled()) {
                                if (permissionResult != null) {
                                    result.error("permission_busy", "权限请求正在进行", null)
                                } else {
                                    permissionResult = result
                                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 70)
                                }
                            } else result.success(null)
                        }
                        "openSettings" -> {
                            val settings = if (Build.VERSION.SDK_INT >= 26)
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName"))
                            startActivity(settings)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("notifications_unavailable", e.message, null)
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>,
        grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 70) {
            permissionResult?.success(null)
            permissionResult = null
        }
    }
}
