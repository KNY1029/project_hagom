package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        when (action) {
            "ACTION_CHECK_MED" -> {
                handleCheckMed(context, prefs)
            }
            "ACTION_CHECK_HABIT" -> {
                handleCheckHabit(context, prefs)
            }
            "ACTION_CHECK_TASK" -> {
                handleCheckTask(context, prefs)
            }
        }
    }

    private fun handleCheckMed(context: Context, prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_medications", null) ?: return
        try {
            val array = JSONArray(rawJson)
            var modified = false

            for (i in 0 until array.length()) {
                val med = array.getJSONObject(i)
                val slots = med.getJSONArray("doseSlots")
                for (j in 0 until slots.length()) {
                    val slot = slots.getJSONObject(j)
                    val isDone = slot.optBoolean("isCompleted", false)
                    val isSkip = slot.optBoolean("isSkipped", false)
                    if (!isDone && !isSkip) {
                        slot.put("isCompleted", true)
                        slot.put("takenTime", "방금 복용")
                        modified = true
                        break
                    }
                }
                if (modified) break
            }

            if (modified) {
                prefs.edit().putString("flutter.hagom_medications", array.toString()).apply()
                // 위젯 갱신 브로드캐스트
                val updateIntent = Intent(context, HagomMedsWidgetProvider::class.java).apply {
                    this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomMedsWidgetProvider::class.java))
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(updateIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleCheckHabit(context: Context, prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_habits", null) ?: return
        try {
            val array = JSONArray(rawJson)
            if (array.length() > 0) {
                val habit = array.getJSONObject(0)
                val cur = habit.optInt("currentCount", 0)
                val target = habit.optInt("targetPerDay", 1)
                habit.put("currentCount", (cur + 1).coerceAtMost(target))

                prefs.edit().putString("flutter.hagom_habits", array.toString()).apply()

                val updateIntent = Intent(context, HagomHabitsWidgetProvider::class.java).apply {
                    this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomHabitsWidgetProvider::class.java))
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(updateIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleCheckTask(context: Context, prefs: android.content.SharedPreferences) {
        val rawJson = prefs.getString("flutter.hagom_tasks", null) ?: return
        try {
            val array = JSONArray(rawJson)
            if (array.length() > 0) {
                val task = array.getJSONObject(0)
                val curDone = task.optBoolean("isCompleted", false)
                task.put("isCompleted", !curDone)

                prefs.edit().putString("flutter.hagom_tasks", array.toString()).apply()

                val updateIntent = Intent(context, HagomCalendarWidgetProvider::class.java).apply {
                    this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, HagomCalendarWidgetProvider::class.java))
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(updateIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
