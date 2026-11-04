package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * 위젯 공통 바인딩 유틸.
 *
 * - 2×N처럼 가로 폭이 좁아지면(minWidth < 210dp) 태그를 숨기고 컴팩트 버튼(46×34dp)으로 전환해
 *   약/습관/할일 이름이 가려지지 않게 한다.
 * - 세로 1칸(minHeight < 105dp)일 때는 확장 목록 전체를 숨기고, 세로 2칸 이상일 때 최대 3개까지 표시한다.
 */
object WidgetBindings {

    fun openAppIntent(context: Context, uri: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HOME_WIDGET_LAUNCH_ACTION
            data = Uri.parse(uri)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun actionIntent(context: Context, uri: String): PendingIntent =
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri))

    fun text(prefs: SharedPreferences, key: String): String = prefs.getString(key, "") ?: ""

    /** 가로 2칸 이하인지 판별 */
    fun isNarrowWidth(appWidgetManager: AppWidgetManager, appWidgetId: Int): Boolean {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        return minW in 1..205
    }

    /** 세로 2칸 이상으로 늘렸는지 판별 */
    fun isVerticallyExpanded(appWidgetManager: AppWidgetManager, appWidgetId: Int): Boolean {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val maxH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 80)
        return maxH >= 135 || minH >= 115
    }

    fun bindRow(
        views: RemoteViews,
        prefs: SharedPreferences,
        context: Context,
        rowId: Int,
        textId: Int,
        btnId: Int,
        textKey: String,
        shortTextKey: String,
        doneKey: String,
        actionKey: String,
        pendingLabel: String,
        pendingBg: Int,
        isNarrow: Boolean
    ) {
        val fullText = text(prefs, textKey)
        val shortText = text(prefs, shortTextKey)
        val display = if (isNarrow && shortText.isNotEmpty()) shortText else fullText
        if (display.isEmpty()) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(textId, display)

        val isDone = prefs.getString(doneKey, "false") == "true"
        if (isDone) {
            views.setTextViewText(btnId, "완료")
            views.setInt(btnId, "setBackgroundResource", R.drawable.hagom_widget_done_bg)
            views.setTextColor(btnId, Color.parseColor("#044E36"))
        } else {
            views.setTextViewText(btnId, pendingLabel)
            views.setInt(btnId, "setBackgroundResource", pendingBg)
            views.setTextColor(btnId, Color.WHITE)
        }

        val action = text(prefs, actionKey)
        if (action.isNotEmpty()) {
            views.setOnClickPendingIntent(btnId, actionIntent(context, action))
        }
    }

    const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
}
