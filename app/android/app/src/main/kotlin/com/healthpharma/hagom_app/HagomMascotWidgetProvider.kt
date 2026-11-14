package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMascotWidgetProvider : HomeWidgetProvider() {

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), es.antonborri.home_widget.HomeWidgetPlugin.getData(context))
    }

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
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val is1x1 = (minW in 1..125) // 1x1 크기 판정 (갤럭시 S25+ 및 고해상도 런처 125dp 이하 포용)
            val imageName = widgetData.getString("mascot_image", "hagom_widget_stage_1")
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

            val views = if (is1x1) {
                // 🌟 1x1 모드: 앱 아이콘 느낌으로 꽉 찬 하곰이 캐릭터 노출 & 터치 시 앱 메인 열기
                RemoteViews(context.packageName, R.layout.hagom_mascot_widget_1x1).apply {
                    setImageViewResource(R.id.widget_mascot_img_1x1, imageRes)
                    setOnClickPendingIntent(
                        R.id.widget_mascot_container_1x1,
                        WidgetBindings.openAppIntent(context, "hagomwidget://openroom", 5002)
                    )
                }
            } else {
                // 🌟 3x1 기본 모드: 캐릭터 + 3단 응원 대사 + 탭하여 다음 표정 전환
                RemoteViews(context.packageName, R.layout.hagom_mascot_widget).apply {
                    val badge = widgetData.getString("mascot_badge", "1. 기대")
                    val quote = widgetData.getString("mascot_quote", "유저가 접속해서 기록을 이어갈 것이라 믿고 웃어주는 모습")
                    val sub = widgetData.getString("mascot_sub", "비처벌적 푸시")

                    setTextViewText(R.id.widget_mascot_badge, badge)
                    setTextViewText(R.id.widget_mascot_quote, quote)
                    setTextViewText(R.id.widget_mascot_sub, sub)
                    setImageViewResource(R.id.widget_mascot_img, imageRes)

                    setOnClickPendingIntent(
                        R.id.widget_mascot_container,
                        WidgetBindings.actionIntent(context, "hagomwidget://next_mascot_stage", 5001)
                    )
                }
            }
            WidgetBindings.applyTheme(
                views, widgetData, if (is1x1) R.id.widget_mascot_container_1x1 else R.id.widget_mascot_container,
                listOf(R.id.widget_mascot_quote, R.id.widget_mascot_sub)
            )
            if (!is1x1) {
                views.setInt(
                    R.id.widget_mascot_badge,
                    "setBackgroundResource",
                    if (widgetData.getString("theme_dark", "false") == "true")
                        R.drawable.hagom_widget_tag_bg_dark
                    else R.drawable.hagom_widget_tag_bg
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
