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
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_mascot_widget).apply {
                val badge = widgetData.getString("mascot_badge", "하곰이의 응원")
                val quote = widgetData.getString("mascot_quote", "한 가지만 실천해도 충분해요.\n오늘 약 하나만 챙겨도 대단한 거예요.")
                val sub = widgetData.getString("mascot_sub", "천천히 편안한 속도로 가요")

                setTextViewText(R.id.widget_mascot_badge, badge)
                setTextViewText(R.id.widget_mascot_quote, quote)
                setTextViewText(R.id.widget_mascot_sub, sub)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
