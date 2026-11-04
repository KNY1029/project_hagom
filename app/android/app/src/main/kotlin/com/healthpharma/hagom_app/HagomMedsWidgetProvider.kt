package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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
                val btnTitle = widgetData.getString("meds_btn_title", "복용")

                setTextViewText(R.id.widget_meds_tag, tag)
                setTextViewText(R.id.widget_meds_progress, progress)
                setTextViewText(R.id.widget_meds_title, title)
                setTextViewText(R.id.widget_meds_subtitle, subtitle)
                setTextViewText(R.id.widget_meds_btn_title, btnTitle)

                // 1) 좌측 본문 터치 시: 하곰이 복약 탭 열기
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openMeds")
                )
                setOnClickPendingIntent(R.id.widget_meds_container, openAppPendingIntent)

                // 2) 🌟 우측 [복용] 버튼 터치 시: BroadcastReceiver를 통해 즉각 로컬 데이터 갱신 및 위젯 업데이트!
                val checkMedIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = "ACTION_CHECK_MED"
                }
                val checkMedPendingIntent = PendingIntent.getBroadcast(
                    context,
                    201,
                    checkMedIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_meds_btn, checkMedPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
