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
 * - 현재 위젯의 실제 세로 높이(dp)에서 상단 대표 카드+여백(약 80dp)을 뺀 뒤
 *   한 줄 높이(26dp)로 나누어 '잘리지 않고 온전히 들어가는 최대 줄 수(0~6)'만 표시한다.
 * - 이미 완료된 항목의 버튼을 누르면 취소되지 않고 해당 탭으로 앱만 열린다.
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

    fun isNarrowWidth(appWidgetManager: AppWidgetManager, appWidgetId: Int): Boolean {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        return minW in 1..205
    }

    /**
     * 위젯 세로 높이(dp) 기준으로 잘리지 않고 온전히 들어가는 확장 줄 개수(0~6)를 계산.
     * 상단 대표 행 + 상하 패딩 + 구분선이 약 82dp를 차지하고, 확장 한 줄은 정확히 26dp.
     */
    fun maxFittingRows(appWidgetManager: AppWidgetManager, appWidgetId: Int): Int {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        // 삼성 One UI 런처는 세로 방향에서 minHeight가 실제 셀 높이에 가깝고, 미지정(0)일 때만 기본값 사용
        val effectiveH = when {
            minH > 0 -> minH
            maxH > 0 -> maxH
            else -> 90 // 기본 3x1
        }
        if (effectiveH < 110) return 0
        val availableForRows = effectiveH - 80
        return (availableForRows / 26).coerceIn(1, 6)
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
        isNarrow: Boolean,
        fallbackOpenIntent: PendingIntent,
        allowShow: Boolean
    ) {
        if (!allowShow) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
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
        if (!isDone && action.isNotEmpty()) {
            views.setOnClickPendingIntent(btnId, actionIntent(context, action))
        } else {
            // 이미 완료된 줄은 위젯에서 취소되지 않고 해당 탭으로 앱만 열림
            views.setOnClickPendingIntent(btnId, fallbackOpenIntent)
        }
    }

    const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
}
