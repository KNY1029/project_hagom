package com.healthpharma.hagom_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class HagomAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID_ESSENTIAL = "hagom_essential_channel"
        const val CHANNEL_ID_TALK = "hagom_talk_channel"
        const val ACTION_TRIGGER = "com.healthpharma.hagom_app.ACTION_ALARM_TRIGGER"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // 부팅 완료 시 알림 재등록 요청
            HagomAlarmScheduler.rescheduleAll(context)
            return
        }

        val type = intent.getStringExtra("type") ?: "essential"
        val title = intent.getStringExtra("title") ?: "하곰이 알림"
        val message = intent.getStringExtra("message") ?: "실천할 시간이에요!"
        val notiId = intent.getIntExtra("notiId", (System.currentTimeMillis() % 100000).toInt())
        val isEssential = intent.getBooleanExtra("isEssential", false)

        sendNotification(context, notiId, title, message, isEssential)
    }

    private fun sendNotification(context: Context, notiId: Int, title: String, message: String, isEssential: Boolean) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channelId = if (isEssential) CHANNEL_ID_ESSENTIAL else CHANNEL_ID_TALK
        val channelName = if (isEssential) "하곰이 필수 실천 알림" else "하곰이 일상 & 토크 알림"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = if (isEssential) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = if (isEssential) "정해진 복약 및 습관 실천 정시 안내" else "하곰이의 다정한 안부 및 일상 대화"
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            notiId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            Notification.Builder(context)
                .setPriority(if (isEssential) Notification.PRIORITY_HIGH else Notification.PRIORITY_DEFAULT)
        }

        builder
            .setSmallIcon(R.drawable.hagom_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        manager.notify(notiId, builder.build())
    }
}
