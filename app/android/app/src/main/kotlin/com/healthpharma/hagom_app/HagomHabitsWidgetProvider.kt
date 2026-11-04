package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomHabitsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                val tag = widgetData.getString("habits_tag", "오늘의 습관")
                val progress = widgetData.getString("habits_progress", "2/3 실천 중")
                val title = widgetData.getString("habits_title", "물 한 컵 마시기")
                val subtitle = widgetData.getString("habits_subtitle", "언제든 자유롭게 · 1컵")
                val extra = widgetData.getString("habits_extra", "오늘의 작은 발걸음")
                val btnTitle = widgetData.getString("habits_btn_title", "실천")
                val btnSubtitle = widgetData.getString("habits_btn_subtitle", "1-Tap")

                setTextViewText(R.id.widget_habits_tag, tag)
                setTextViewText(R.id.widget_habits_progress, progress)
                setTextViewText(R.id.widget_habits_title, title)
                setTextViewText(R.id.widget_habits_subtitle, subtitle)
                setTextViewText(R.id.widget_habits_extra, extra)
                setTextViewText(R.id.widget_habits_btn_title, btnTitle)
                setTextViewText(R.id.widget_habits_btn_subtitle, btnSubtitle)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
