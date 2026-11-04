package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        when (action) {
            "ACTION_CHECK_MED" -> {
                // 1) 위젯 데이터 즉시 업데이트
                val curProgress = homePrefs.getString("meds_progress", "1/3 완료") ?: "1/3 완료"
                val nextProgress = when {
                    curProgress.contains("0/3") -> "1/3 완료"
                    curProgress.contains("1/3") -> "2/3 완료"
                    curProgress.contains("2/3") -> "3/3 완료"
                    else -> "3/3 완료"
                }
                val nextSub = if (nextProgress.contains("3/3")) "오늘의 모든 복약 완료!" else "오후 12:30 · 식후 복용"
                val nextBtn = if (nextProgress.contains("3/3")) "완료" else "복용"

                homePrefs.edit()
                    .putString("meds_progress", nextProgress)
                    .putString("meds_subtitle", nextSub)
                    .putString("meds_btn_title", nextBtn)
                    .apply()

                // Flutter SharedPreferences의 실제 복약 슬롯 데이터도 완료로 업데이트
                updateFlutterMedSlot(flutterPrefs)

                // 화면 즉시 갱신 (onUpdate 호출 강제 트리거)
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomMedsWidgetProvider::class.java))
                val provider = HagomMedsWidgetProvider()
                provider.onUpdate(context, appWidgetManager, ids, homePrefs)
            }

            "ACTION_CHECK_HABIT" -> {
                val curProgress = homePrefs.getString("habits_progress", "2/4 실천 중") ?: "2/4 실천 중"
                val nextProgress = when {
                    curProgress.contains("2/4") -> "3/4 실천 중"
                    curProgress.contains("3/4") -> "4/4 실천 완료"
                    curProgress.contains("4/4") -> "4/4 실천 완료"
                    else -> "3/4 실천 중"
                }
                val nextBtn = if (nextProgress.contains("4/4")) "완료" else "실천"

                homePrefs.edit()
                    .putString("habits_progress", nextProgress)
                    .putString("habits_btn_title", nextBtn)
                    .apply()

                updateFlutterHabit(flutterPrefs)

                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomHabitsWidgetProvider::class.java))
                val provider = HagomHabitsWidgetProvider()
                provider.onUpdate(context, appWidgetManager, ids, homePrefs)
            }

            "ACTION_CHECK_TASK" -> {
                val curBtn = homePrefs.getString("calendar_btn_title", "체크") ?: "체크"
                val nextBtn = if (curBtn == "체크") "완료" else "체크"
                val nextExtra = if (nextBtn == "완료") "상태: 완료됨" else "상태: 진행 대기"

                homePrefs.edit()
                    .putString("calendar_btn_title", nextBtn)
                    .putString("calendar_extra", nextExtra)
                    .apply()

                updateFlutterTask(flutterPrefs)

                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomCalendarWidgetProvider::class.java))
                val provider = HagomCalendarWidgetProvider()
                provider.onUpdate(context, appWidgetManager, ids, homePrefs)
            }
        }
    }

    private fun updateFlutterMedSlot(prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_medications", null) ?: return
        try {
            val array = JSONArray(rawJson)
            for (i in 0 until array.length()) {
                val med = array.getJSONObject(i)
                val slots = med.getJSONArray("doseSlots")
                for (j in 0 until slots.length()) {
                    val slot = slots.getJSONObject(j)
                    if (!slot.optBoolean("isCompleted", false) && !slot.optBoolean("isSkipped", false)) {
                        slot.put("isCompleted", true)
                        slot.put("takenTime", "방금 복용")
                        prefs.edit().putString("flutter.hagom_medications", array.toString()).apply()
                        return
                    }
                }
            }
        } catch (_: Exception) {}
    }

    private fun updateFlutterHabit(prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_habits", null) ?: return
        try {
            val array = JSONArray(rawJson)
            if (array.length() > 0) {
                val habit = array.getJSONObject(0)
                val cur = habit.optInt("currentCount", 0)
                val target = habit.optInt("targetPerDay", 4)
                habit.put("currentCount", (cur + 1).coerceAtMost(target))
                prefs.edit().putString("flutter.hagom_habits", array.toString()).apply()
            }
        } catch (_: Exception) {}
    }

    private fun updateFlutterTask(prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_tasks", null) ?: return
        try {
            val array = JSONArray(rawJson)
            if (array.length() > 0) {
                val task = array.getJSONObject(0)
                val cur = task.optBoolean("isCompleted", false)
                task.put("isCompleted", !cur)
                prefs.edit().putString("flutter.hagom_tasks", array.toString()).apply()
            }
        } catch (_: Exception) {}
    }
}
