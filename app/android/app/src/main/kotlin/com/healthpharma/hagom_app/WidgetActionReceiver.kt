package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import org.json.JSONArray

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        when {
            action == "ACTION_CHECK_MED" || action == "ACTION_CHECK_MED_SLOT" -> {
                val slotIdx = intent.getIntExtra("slot_index", -1)

                // 1) 특정 슬롯 상태 토글 또는 다음 슬롯 진행
                val slot2Done = homePrefs.getBoolean("med_slot_2_done", false)
                val slot3Done = homePrefs.getBoolean("med_slot_3_done", false)

                val (newSlot2, newSlot3) = when (slotIdx) {
                    2 -> Pair(!slot2Done, slot3Done)
                    3 -> Pair(slot2Done, !slot3Done)
                    else -> {
                        // 메인 복용 버튼
                        if (!slot2Done) Pair(true, slot3Done)
                        else Pair(slot2Done, true)
                    }
                }

                val completedCount = 1 + (if (newSlot2) 1 else 0) + (if (newSlot3) 1 else 0)
                val nextProgress = "$completedCount/3 완료"
                val nextBtn = if (completedCount >= 3) "완료" else "복용"
                val nextSub = if (completedCount >= 3) "오늘의 모든 복약 완료!" else (if (!newSlot2) "오후 12:30 · 식후 복용" else "오후 7:00 · 식후 복용")

                homePrefs.edit()
                    .putBoolean("med_slot_2_done", newSlot2)
                    .putBoolean("med_slot_3_done", newSlot3)
                    .putString("meds_progress", nextProgress)
                    .putString("meds_subtitle", nextSub)
                    .putString("meds_btn_title", nextBtn)
                    .apply()

                updateFlutterMedSlot(flutterPrefs)

                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomMedsWidgetProvider::class.java))
                val provider = HagomMedsWidgetProvider()
                provider.onUpdate(context, appWidgetManager, ids, homePrefs)
            }

            action == "ACTION_CHECK_HABIT" || action == "ACTION_CHECK_HABIT_SLOT" -> {
                val habitIdx = intent.getIntExtra("habit_index", -1)

                val habit1Done = homePrefs.getBoolean("habit_slot_1_done", false)
                val habit4Done = homePrefs.getBoolean("habit_slot_4_done", false)

                val (newH1, newH4) = when (habitIdx) {
                    1 -> Pair(!habit1Done, habit4Done)
                    4 -> Pair(habit1Done, !habit4Done)
                    else -> {
                        if (!habit1Done) Pair(true, habit4Done)
                        else Pair(habit1Done, true)
                    }
                }

                val completedCount = 2 + (if (newH1) 1 else 0) + (if (newH4) 1 else 0)
                val nextProgress = "$completedCount/4 실천 중"
                val nextBtn = if (completedCount >= 4) "완료" else "실천"

                homePrefs.edit()
                    .putBoolean("habit_slot_1_done", newH1)
                    .putBoolean("habit_slot_4_done", newH4)
                    .putString("habits_progress", nextProgress)
                    .putString("habits_btn_title", nextBtn)
                    .apply()

                updateFlutterHabit(flutterPrefs)

                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomHabitsWidgetProvider::class.java))
                val provider = HagomHabitsWidgetProvider()
                provider.onUpdate(context, appWidgetManager, ids, homePrefs)
            }

            action == "ACTION_CHECK_TASK" || action == "ACTION_CHECK_TASK_SLOT" -> {
                val taskIdx = intent.getIntExtra("task_index", -1)

                val task1Done = homePrefs.getBoolean("task_slot_1_done", false)
                val task2Done = homePrefs.getBoolean("task_slot_2_done", false)

                val (newT1, newT2) = when (taskIdx) {
                    1 -> Pair(!task1Done, task2Done)
                    2 -> Pair(task1Done, !task2Done)
                    else -> {
                        if (!task1Done) Pair(true, task2Done)
                        else Pair(task1Done, true)
                    }
                }

                val completedCount = (if (newT1) 1 else 0) + (if (newT2) 1 else 0)
                val nextBtn = if (completedCount >= 2) "완료" else "체크"

                homePrefs.edit()
                    .putBoolean("task_slot_1_done", newT1)
                    .putBoolean("task_slot_2_done", newT2)
                    .putString("calendar_btn_title", nextBtn)
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
