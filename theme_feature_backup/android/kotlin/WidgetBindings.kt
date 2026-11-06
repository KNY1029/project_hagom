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
 * - 완료된 복약/습관 버튼을 누르면 앱을 켜지도 취소하지도 않는 noopIntent로 연결해 버튼 터치감만 준다.
 * - 할일(task)은 allowCompletedToggle=true로 넘겨 완료된 상태에서도 다시 눌러 취소할 수 있게 한다.
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

    fun actionIntent(context: Context, uri: String, requestCode: Int = 0): PendingIntent {
        val intent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            data = Uri.parse(uri)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (android.os.Build.VERSION.SDK_INT >= 23) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        val code = if (requestCode != 0) requestCode else uri.hashCode()
        return PendingIntent.getBroadcast(context, code, intent, flags)
    }

    /** 앱을 띄우지도 데이터를 바꾸지도 않고 버튼 클릭 리플만 발생시키는 인텐트 */
    fun noopIntent(context: Context): PendingIntent =
        actionIntent(context, "hagomwidget://noop", 99999)

    fun text(prefs: SharedPreferences, key: String): String = prefs.getString(key, "") ?: ""

    fun isNarrowWidth(appWidgetManager: AppWidgetManager, appWidgetId: Int): Boolean {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        return minW in 1..205
    }

    fun maxFittingRows(appWidgetManager: AppWidgetManager, appWidgetId: Int): Int {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val effectiveH = when {
            minH > 0 -> minH
            maxH > 0 -> maxH
            else -> 90
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
        allowCompletedToggle: Boolean,
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
        if ((!isDone || allowCompletedToggle) && action.isNotEmpty()) {
            views.setOnClickPendingIntent(btnId, actionIntent(context, action))
        } else {
            // 완료된 복약/습관 줄은 눌리는 느낌만 주고 앱은 띄우지 않음
            views.setOnClickPendingIntent(btnId, noopIntent(context))
        }
    }

    const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
}
