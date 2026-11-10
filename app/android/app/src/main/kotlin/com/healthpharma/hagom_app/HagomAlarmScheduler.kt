package com.healthpharma.hagom_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object HagomAlarmScheduler {

    fun scheduleAlarmsFromJson(context: Context, schedulesJson: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val prefs = context.getSharedPreferences("HagomAlarmPrefs", Context.MODE_PRIVATE)
        prefs.edit().putString("last_schedules_json", schedulesJson).apply()

        try {
            val arr = JSONArray(schedulesJson)
            for (i in 0 until arr.length()) {
                val item = arr.getJSONObject(i)
                val id = item.getInt("id")
                val hour = item.getInt("hour")
                val minute = item.getInt("minute")
                val title = item.optString("title", "하곰이 알림")
                val message = item.optString("message", "실천할 시간이에요!")
                val isEssential = item.optBoolean("isEssential", false)
                val repeatDays = item.optJSONArray("repeatDays") // e.g. [1, 2, 3...] 1=일요일

                val targetDays = mutableListOf<Int>()
                if (repeatDays != null && repeatDays.length() > 0) {
                    for (dIdx in 0 until repeatDays.length()) {
                        targetDays.add(repeatDays.getInt(dIdx))
                    }
                }

                if (targetDays.isEmpty()) {
                    // 특정 요일 지정이 없으면 매일 울림
                    scheduleSingleAlarm(context, am, id, hour, minute, -1, title, message, isEssential)
                } else {
                    // 지정된 특정 요일(예: 1=일요일)에만 정확히 알림 등록!
                    for ((index, dayOfWeek) in targetDays.withIndex()) {
                        val subId = id * 10 + index
                        scheduleSingleAlarm(context, am, subId, hour, minute, dayOfWeek, title, message, isEssential)
                    }
                }
            }
        } catch (_: Exception) {}
    }

    private fun scheduleSingleAlarm(
        context: Context,
        am: AlarmManager,
        alarmId: Int,
        hour: Int,
        minute: Int,
        targetDayOfWeek: Int, // Calendar.SUNDAY(1) ~ Calendar.SATURDAY(7), 또는 -1 (매일)
        title: String,
        message: String,
        isEssential: Boolean
    ) {
        val intent = Intent(context, HagomAlarmReceiver::class.java).apply {
            action = HagomAlarmReceiver.ACTION_TRIGGER
            putExtra("notiId", alarmId)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("isEssential", isEssential)
        }

        val pi = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)

            if (targetDayOfWeek in Calendar.SUNDAY..Calendar.SATURDAY) {
                // 🌟 [특정 요일 전용 정밀 계산]: 오늘부터 가장 가까운 해당 요일로 점프!
                var daysUntil = (targetDayOfWeek - get(Calendar.DAY_OF_WEEK) + 7) % 7
                if (daysUntil == 0 && timeInMillis <= System.currentTimeMillis()) {
                    daysUntil = 7 // 오늘이 해당 요일이지만 시간이 이미 지났다면 7일 뒤(다음 주 해당 요일)
                }
                add(Calendar.DAY_OF_YEAR, daysUntil)
            } else {
                // 매일 울림
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
        }
    }

    fun rescheduleAll(context: Context) {
        val prefs = context.getSharedPreferences("HagomAlarmPrefs", Context.MODE_PRIVATE)
        val json = prefs.getString("last_schedules_json", null) ?: return
        scheduleAlarmsFromJson(context, json)
    }
}
