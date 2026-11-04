package com.healthpharma.hagom_app

import android.app.PendingIntent
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
 * 설계 원칙: 네이티브는 상태를 '계산'하거나 '지어내지' 않는다.
 * 모든 문구/상태는 Flutter(AppStateManager)가 저장한 값을 그대로 렌더링만 한다.
 * 버튼 탭은 전부 Dart 백그라운드 콜백으로 넘겨서 실제 앱 데이터를 변경한다.
 */
object WidgetBindings {

    /**
     * 앱 특정 탭으로 여는 PendingIntent.
     *
     * home_widget 기본 LaunchIntent는 액티비티 플래그가 없어서, 앱이 이미 떠 있으면
     * 런처가 태스크만 앞으로 가져오고 onNewIntent를 호출하지 않는다(= 탭 이동 실패).
     * NEW_TASK|SINGLE_TOP|CLEAR_TOP을 직접 지정해야 기존 인스턴스에 인텐트가 전달된다.
     */
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

    /** 버튼 탭 -> Dart 백그라운드 콜백(앱 실행 없이 실제 데이터 변경) */
    fun actionIntent(context: Context, uri: String): PendingIntent =
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri))

    fun text(prefs: SharedPreferences, key: String): String = prefs.getString(key, "") ?: ""

    /**
     * 확장 영역의 한 줄을 바인딩한다.
     * Flutter가 내려준 text가 비어 있으면 그 줄은 숨긴다(= 가짜 예시 문구가 남지 않음).
     */
    fun bindRow(
        views: RemoteViews,
        prefs: SharedPreferences,
        context: Context,
        rowId: Int,
        textId: Int,
        btnId: Int,
        textKey: String,
        doneKey: String,
        actionKey: String,
        pendingLabel: String,
        pendingBg: Int
    ) {
        val rowText = text(prefs, textKey)
        if (rowText.isEmpty()) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(textId, rowText)

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
