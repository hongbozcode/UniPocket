package com.hongbozcode.unipocket

import android.app.Activity
import android.content.Intent
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/** User-selected documents only. No storage permission or upload path. */
class BackupDocuments(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val limit = 50 * 1024 * 1024

    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (call.method != "pick" && call.method != "save") {
            result.notImplemented()
            return
        }
        if (pending != null) {
            result.error("picker_busy", "文件操作正在进行", null)
            return
        }
        try {
            val saving = call.method == "save"
            val bytes = if (saving) call.argument<ByteArray>("bytes") else null
            if (saving && (bytes == null || bytes.isEmpty() || bytes.size > limit)) {
                result.error("invalid_backup", "备份为空或超过 50 MB", null)
                return
            }
            val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = if (saving) "application/octet-stream" else "*/*"
                if (saving) putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
            }
            pending = result
            exportBytes = bytes
            activity.startActivityForResult(intent, 72)
        } catch (e: Exception) {
            pending = null
            exportBytes = null
            result.error("picker_unavailable", "无法打开系统文件选择器", null)
        }
    }

    fun onResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != 72) return
        val result = pending ?: return
        val bytes = exportBytes
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            exportBytes = null
            result.success(if (bytes == null) null else false)
            return
        }
        worker.execute {
            try {
                val response: Any = if (bytes != null) {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use {
                        it.write(bytes)
                        it.flush()
                    } ?: throw java.io.IOException("unwritable")
                    true
                } else {
                    var name = "UniPocket 备份"
                    activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                        if (it.moveToFirst()) name = it.getString(0) ?: name
                    }
                    val contents = activity.contentResolver.openInputStream(uri)?.use { input ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        var count = input.read(buffer)
                        while (count != -1) {
                            if (output.size() + count > limit) throw java.io.IOException("file_too_large")
                            output.write(buffer, 0, count)
                            count = input.read(buffer)
                        }
                        output.toByteArray()
                    } ?: throw java.io.IOException("unreadable")
                    mapOf("name" to name, "bytes" to contents)
                }
                activity.runOnUiThread {
                    if (pending !== result) return@runOnUiThread
                    pending = null
                    exportBytes = null
                    result.success(response)
                }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    if (pending !== result) return@runOnUiThread
                    pending = null
                    exportBytes = null
                    result.error("file_operation_failed", "无法完成备份文件操作", null)
                }
            }
        }
    }

    fun close() {
        pending?.error("picker_closed", "文件操作已关闭，请重试", null)
        pending = null
        exportBytes = null
        worker.shutdown()
    }
}
