package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
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
                val tag = widgetData.getString("meds_tag", "다음 복약") ?: "다음 복약"
                val progress = widgetData.getString("meds_progress", "2/3 완료") ?: "2/3 완료"
                val title = widgetData.getString("meds_title", "Focusin 10mg") ?: "Focusin 10mg"
                val subtitle = widgetData.getString("meds_subtitle", "오후 12:30 · 식후 복용") ?: "오후 12:30 · 식후 복용"
                val btnTitle = widgetData.getString("meds_btn_title", "복용") ?: "복용"

                setTextViewText(R.id.widget_meds_tag, tag)
                setTextViewText(R.id.widget_meds_progress, progress)
                setTextViewText(R.id.widget_meds_title, title)
                setTextViewText(R.id.widget_meds_subtitle, subtitle)
                setTextViewText(R.id.widget_meds_btn_title, btnTitle)

                // 🌟 복약 버튼 색상 앱과 100% 동일하게 분기:
                // - 미복용/대기 중: 하곰이 브랜드 라벤더 퍼플 (#7B61A8) + 흰색 글자
                // - 전체 완료 (3/3): 소프트 민트초록 (#EAF8F1) + 딥그린 글자 (#1B6B46)
                if (btnTitle == "완료" || progress.contains("3/3")) {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.parseColor("#1B6B46"))
                } else {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.WHITE)
                }

                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openMeds")
                )
                setOnClickPendingIntent(R.id.widget_meds_container, openAppPendingIntent)

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
