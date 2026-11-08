package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * ⚡ [초고속 네이티브 위젯 인터랙션 리시버]
 *
 * 위젯 탭 시 무거운 플러터 엔진(Dart VM)이 깨어나길 기다리거나 프로세스 킬로 씹히지 않고,
 * 안드로이드 네이티브 OS가 SharedPreferences를 직접 갱신하고 위젯 UI를 0.01초 만에 즉시 다시 그립니다!
 * 그 후 백그라운드로 기존 HomeWidgetBackgroundReceiver에 토스하여 앱 내부 데이터도 동기화합니다.
 */
class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val uri = intent.data ?: return
        val host = uri.host ?: uri.path?.replace("/", "") ?: return
        val action = host.lowercase()

        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val editor = prefs.edit()

        val appWidgetManager = AppWidgetManager.getInstance(context)

        when (action) {
            "selectday" -> {
                // 📅 달력 날짜 탭: 즉시 SharedPreferences에 선택일 저장하고 달력 위젯 즉시 갱신!
                val dateParam = uri.getQueryParameter("date")
                if (!dateParam.isNullOrEmpty()) {
                    val currentSelected = prefs.getString("month_selected_date", "")
                    val newSelected = if (currentSelected == dateParam) "" else dateParam
                    val dayStr = if (newSelected.isNotEmpty()) {
                        dateParam.split("-").lastOrNull()?.toIntOrNull()?.toString() ?: ""
                    } else ""

                    editor.putString("month_selected_date", newSelected)
                    editor.putString("month_selected_day", dayStr)
                    editor.putString("month_inspecting_iso", newSelected)
                    editor.apply()

                    // 달력 위젯 즉시 강제 리프레시!
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, HagomMonthCalendarWidgetProvider::class.java)
                    )
                    if (ids.isNotEmpty()) {
                        val provider = HagomMonthCalendarWidgetProvider()
                        provider.onUpdate(context, appWidgetManager, ids, prefs)
                    }
                }
            }

            "next_mascot_stage" -> {
                // 🐻 마스코트 위젯 탭: 1~9단계 즉시 네이티브 카운트업 & 이미지/대사 즉시 교체!
                val mascotStages = listOf(
                    Triple("1. 기대", "유저가 접속해서 기록을 이어갈 것이라 믿고 웃어주는 모습", "비처벌적 푸시" to "hagom_widget_stage_1"),
                    Triple("2. 기다림", "생각보다 유저의 귀환이늦어져서 슬슬 초조해지는 모습", "하곰이와 상호작용할 도덕적 의무감 부여" to "hagom_widget_stage_2"),
                    Triple("3. 부담", "어째서 돌아오지 않는지 알고 싶어하는 모습", "앱 접속이 오래 끊겼다는 걸 확대이미지를 통해 강조" to "hagom_widget_stage_3"),
                    Triple("4. 당황", "정말로 발걸음이 끊겼다는 걸 받아들이지 못하는 모습", "하곰이의 불안과 당혹감" to "hagom_widget_stage_4"),
                    Triple("5. 분노", "하곰이의 듀오링고적 면 살짝 보여주고 싶었음", "흑화 가능하다는 가능성 시사" to "hagom_widget_stage_5"),
                    Triple("6. 슬픔", "눈물이 점점 차오르는 모습", "어 한번 들어가봐야 하나 싶도록 존재감 어필" to "hagom_widget_stage_6"),
                    Triple("7. 피로", "다 울고 나서 바싹 마른 모습", "기존 이미지와 다르게 망가지는 표현으로 재접속 시도" to "hagom_widget_stage_7"),
                    Triple("8. 절망", "극적인 표현과 명암대비로 시선 붙잡기", "시선 붙잡고 재접속 유도" to "hagom_widget_stage_8"),
                    Triple("9. 붕괴", "최종단계로 완전히 고장난/고사한 모습", "다마고치 사망 같은 무게감의 엔딩" to "hagom_widget_stage_9")
                )

                val curBadge = prefs.getString("mascot_badge", "1. 기대") ?: "1. 기대"
                val curIndex = mascotStages.indexOfFirst { it.first == curBadge }.let { if (it == -1) 0 else it }
                val nextIndex = (curIndex + 1) % mascotStages.size
                val nextStage = mascotStages[nextIndex]

                editor.putString("mascot_badge", nextStage.first)
                editor.putString("mascot_quote", nextStage.second)
                editor.putString("mascot_sub", nextStage.third.first)
                editor.putString("mascot_image", nextStage.third.second)
                editor.apply()

                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomMascotWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomMascotWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }

            "checkmed" -> {
                // 💊 복약 체크 탭: 해당 row를 즉각 '완료' 상태로 바꾸고 위젯 즉시 갱신!
                val id = uri.getQueryParameter("id")
                val slot = uri.getQueryParameter("slot")
                // 위젯 내 meds_row_1~6 중 일치하는 row 찾아서 done=true 처리
                for (n in 1..6) {
                    val actionStr = prefs.getString("meds_row_${n}_action", "") ?: ""
                    if (actionStr.contains("id=$id") && actionStr.contains("slot=$slot")) {
                        editor.putString("meds_row_${n}_done", "true")
                        editor.putString("meds_row_${n}_action", "") // 중복 클릭 방지
                        editor.apply()
                        break
                    }
                }
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomMedsWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomMedsWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }

            "checkhabit" -> {
                // 🌱 습관 체크 탭: 해당 row 즉각 완료 처리 및 위젯 즉시 갱신!
                val id = uri.getQueryParameter("id")
                for (n in 1..6) {
                    val actionStr = prefs.getString("habits_row_${n}_action", "") ?: ""
                    if (actionStr.contains("id=$id")) {
                        editor.putString("habits_row_${n}_done", "true")
                        editor.putString("habits_row_${n}_action", "")
                        editor.apply()
                        break
                    }
                }
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomHabitsWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomHabitsWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }

            "checktask" -> {
                // 🗓️ 할일 체크 탭: 완료 토글 및 위젯 즉시 갱신!
                val id = uri.getQueryParameter("id")
                for (n in 1..6) {
                    val actionStr = prefs.getString("cal_row_${n}_action", "") ?: ""
                    if (actionStr.contains("id=$id")) {
                        val currentDone = prefs.getString("cal_row_${n}_done", "false") == "true"
                        editor.putString("cal_row_${n}_done", if (currentDone) "false" else "true")
                        editor.apply()
                        break
                    }
                }
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomCalendarWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomCalendarWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }
        }

        // 🌟 안드로이드 네이티브 UI를 0.01초 만에 바꾼 뒤, 플러터 엔진에도 백그라운드 동기화 전달!
        try {
            val bgIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
                this.action = "es.antonborri.home_widget.action.BACKGROUND"
                this.data = uri
            }
            context.sendBroadcast(bgIntent)
        } catch (_: Exception) {
            // 플러터 엔진이 죽어있어도 위젯 화면은 이미 네이티브가 100% 갱신 완료했으므로 문제없음!
        }
    }
}
