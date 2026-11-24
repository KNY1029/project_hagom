package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.app.NotificationManager
import android.os.Handler
import android.os.Looper
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import es.antonborri.home_widget.HomeWidgetPlugin
/**
 * ⚡ [초고속 네이티브 위젯 인터랙션 리시버]
 *
 * 위젯 탭 시 무거운 플러터 엔진(Dart VM)이 깨어나길 기다리거나 프로세스 킬로 씹히지 않고,
 * 안드로이드 네이티브 OS가 SharedPreferences를 직접 갱신하고 위젯 UI를 0.01초 만에 즉시 다시 그립니다!
 * 그 후 백그라운드로 기존 HomeWidgetBackgroundReceiver에 토스하여 앱 내부 데이터도 동기화합니다.
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        // 🌟 [전체 버튼 글로벌 락]: 버튼을 누르면 대기시간(450ms) 동안
        // 해당 버튼뿐만 아니라 "위젯 내의 다른 모든 버튼" 클릭까지 전부 잠금 처리하여 동시 연타 및 꼬임 완벽 차단!
        private var globalLockUntil = 0L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val uri = intent.data ?: return
        val host = uri.host ?: uri.path?.replace("/", "") ?: return
        val action = host.lowercase()

        if (intent.action == "com.healthpharma.hagom_app.ACTION_NOTIFICATION_COMPLETE") {
            val notificationPrefs = context.getSharedPreferences("HagomNotificationPrefs", Context.MODE_PRIVATE)
            val actionKey = uri.toString().hashCode()
            val activeKey = "active_$actionKey"
            val activeIds = notificationPrefs.getStringSet(activeKey, emptySet()).orEmpty()
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            activeIds.forEach { it.toIntOrNull()?.let { id -> notificationManager?.cancel(id) } }
            notificationManager?.cancel(intent.getIntExtra("notificationId", -1))
            notificationPrefs.edit().remove(activeKey).apply()

            // 원래 알림과 재알림이 함께 쌓여 있어도 같은 항목은 하루 한 번만 처리한다.
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            val handledKey = "handled_${today}_$actionKey"
            if (notificationPrefs.getBoolean(handledKey, false)) {
                return
            }
            notificationPrefs.edit().putBoolean(handledKey, true).apply()

            val notificationId = intent.getIntExtra("notificationId", -1)
            if (notificationId >= 0) {
                notificationManager?.cancel(notificationId)
            }
        }

        if (action != "noop") {
            val accessPrefs = HomeWidgetPlugin.getData(context)
            accessPrefs.edit()
                .putString("hagom_widget_access_day", SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date()))
                .apply()
        }

        // 🔒 글로벌 락 검사: 450ms 대기시간 동안에는 어떤 위젯 버튼 클릭도 무시
        val now = System.currentTimeMillis()
        if (now < globalLockUntil) {
            return
        }
        // 사용자가 완료 인지할 수 있는 가장 쾌적하고 깔끔한 대기시간: 450ms
        if (action == "checkmed" || action == "checkhabit" || action == "checktask") {
            globalLockUntil = now + 450L
        }

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
                val userNickname = prefs.getString("user_nickname", "유저")?.trim().let { if (it.isNullOrEmpty()) "유저" else it }
                val userDisplayName = "${userNickname}님"

                val mascotStages = listOf(
                    Triple("1. 기대", listOf("하곰이는 언제나 여기 있어요!", "내일도 힘내서 가보자고요✨"), "hagom_widget_stage_1"),
                    Triple("2. 기다림", listOf("하곰은(뚠뚠) 오늘도(뚠뚠) 접속을~ 기다리네(뚠뚠)", "오늘 할 일도 마치고 오실 때까지, 조용히 기다릴게요!"), "hagom_widget_stage_2"),
                    Triple("3. 부담", listOf("있죠 나 알고 있어요, ${userDisplayName}은 할 수 있는 아이라는 거~", "${userNickname}니이임!! 나를 두고 어디 가신 거예요오오!!!!"), "hagom_widget_stage_3"),
                    Triple("4. 당황", listOf("하곰이 조금은 슬플지도 몰라요...", "어라...? 연속 방문 기록이 깨지고 있어요😳"), "hagom_widget_stage_4"),
                    Triple("5. 분노", listOf("요즘 많이 바쁜가 봐요...!!", "충격: 하곰이 앱 이용횟수 급감해"), "hagom_widget_stage_5"),
                    Triple("6. 슬픔", listOf("너 떠난 이곳은 잠겨 눈물로🎵", "${userDisplayName}, 큰일이에요!! 애써 쌓은 기록이..."), "hagom_widget_stage_6"),
                    Triple("7. 피로", listOf("(진짜 안 올 거예요?? 아니 진짜로?)", "우리... 좋았잖아요....."), "hagom_widget_stage_7"),
                    Triple("8. 절망", listOf("하곰이는 늘 ${userDisplayName}뿐이었는데ㅠ", "어쩜... 다른 앱으로 갈아타버린 거예요?"), "hagom_widget_stage_8"),
                    Triple("9. 붕괴", listOf("그럼 하곰이... 삭제돼도 되니...?", "하... ${userDisplayName}- 아니, 당신. 이런 관계 하곰이는 이제 지쳤어요."), "hagom_widget_stage_9")
                )

                val isDevMode = prefs.getString("is_developer_mode", "false") == "true" ||
                                prefs.getString("mascot_show_badge", "false") == "true"

                val curBadge = prefs.getString("mascot_badge", "1. 기대") ?: "1. 기대"
                val curIndex = mascotStages.indexOfFirst { it.first == curBadge }.let { if (it == -1) 0 else it }
                val currentStage = mascotStages[curIndex]
                val currentQuoteIndex = when (val v = prefs.all["mascot_quote_index"]) {
                    is Number -> v.toInt()
                    is String -> v.toIntOrNull() ?: 0
                    else -> 0
                }

                val nextIndex: Int
                val nextQuoteIndex: Int

                if (isDevMode) {
                    // 🛠️ 개발자 모드: 대사를 다 보면 다음 단계로 넘어가며 9단계 전체 회전
                    val isLastQuote = currentQuoteIndex >= currentStage.second.lastIndex
                    nextIndex = if (isLastQuote) (curIndex + 1) % mascotStages.size else curIndex
                    nextQuoteIndex = if (isLastQuote) 0 else currentQuoteIndex + 1
                } else {
                    // ☀️ 일반 모드: 단계는 현재 출석 단계에 고정, 대사만 순환 전환
                    nextIndex = curIndex
                    nextQuoteIndex = (currentQuoteIndex + 1) % currentStage.second.size
                }

                val rawQuote = nextStage.second[nextQuoteIndex]
                val formattedQuote = rawQuote
                    .replace("유저니이이임", "${userNickname}니이이임")
                    .replace("유저니이임", "${userNickname}니이임")
                    .replace("유저님", userDisplayName)
                    .replace("유저", userNickname)

                editor.putString("mascot_badge", nextStage.first)
                editor.putString("mascot_quote", formattedQuote)
                editor.putInt("mascot_quote_index", nextQuoteIndex)
                editor.putInt("mascot_stage_index", nextIndex)
                editor.putString("mascot_sub", "")
                editor.putString("mascot_image", nextStage.third)
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
                // 💊 복약 체크 탭: 해당 row를 즉각 '완료' 상태로 바꾸고, 메인 복용 버튼도 즉시 변경!
                val id = uri.getQueryParameter("id")
                val slot = uri.getQueryParameter("slot")
                
                // 1) row 일치 항목 체크 (반드시 id와 slot 번호가 둘 다 일치해야 함!)
                for (n in 1..6) {
                    val actionStr = prefs.getString("meds_row_${n}_action", "") ?: ""
                    val isMatch = if (id != null && slot != null) {
                        actionStr.contains("id=$id") && actionStr.contains("slot=$slot")
                    } else if (id != null) {
                        actionStr.contains("id=$id")
                    } else false

                    if (isMatch) {
                        editor.putString("meds_row_${n}_done", "true")
                        editor.putString("meds_row_${n}_action", "")
                        break
                    }
                }
                
                // 2) 메인 헤더 복용 버튼 체크 (primary med와 id 및 slot까지 모두 일치할 때만 완료 처리!)
                val mainAction = prefs.getString("meds_action", "") ?: ""
                val isMainMatch = if (mainAction.isNotEmpty()) {
                    if (id != null && slot != null) {
                        mainAction.contains("id=$id") && mainAction.contains("slot=$slot")
                    } else if (id != null) {
                        mainAction.contains("id=$id")
                    } else true
                } else false

                if (isMainMatch) {
                    editor.putString("meds_btn_title", "완료")
                    editor.putString("meds_action", "")
                }
                editor.apply()

                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomMedsWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomMedsWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }

            "checkhabit" -> {
                // 🌱 습관 체크 탭: 0.01초 만에 다음 상태 라벨로 정확하게 전진!
                // (3/4회에서 눌렀을 때만 완료로 바뀌고, 그 전에는 2/4회, 3/4회로 즉시 다음 번호로 이동)
                val id = uri.getQueryParameter("id")
                val curParam = uri.getQueryParameter("cur")?.toIntOrNull()
                val targetParam = uri.getQueryParameter("target")?.toIntOrNull() ?: 1

                // 1) row 일치 항목 즉시 갱신
                for (n in 1..6) {
                    val actionStr = prefs.getString("habits_row_${n}_action", "") ?: ""
                    if (id != null && actionStr.contains("id=$id")) {
                        val currentLabel = prefs.getString("habits_row_${n}_btn_label", "") ?: ""
                        val parsedCur = if (currentLabel.contains("/")) {
                            currentLabel.split("/").firstOrNull()?.filter { it.isDigit() }?.toIntOrNull()
                        } else if (currentLabel == "조금 실천") {
                            1
                        } else if (currentLabel == "대기") {
                            0
                        } else null

                        val curVal = parsedCur ?: curParam ?: 0
                        val nextVal = curVal + 1
                        val isTargetMulti = targetParam > 1

                        val nextLabel: String
                        val nextState: String
                        val isDone: Boolean

                        if (isTargetMulti) {
                            if (nextVal >= targetParam) {
                                nextLabel = "완료"
                                nextState = "done"
                                isDone = true
                            } else {
                                nextLabel = "$nextVal/${targetParam}회"
                                nextState = "partial"
                                isDone = false
                            }
                        } else {
                            if (nextVal >= 2) {
                                nextLabel = "완료"
                                nextState = "done"
                                isDone = true
                            } else {
                                nextLabel = "조금 실천"
                                nextState = "partial"
                                isDone = false
                            }
                        }

                        editor.putString("habits_row_${n}_btn_label", nextLabel)
                        editor.putString("habits_row_${n}_state", nextState)
                        editor.putString("habits_row_${n}_done", if (isDone) "true" else "false")
                        if (isDone) {
                            editor.putString("habits_row_${n}_action", "")
                        } else {
                            editor.putString("habits_row_${n}_action", "hagomwidget://checkhabit?id=$id&cur=$nextVal&target=$targetParam")
                        }
                        break
                    }
                }

                // 2) 메인 헤더 대표 습관 버튼 즉시 갱신
                val mainAction = prefs.getString("habits_action", "") ?: ""
                if (mainAction.isNotEmpty() && (id == null || mainAction.contains("id=$id"))) {
                    val currentLabel = prefs.getString("habits_btn_title", "") ?: ""
                    val parsedCur = if (currentLabel.contains("/")) {
                        currentLabel.split("/").firstOrNull()?.filter { it.isDigit() }?.toIntOrNull()
                    } else if (currentLabel == "조금 실천") {
                        1
                    } else if (currentLabel == "대기") {
                        0
                    } else null

                    val curVal = parsedCur ?: curParam ?: 0
                    val nextVal = curVal + 1
                    val isTargetMulti = targetParam > 1

                    val nextLabel: String
                    val nextState: String
                    val isDone: Boolean

                    if (isTargetMulti) {
                        if (nextVal >= targetParam) {
                            nextLabel = "완료"
                            nextState = "done"
                            isDone = true
                        } else {
                            nextLabel = "$nextVal/${targetParam}회"
                            nextState = "partial"
                            isDone = false
                        }
                    } else {
                        if (nextVal >= 2) {
                            nextLabel = "완료"
                            nextState = "done"
                            isDone = true
                        } else {
                            nextLabel = "조금 실천"
                            nextState = "partial"
                            isDone = false
                        }
                    }

                    editor.putString("habits_btn_title", nextLabel)
                    editor.putString("habits_state", nextState)
                    if (isDone) {
                        editor.putString("habits_action", "")
                    } else {
                        editor.putString("habits_action", "hagomwidget://checkhabit?id=${id ?: ""}&cur=$nextVal&target=$targetParam")
                    }
                }
                editor.apply()

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
                var oldDone: Boolean? = null
                var newDone: Boolean? = null
                for (n in 1..6) {
                    val actionStr = prefs.getString("cal_row_${n}_action", "") ?: ""
                    if (id != null && actionStr.contains("id=$id")) {
                        val currentDone = prefs.getString("cal_row_${n}_done", "false") == "true"
                        oldDone = currentDone
                        newDone = !currentDone
                        editor.putString("cal_row_${n}_done", if (newDone == true) "true" else "false")
                        editor.apply()
                        break
                    }
                }
                // 대표 할일 카드가 눌린 경우에도 제목·버튼·완료색·진행률을 즉시 함께 갱신한다.
                val mainAction = prefs.getString("calendar_action", "") ?: ""
                if (id != null && mainAction.contains("id=$id")) {
                    val currentDone = prefs.getString("calendar_all_done", "false") == "true"
                    oldDone = currentDone
                    newDone = !currentDone
                    editor.putString("calendar_btn_title", if (newDone == true) "완료" else "체크")
                    editor.putString("calendar_all_done", if (newDone == true) "true" else "false")
                }
                if (oldDone != null && newDone != null) {
                    val progress = prefs.getString("calendar_progress", "") ?: ""
                    val match = Regex("(\\d+)/(\\d+)").find(progress)
                    if (match != null) {
                        val done = match.groupValues[1].toIntOrNull() ?: 0
                        val total = match.groupValues[2].toIntOrNull() ?: 0
                        val nextDone = (done + if (newDone == true) 1 else -1).coerceIn(0, total)
                        editor.putString("calendar_progress", "$nextDone/$total 완료")
                    }
                }
                editor.apply()
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HagomCalendarWidgetProvider::class.java)
                )
                if (ids.isNotEmpty()) {
                    val provider = HagomCalendarWidgetProvider()
                    provider.onUpdate(context, appWidgetManager, ids, prefs)
                }
            }
        }

        // 🌟 마스코트 위젯 터치(대사 전환) 및 단순 리플(noop)은 네이티브에서 100% 처리 완료되므로
        // 무거운 플러터 백그라운드 엔진을 깨워 배터리를 낭비하거나 위젯 상태를 덮어쓰지 않도록 즉시 종료합니다.
        // (주의: selectday 날짜 선택은 날짜별 상세 일정/복약/습관 계산을 위해 플러터 백그라운드로 전달되어야 합니다!)
        if (action == "next_mascot_stage" || action == "noop") {
            return
        }

        // 🌟 [최적화된 450ms 딜레이]:
        // 사용자가 버튼이 눌렸다는 것(초록 완료 등)을 명확하게 눈으로 인지한 뒤
        // 지루하게 기다리지 않고 450ms 시점에 자연스럽게 하단으로 재배치!
        val shouldDelayReposition = (action == "checkmed" || action == "checkhabit" || action == "checktask")
        val delayMs = if (shouldDelayReposition) 450L else 0L

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val bgIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
                    this.action = "es.antonborri.home_widget.action.BACKGROUND"
                    this.data = uri
                }
                context.sendBroadcast(bgIntent)
            } catch (_: Exception) {
                // 플러터 엔진이 죽어있어도 위젯 화면은 이미 네이티브가 100% 갱신 완료했으므로 문제없음!
            }
        }, delayMs)
    }
}
