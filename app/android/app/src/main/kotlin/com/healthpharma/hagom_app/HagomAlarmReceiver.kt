package com.healthpharma.hagom_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class HagomAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TRIGGER) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
            android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            HagomAlarmScheduler.rescheduleAll(context)
            return
        }

        val notificationManager = context.getSystemService(NotificationManager::class.java)
        val channelId = CHANNEL_ID
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.createNotificationChannel(
                NotificationChannel(channelId, "하곰이 알림", NotificationManager.IMPORTANCE_HIGH)
            )
        }

        val title = intent.getStringExtra("title") ?: "하곰이 알림"
        val message = intent.getStringExtra("message") ?: "실천할 시간이에요!"
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
        }

        builder
            .setSmallIcon(R.drawable.hagom_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)

        notificationManager.notify(intent.getIntExtra("notiId", 0), builder.build())

        // AlarmManager alarms are one-shot. Restore the saved schedule after each
        // reminder so incomplete daily/weekly items keep notifying.
        HagomAlarmScheduler.rescheduleAll(context)
    }

    companion object {
        const val ACTION_TRIGGER = "com.healthpharma.hagom_app.ACTION_ALARM_TRIGGER"
        private const val CHANNEL_ID = "hagom_scheduled_notifications"
    }
}
