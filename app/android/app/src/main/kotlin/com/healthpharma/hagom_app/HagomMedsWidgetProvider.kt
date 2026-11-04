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

                if (btnTitle == "완료" || progress.contains("3/3")) {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.parseColor("#1B6B46"))
                } else {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.WHITE)
                }

                // 1) 바탕 터치 시: 복약 탭(0번)으로 직행
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openMeds")
                )
                setOnClickPendingIntent(R.id.widget_meds_container, openAppPendingIntent)

                // 2) 메인 우측 복용 버튼 터치 시 브로드캐스트
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

                // 3) 🌟 세로 확장 시 나타나는 작은 슬롯 버튼들 상태 렌더링 & 개별 인텐트 연결!
                val slot2Done = widgetData.getBoolean("med_slot_2_done", false)
                val slot3Done = widgetData.getBoolean("med_slot_3_done", false)

                if (slot2Done) {
                    setTextViewText(R.id.med_slot_2_btn, "완료")
                    setInt(R.id.med_slot_2_btn, "setBackgroundResource", R.drawable.hagom_widget_done_bg)
                    setTextColor(R.id.med_slot_2_btn, Color.parseColor("#044E36"))
                } else {
                    setTextViewText(R.id.med_slot_2_btn, "복용")
                    setInt(R.id.med_slot_2_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.med_slot_2_btn, Color.WHITE)
                }

                if (slot3Done) {
                    setTextViewText(R.id.med_slot_3_btn, "완료")
                    setInt(R.id.med_slot_3_btn, "setBackgroundResource", R.drawable.hagom_widget_done_bg)
                    setTextColor(R.id.med_slot_3_btn, Color.parseColor("#044E36"))
                } else {
                    setTextViewText(R.id.med_slot_3_btn, "복용")
                    setInt(R.id.med_slot_3_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.med_slot_3_btn, Color.WHITE)
                }

                val slot2Intent = PendingIntent.getBroadcast(
                    context,
                    204,
                    Intent(context, WidgetActionReceiver::class.java).apply {
                        action = "ACTION_CHECK_MED_SLOT"
                        putExtra("slot_index", 2)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.med_slot_2_btn, slot2Intent)

                val slot3Intent = PendingIntent.getBroadcast(
                    context,
                    205,
                    Intent(context, WidgetActionReceiver::class.java).apply {
                        action = "ACTION_CHECK_MED_SLOT"
                        putExtra("slot_index", 3)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.med_slot_3_btn, slot3Intent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
