package com.hongbozcode.unipocket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.os.Build
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.app.Activity
import android.provider.OpenableColumns
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private var schoolFileResult: MethodChannel.Result? = null
    private val fileReader = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unipocket/school-file")
            .setMethodCallHandler { call, result ->
                if (call.method != "pick") {
                    result.notImplemented()
                } else if (schoolFileResult != null) {
                    result.error("picker_busy", "文件选择正在进行", null)
                } else {
                    schoolFileResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                "application/octet-stream"))
                        }
                        startActivityForResult(intent, 71)
                    } catch (e: Exception) {
                        schoolFileResult = null
                        result.error("picker_unavailable", "无法打开文件选择器", null)
                    }
                }
            }
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

    @Deprecated("Android activity result callback used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 71) return
        val pending = schoolFileResult ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            schoolFileResult = null
            pending.success(null)
            return
        }
        fileReader.execute {
            try {
                var name = "课表.xlsx"
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                    if (it.moveToFirst()) name = it.getString(0) ?: name
                }
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    var count = input.read(buffer)
                    while (count != -1) {
                        if (output.size() + count > 10 * 1024 * 1024) {
                            throw IllegalArgumentException("file_too_large")
                        }
                        output.write(buffer, 0, count)
                        count = input.read(buffer)
                    }
                    output.toByteArray()
                } ?: throw java.io.IOException("unreadable")
                runOnUiThread {
                    if (schoolFileResult !== pending) return@runOnUiThread
                    schoolFileResult = null
                    pending.success(mapOf("name" to name, "bytes" to bytes))
                }
            } catch (e: Exception) {
                runOnUiThread {
                    if (schoolFileResult !== pending) return@runOnUiThread
                    schoolFileResult = null
                    pending.error(if (e.message == "file_too_large") "file_too_large" else "file_unreadable",
                        "无法读取课表文件", null)
                }
            }
        }
    }

    override fun onDestroy() {
        schoolFileResult?.error("picker_closed", "文件选择已关闭", null)
        schoolFileResult = null
        fileReader.shutdown()
        super.onDestroy()
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
