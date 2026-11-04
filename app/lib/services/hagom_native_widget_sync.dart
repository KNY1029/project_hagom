import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../state/app_state_manager.dart';

/// 📱 안드로이드 홈 화면 런처 4대 위젯에 앱의 최신 복약/습관/할일 데이터를 동기화하는 서비스
class HagomNativeWidgetSync {
  static const String mascotProvider = 'HagomMascotWidgetProvider';
  static const String medsProvider = 'HagomMedsWidgetProvider';
  static const String habitsProvider = 'HagomHabitsWidgetProvider';
  static const String calendarProvider = 'HagomCalendarWidgetProvider';
  static const String monthCalendarProvider = 'HagomMonthCalendarWidgetProvider';

  /// 앱 상태 변경 시 호출되어 안드로이드 홈 화면의 4대 위젯을 모두 최신 상태로 갱신
  static Future<void> updateNativeWidget(AppStateManager state) async {
    // 웹 플랫폼에서는 네이티브 위젯 플러그인이 동작하지 않으므로 무시
    if (kIsWeb) return;

    try {
      // -------------------------------------------------------------
      // 1) 🐻 마스코트 응원 한마디 위젯 데이터 구성
      // -------------------------------------------------------------
      final totalMeds = state.totalDoseSlots;
      final compMeds = state.completedDoseSlots;
      final habitTotal = state.habits.where((h) => h.isDueToday).length;
      final habitScore = state.habitTotalScore;

      final bool isMedAll = totalMeds > 0 && compMeds >= totalMeds;
      final bool isHabitAll = habitTotal > 0 && habitScore >= habitTotal.toDouble();

      String mascotBadge;
      String mascotQuote;
      String mascotSub;

      if (isMedAll && isHabitAll) {
        mascotBadge = '기쁨 (올클리어)';
        mascotQuote = '오늘 약과 루틴을 모두 완료했어요!\n스스로를 아끼는 마음이 정말 멋져요.';
        mascotSub = '오늘의 모든 목표 달성 완료';
      } else {
        mascotBadge = '하곰이의 응원';
        mascotQuote = '한 가지만 실천해도 충분해요.\n오늘 약 하나만 챙겨도 대단한 거예요.';
        mascotSub = '천천히 편안한 속도로 가요';
      }

      await HomeWidget.saveWidgetData<String>('mascot_badge', mascotBadge);
      await HomeWidget.saveWidgetData<String>('mascot_quote', mascotQuote);
      await HomeWidget.saveWidgetData<String>('mascot_sub', mascotSub);
      await HomeWidget.updateWidget(name: mascotProvider, androidName: mascotProvider);

      // -------------------------------------------------------------
      // 2) 💊 복약 관리 1-Tap 위젯 데이터 구성
      // -------------------------------------------------------------
      String medsTag = '다음 복약';
      String medsProgress = '${state.completedDoseSlots}/${state.totalDoseSlots} 완료';
      String medsTitle = '오늘 복약 완료';
      String medsSubtitle = '오늘 예정된 모든 복약을 마쳤어요';
      String medsExtra = '자가 모니터링 성공';
      String medsBtnTitle = '완료';
      String medsBtnSubtitle = '달성';

      bool foundPendingMed = false;
      for (final med in state.medications) {
        if (!med.isDueToday) continue;
        for (final slot in med.doseSlots) {
          if (!slot.isCompleted && !slot.isSkipped) {
            medsTitle = '${med.name} ${med.dosage}';
            medsSubtitle = '${slot.scheduledTime ?? "예정"} · 식후 복용';
            medsExtra = med.isPrescription ? '처방약 (시간 엄수)' : '일반약';
            medsBtnTitle = '복용';
            medsBtnSubtitle = '1-Tap';
            foundPendingMed = true;
            break;
          }
        }
        if (foundPendingMed) break;
      }

      if (!foundPendingMed && state.medications.isEmpty) {
        medsTitle = '등록된 약 없음';
        medsSubtitle = '앱에서 새로운 약을 추가해 보세요';
        medsExtra = '자유 실천';
        medsProgress = '0/0';
        medsBtnTitle = '추가';
        medsBtnSubtitle = '앱 열기';
      }

      await HomeWidget.saveWidgetData<String>('meds_tag', medsTag);
      await HomeWidget.saveWidgetData<String>('meds_progress', medsProgress);
      await HomeWidget.saveWidgetData<String>('meds_title', medsTitle);
      await HomeWidget.saveWidgetData<String>('meds_subtitle', medsSubtitle);
      await HomeWidget.saveWidgetData<String>('meds_extra', medsExtra);
      await HomeWidget.saveWidgetData<String>('meds_btn_title', medsBtnTitle);
      await HomeWidget.saveWidgetData<String>('meds_btn_subtitle', medsBtnSubtitle);
      await HomeWidget.updateWidget(name: medsProvider, androidName: medsProvider);

      // -------------------------------------------------------------
      // 3) 🌱 습관 관리 1-Tap 위젯 데이터 구성
      // -------------------------------------------------------------
      final todayHabits = state.habits.where((h) => h.isDueToday).toList();
      final habit = todayHabits.isNotEmpty ? todayHabits.first : null;

      String habitsTag = '오늘의 습관';
      String habitsProgress = '총 ${state.habitTotalScore.toStringAsFixed(1)}/${todayHabits.length} 실천';
      String habitsTitle = habit != null ? habit.title : '등록된 습관 없음';
      String habitsSubtitle = habit != null ? habit.subtitle : '앱에서 새로운 습관을 추가해 보세요';
      String habitsExtra = habit != null ? '현재 상태: ${habit.statusLabel}' : '자유 실천';
      String habitsBtnTitle = (habit != null && habit.score >= 1.0) ? '달성' : '실천';
      String habitsBtnSubtitle = '1-Tap';

      await HomeWidget.saveWidgetData<String>('habits_tag', habitsTag);
      await HomeWidget.saveWidgetData<String>('habits_progress', habitsProgress);
      await HomeWidget.saveWidgetData<String>('habits_title', habitsTitle);
      await HomeWidget.saveWidgetData<String>('habits_subtitle', habitsSubtitle);
      await HomeWidget.saveWidgetData<String>('habits_extra', habitsExtra);
      await HomeWidget.saveWidgetData<String>('habits_btn_title', habitsBtnTitle);
      await HomeWidget.saveWidgetData<String>('habits_btn_subtitle', habitsBtnSubtitle);
      await HomeWidget.updateWidget(name: habitsProvider, androidName: habitsProvider);

      // -------------------------------------------------------------
      // 4) 🗓️ 기록 달력 / 할일 1-Tap 위젯 데이터 구성
      // -------------------------------------------------------------
      final now = DateTime.now();
      final todayTasks = state.getTasksForDay(now);
      final task = todayTasks.isNotEmpty ? todayTasks.first : (state.tasks.isNotEmpty ? state.tasks.first : null);

      String calTag = '오늘의 일정';
      String calProgress = (task != null && task.time != null) ? task.time! : '시간 미지정';
      String calTitle = task != null ? task.title : '등록된 일정 없음';
      String calSubtitle = task != null ? '반복: ${task.repeatSummary}' : '일정을 추가해 보세요';
      String calExtra = (task != null && task.isCompleted) ? '상태: 완료됨' : '상태: 진행 대기';
      String calBtnTitle = (task != null && task.isCompleted) ? '완료' : '체크';
      String calBtnSubtitle = '1-Tap';

      await HomeWidget.saveWidgetData<String>('calendar_tag', calTag);
      await HomeWidget.saveWidgetData<String>('calendar_progress', calProgress);
      await HomeWidget.saveWidgetData<String>('calendar_title', calTitle);
      await HomeWidget.saveWidgetData<String>('calendar_subtitle', calSubtitle);
      await HomeWidget.saveWidgetData<String>('calendar_extra', calExtra);
      await HomeWidget.saveWidgetData<String>('calendar_btn_title', calBtnTitle);
      await HomeWidget.saveWidgetData<String>('calendar_btn_subtitle', calBtnSubtitle);
      await HomeWidget.updateWidget(name: calendarProvider, androidName: calendarProvider);
      // -------------------------------------------------------------
      // 5) 🗓️ 4x4 한 달 달력 위젯 데이터 구성 (복약 + 습관 + 할일 3종 종합)
      // -------------------------------------------------------------
      final monthStr = '${now.year}년 ${now.month}월 기록 달력';
      final monthMeds = '복약 ${state.completedDoseSlots}/${state.totalDoseSlots} 완료';
      final monthHabits = '습관 ${state.habitTotalScore.toStringAsFixed(0)}/${todayHabits.length} 실천';
      final monthTasks = todayTasks.isNotEmpty
          ? '${todayTasks.first.title} (${todayTasks.first.time ?? "시간 미지정"})'
          : '예정된 일정이 없어요';

      await HomeWidget.saveWidgetData<String>('month_title', monthStr);
      await HomeWidget.saveWidgetData<String>('month_meds', monthMeds);
      await HomeWidget.saveWidgetData<String>('month_habits', monthHabits);
      await HomeWidget.saveWidgetData<String>('month_tasks', monthTasks);

      // 이번 달 날짜별 임상 상태(올클리어만 연초록 틴트, 나머지는 하단 바와 핀으로 정밀 바인딩)
      for (int d = 1; d <= 30; d++) {
        final date = DateTime(now.year, now.month, d);
        if (!state.isBeforeTrackingStart(date) && !date.isAfter(now)) {
          final mRate = state.getMedRateForDay(date);
          final hRate = state.getHabitRateForDay(date);
          final isMissedP = state.hasMissedPrescriptionForDay(date);
          final tasks = state.getTasksForDay(date);
          final hasT = tasks.isNotEmpty;

          String status = '';
          if (mRate != null && mRate >= 1.0 && hRate != null && hRate >= 1.0) {
            status = hasT ? 'all_done_pin' : 'all_done';
          } else if (isMissedP) {
            status = hasT ? 'missed_med_pin' : 'missed_med';
          } else if (mRate != null && mRate > 0.0) {
            status = hasT ? 'partial_pin' : 'partial';
          } else if (hasT) {
            status = 'pin_only';
          }
          await HomeWidget.saveWidgetData<String>('day_status_$d', status);
        }
      }

      await HomeWidget.updateWidget(name: monthCalendarProvider, androidName: monthCalendarProvider);
    } catch (e) {
      debugPrint('Native widget update error: $e');
    }
  }
}
