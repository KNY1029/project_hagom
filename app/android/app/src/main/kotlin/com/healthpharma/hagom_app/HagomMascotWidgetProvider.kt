package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMascotWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val targetIds = if (appWidgetIds.isNotEmpty()) {
            appWidgetIds
        } else {
            appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, HagomMascotWidgetProvider::class.java)
            )
        }

        for (appWidgetId in targetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_mascot_widget).apply {
                val badge = widgetData.getString("mascot_badge", "1. 기대")
                val quote = widgetData.getString("mascot_quote", "유저가 접속해서 기록을 이어갈 것이라 믿고 웃어주는 모습")
                val sub = widgetData.getString("mascot_sub", "비처벌적 푸시")
                val imageName = widgetData.getString("mascot_image", "hagom_widget_stage_1")

                setTextViewText(R.id.widget_mascot_badge, badge)
                setTextViewText(R.id.widget_mascot_quote, quote)
                setTextViewText(R.id.widget_mascot_sub, sub)

                val imageRes = when (imageName) {
                    "hagom_widget_stage_1" -> R.drawable.hagom_widget_stage_1
                    "hagom_widget_stage_2" -> R.drawable.hagom_widget_stage_2
                    "hagom_widget_stage_3" -> R.drawable.hagom_widget_stage_3
                    "hagom_widget_stage_4" -> R.drawable.hagom_widget_stage_4
                    "hagom_widget_stage_5" -> R.drawable.hagom_widget_stage_5
                    "hagom_widget_stage_6" -> R.drawable.hagom_widget_stage_6
                    "hagom_widget_stage_7" -> R.drawable.hagom_widget_stage_7
                    "hagom_widget_stage_8" -> R.drawable.hagom_widget_stage_8
                    "hagom_widget_stage_9" -> R.drawable.hagom_widget_stage_9
                    else -> R.drawable.hagom_widget_stage_1
                }
                setImageViewResource(R.id.widget_mascot_img, imageRes)

                // 🌟 위젯 터치 시 백그라운드로 다음 단계(1~9단계 순환)로 즉시 전환!
                setOnClickPendingIntent(
                    R.id.widget_mascot_container,
                    WidgetBindings.actionIntent(context, "hagomwidget://next_mascot_stage", 5001)
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
