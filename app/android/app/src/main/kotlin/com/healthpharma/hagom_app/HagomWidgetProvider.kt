package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_widget_2x1).apply {
                val tag = widgetData.getString("widget_tag", "다음 복약")
                val progress = widgetData.getString("widget_progress", "2/3 완료")
                val title = widgetData.getString("widget_title", "Focusin 10mg")
                val subtitle = widgetData.getString("widget_subtitle", "오후 12:30 · 식후 30분 복용")
                val extra = widgetData.getString("widget_extra", "처방약 (시간 엄수)")
                val btnTitle = widgetData.getString("widget_btn_title", "복용")
                val btnSubtitle = widgetData.getString("widget_btn_subtitle", "1-Tap")

                setTextViewText(R.id.widget_tag, tag)
                setTextViewText(R.id.widget_progress, progress)
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_subtitle, subtitle)
                setTextViewText(R.id.widget_extra, extra)
                setTextViewText(R.id.widget_btn_title, btnTitle)
                setTextViewText(R.id.widget_btn_subtitle, btnSubtitle)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
