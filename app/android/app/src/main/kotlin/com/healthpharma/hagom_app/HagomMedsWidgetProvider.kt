package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMedsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_meds_widget).apply {
                val tag = widgetData.getString("meds_tag", "다음 복약")
                val progress = widgetData.getString("meds_progress", "2/3 완료")
                val title = widgetData.getString("meds_title", "Focusin 10mg")
                val subtitle = widgetData.getString("meds_subtitle", "오후 12:30 · 식후 복용")
                val extra = widgetData.getString("meds_extra", "처방약 (시간 엄수)")
                val btnTitle = widgetData.getString("meds_btn_title", "복용")
                val btnSubtitle = widgetData.getString("meds_btn_subtitle", "1-Tap")

                setTextViewText(R.id.widget_meds_tag, tag)
                setTextViewText(R.id.widget_meds_progress, progress)
                setTextViewText(R.id.widget_meds_title, title)
                setTextViewText(R.id.widget_meds_subtitle, subtitle)
                setTextViewText(R.id.widget_meds_extra, extra)
                setTextViewText(R.id.widget_meds_btn_title, btnTitle)
                setTextViewText(R.id.widget_meds_btn_subtitle, btnSubtitle)

                // 1) 좌측 본문 터치 시: 하곰이 앱 열기
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget", "meds")
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    101,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_meds_container, openAppPendingIntent)

                // 2) 우측 [복용] 버튼 터치 시: 앱 실행 없이 즉시 복약 체크되는 백그라운드 인텐트!
                val bgCheckIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("hagomWidget://checkMed")
                )
                setOnClickPendingIntent(R.id.widget_meds_btn, bgCheckIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
