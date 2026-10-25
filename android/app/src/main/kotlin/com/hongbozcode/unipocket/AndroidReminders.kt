package com.hongbozcode.unipocket

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONObject

/** Small OS adapter. SQLite remains authoritative; this is the alarm delivery cache. */
class AndroidReminders(private val context: Context) {
    private val preferences = context.getSharedPreferences("local_reminders", Context.MODE_PRIVATE)
    private val alarms = context.getSystemService(AlarmManager::class.java)
    private val notifications = context.getSystemService(NotificationManager::class.java)

    init {
      if (Build.VERSION.SDK_INT >= 26) {
        notifications.createNotificationChannel(NotificationChannel(
            CHANNEL, "学习提醒", NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = "学习任务等校园安排的本地提醒" })
      }
    }

    fun enabled(): Boolean = notifications.areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 26 ||
            notifications.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)

    private fun read(): JSONObject = JSONObject(preferences.getString("pending", "{}")!!)

    private fun write(data: JSONObject) {
        check(preferences.edit().putString("pending", data.toString()).commit()) {
            "无法保存系统提醒缓存"
        }
    }

    private fun operation(key: String): PendingIntent = PendingIntent.getBroadcast(
        context, 0, Intent(context, ReminderReceiver::class.java)
            .setData(Uri.parse("unipocket://reminders/" + Uri.encode(key))),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private fun cancel(key: String) {
        val pending = operation(key)
        alarms.cancel(pending)
        pending.cancel()
        notifications.cancel(key, 0)
    }

    private fun schedule(key: String, item: JSONObject) {
        val at = item.getLong("at")
        if (at > System.currentTimeMillis() && enabled()) {
            // Calendar notifications may run during Doze; Android may batch/delay them.
            // No special exact-alarm access is required or requested.
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation(key))
        }
    }

    fun replace(scope: String, reminders: List<Map<String, Any>>) {
        val data = read()
        val incoming = JSONObject()
        for (reminder in reminders) {
            val item = JSONObject(reminder).put("scope", scope)
            if (item.getLong("at") > System.currentTimeMillis()) {
                incoming.put("$scope/${item.getString("key")}", item)
            }
        }
        val oldKeys = data.keys().asSequence().toList()
        for (key in oldKeys) {
            if (data.getJSONObject(key).getString("scope") == scope && !incoming.has(key)) {
                cancel(key)
                data.remove(key)
            }
        }
        val changed = mutableListOf<String>()
        for (key in incoming.keys()) {
            val item = incoming.getJSONObject(key)
            val previous = data.optJSONObject(key)
            if (previous == null || previous.getLong("at") != item.getLong("at") ||
                previous.getString("title") != item.getString("title") ||
                previous.getString("body") != item.getString("body")) {
                cancel(key)
            }
            data.put(key, item)
            changed.add(key)
        }
        write(data)
        // Re-arming identical pending intents is idempotent and also repairs a previous
        // partial platform failure. No delivered/past item is ever re-armed.
        for (key in changed) schedule(key, data.getJSONObject(key))
    }

    fun restore() {
        val data = read()
        for (key in data.keys().asSequence().toList()) {
            if (data.getJSONObject(key).getLong("at") <= System.currentTimeMillis()) {
                cancel(key)
                data.remove(key)
            } else schedule(key, data.getJSONObject(key))
        }
        write(data)
    }

    fun deliver(key: String) {
        val data = read()
        val item = data.optJSONObject(key) ?: return
        // A cancelled/edited alarm can race with its receiver. Never deliver the old payload.
        if (item.getLong("at") > System.currentTimeMillis()) return
        data.remove(key)
        write(data)
        if (!enabled()) return
        val launch = PendingIntent.getActivity(context, 0,
            Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL)
            else Notification.Builder(context).setDefaults(Notification.DEFAULT_ALL)
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_reminder)
            .setContentTitle(item.getString("title"))
            .setContentText(item.getString("body"))
            .setStyle(Notification.BigTextStyle().bigText(item.getString("body")))
            .setContentIntent(launch).setAutoCancel(true).build()
        notifications.notify(key, 0, notification)
    }

    companion object { const val CHANNEL = "learning_reminders" }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = intent.data?.lastPathSegment ?: return
        AndroidReminders(context).deliver(key)
    }
}

class ReminderRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AndroidReminders(context).restore()
    }
}
