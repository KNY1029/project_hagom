package com.healthpharma.hagom_app

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver

object WidgetBindings {

    fun openAppIntent(context: Context, uri: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HOME_WIDGET_LAUNCH_ACTION
            data = Uri.parse(uri)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= 23) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        if (Build.VERSION.SDK_INT >= 34) {
            val options = ActivityOptions.makeBasic()
            if (Build.VERSION.SDK_INT >= 35) {
                options.setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                )
            } else {
                options.pendingIntentBackgroundActivityStartMode =
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
            }
            return PendingIntent.getActivity(context, requestCode, intent, flags, options.toBundle())
        }

        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    /** 🌟 고유 requestCode를 부여하여 서로 다른 버튼/셀 인텐트가 안드로이드 시스템에 의해 덮어씌워지지 않도록 보장 */
    fun actionIntent(context: Context, uri: String, requestCode: Int = 0): PendingIntent {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            data = Uri.parse(uri)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= 23) {
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
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)
        return ((minH - 80) / 26).coerceIn(1, 6)
    }

    const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
}
