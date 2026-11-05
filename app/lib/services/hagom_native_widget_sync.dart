import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/medication_item.dart';
import '../state/app_state_manager.dart';

/// 안드로이드 홈 화면 위젯과 앱 데이터를 1:1로 동기화하는 서비스.
///
/// - 상단 대표 카드는 아래 확장 목록에서 제외(중복 제거)
/// - 확장 목록은 최대 6줄까지 내려보내며, 네이티브가 현재 위젯 높이에 맞춰 잘리지 않는 개수만 노출
/// - 이미 완료된 항목의 action은 비워서 위젯에서 실수로 취소되지 않게 함(탭 시 해당 탭으로 앱만 열림)
class HagomNativeWidgetSync {
  static const String mascotProvider = 'HagomMascotWidgetProvider';
  static const String medsProvider = 'HagomMedsWidgetProvider';
  static const String habitsProvider = 'HagomHabitsWidgetProvider';
  static const String calendarProvider = 'HagomCalendarWidgetProvider';
  static const String monthCalendarProvider = 'HagomMonthCalendarWidgetProvider';

  static Future<void> updateNativeWidget(AppStateManager state) async {
    if (kIsWeb) return;

    try {
      // -------------------------------------------------------------
      // 1) 마스코트 응원 위젯
      // -------------------------------------------------------------
      final totalMeds = state.totalDoseSlots;
      final compMeds = state.completedDoseSlots;
      final todayHabits = state.habits.where((h) => h.isDueToday).toList();
      final habitTotal = todayHabits.length;
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
      // 2) 복약 관리 위젯
      // -------------------------------------------------------------
      final List<_MedSlotEntry> todaySlots = [];
      for (final med in state.medications) {
        if (!med.isDueToday) continue;
        for (int i = 0; i < med.doseSlots.length; i++) {
          todaySlots.add(_MedSlotEntry(med: med, slotIndex: i, slot: med.doseSlots[i]));
        }
      }

      _MedSlotEntry? primaryMed;
      for (final entry in todaySlots) {
        if (!entry.slot.isCompleted && !entry.slot.isSkipped) {
          primaryMed = entry;
          break;
        }
      }
      primaryMed ??= todaySlots.isNotEmpty ? todaySlots.first : null;

      String medsTag = '다음 복약';
      String medsProgress = '$compMeds/$totalMeds 완료';
      String medsTitle;
      String medsSubtitle;
      String medsSubtitleShort;
      String medsBtnTitle;
      String medsAllDone;
      String medsAction;

      final allMedsCompleted = todaySlots.isNotEmpty &&
          todaySlots.every((e) => e.slot.isCompleted || e.slot.isSkipped);

      if (todaySlots.isEmpty) {
        medsTitle = '오늘 예정된 약 없음';
        medsSubtitle = '앱에서 복약 일정을 확인해 보세요';
        medsSubtitleShort = '일정 없음';
        medsProgress = '0/0';
        medsBtnTitle = '열기';
        medsAllDone = 'false';
        medsAction = '';
      } else if (!allMedsCompleted && primaryMed != null) {
        medsTitle = primaryMed.med.name;
        final timePart = primaryMed.slot.scheduledTime ?? primaryMed.slot.label;
        final howPart = primaryMed.med.dosage.isNotEmpty ? ' · ${primaryMed.med.dosage}' : '';
        medsSubtitle = '${primaryMed.slot.label} ($timePart)$howPart';
        medsSubtitleShort = '${primaryMed.slot.label} · $timePart';
        medsBtnTitle = '복용';
        medsAllDone = 'false';
        medsAction = 'hagomwidget://checkmed?id=${Uri.encodeComponent(primaryMed.med.id)}&slot=${primaryMed.slotIndex}';
      } else {
        medsTitle = '오늘 복약 모두 완료';
        medsSubtitle = '오늘 예정된 $totalMeds회 복약을 모두 마쳤어요';
        medsSubtitleShort = '$totalMeds회 모두 완료';
        medsBtnTitle = '완료';
        medsAllDone = 'true';
        medsAction = ''; // 완료 상태에서는 탭 시 앱(복약 탭)만 열림
      }

      await HomeWidget.saveWidgetData<String>('meds_tag', medsTag);
      await HomeWidget.saveWidgetData<String>('meds_progress', medsProgress);
      await HomeWidget.saveWidgetData<String>('meds_title', medsTitle);
      await HomeWidget.saveWidgetData<String>('meds_subtitle', medsSubtitle);
      await HomeWidget.saveWidgetData<String>('meds_subtitle_short', medsSubtitleShort);
      await HomeWidget.saveWidgetData<String>('meds_btn_title', medsBtnTitle);
      await HomeWidget.saveWidgetData<String>('meds_all_done', medsAllDone);
      await HomeWidget.saveWidgetData<String>('meds_action', medsAction);

      final remainingSlots = allMedsCompleted
          ? todaySlots
          : todaySlots.where((e) => !identical(e, primaryMed)).toList();
      final orderedSlots = [
        ...remainingSlots.where((e) => !e.slot.isCompleted && !e.slot.isSkipped),
        ...remainingSlots.where((e) => e.slot.isCompleted || e.slot.isSkipped),
      ];
      for (int i = 0; i < 6; i++) {
        final n = i + 1;
        if (i < orderedSlots.length) {
          final e = orderedSlots[i];
          final timeStr = e.slot.scheduledTime ?? e.slot.label;
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_text', '${e.med.name} · ${e.slot.label} ($timeStr)');
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_short', '${e.med.name} (${e.slot.label})');
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_done', e.slot.isCompleted ? 'true' : 'false');
          await HomeWidget.saveWidgetData<String>(
            'meds_row_${n}_action',
            e.slot.isCompleted ? '' : 'hagomwidget://checkmed?id=${Uri.encodeComponent(e.med.id)}&slot=${e.slotIndex}',
          );
        } else {
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_text', '');
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_short', '');
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_done', 'false');
          await HomeWidget.saveWidgetData<String>('meds_row_${n}_action', '');
        }
      }
      await HomeWidget.updateWidget(name: medsProvider, androidName: medsProvider);

      // -------------------------------------------------------------
      // 3) 습관 관리 위젯
      // -------------------------------------------------------------
      final pendingHabits = todayHabits.where((h) => h.score < 1.0).toList();
      final primaryHabit = pendingHabits.isNotEmpty
          ? pendingHabits.first
          : (todayHabits.isNotEmpty ? todayHabits.first : null);
      final doneHabitCount = todayHabits.where((h) => h.score >= 1.0).length;

      String habitsTag = '오늘의 습관';
      String habitsProgress = '$doneHabitCount/${todayHabits.length} 완료';
      String habitsTitle;
      String habitsSubtitle;
      String habitsSubtitleShort;
      String habitsBtnTitle;
      String habitsState;
      String habitsAction;

      if (primaryHabit == null) {
        habitsTitle = '오늘 예정된 습관 없음';
        habitsSubtitle = '앱에서 새로운 습관을 추가해 보세요';
        habitsSubtitleShort = '습관 없음';
        habitsBtnTitle = '열기';
        habitsState = 'standby';
        habitsAction = '';
      } else {
        final countInfo = primaryHabit.targetPerDay > 1
            ? ' (${primaryHabit.currentCount}/${primaryHabit.targetPerDay})'
            : '';
        habitsTitle = '${primaryHabit.title}$countInfo';
        habitsSubtitle = primaryHabit.subtitle;
        habitsSubtitleShort = primaryHabit.targetPerDay > 1
            ? '${primaryHabit.currentCount}/${primaryHabit.targetPerDay}회 실천'
            : primaryHabit.recurrenceSummary;
        if (primaryHabit.score >= 1.0) {
          habitsBtnTitle = '완료';
          habitsState = 'done';
          habitsAction = '';
        } else if (primaryHabit.score > 0.0) {
          habitsBtnTitle = '실천';
          habitsState = 'partial';
          habitsAction = 'hagomwidget://checkhabit?id=${Uri.encodeComponent(primaryHabit.id)}';
        } else {
          habitsBtnTitle = '실천';
          habitsState = 'standby';
          habitsAction = 'hagomwidget://checkhabit?id=${Uri.encodeComponent(primaryHabit.id)}';
        }
      }

      final allHabitsCompleted = todayHabits.isNotEmpty && todayHabits.every((h) => h.score >= 1.0);
      await HomeWidget.saveWidgetData<String>('habits_all_done', allHabitsCompleted ? 'true' : 'false');
      await HomeWidget.saveWidgetData<String>('habits_tag', habitsTag);
      await HomeWidget.saveWidgetData<String>('habits_progress', habitsProgress);
      await HomeWidget.saveWidgetData<String>('habits_title', habitsTitle);
      await HomeWidget.saveWidgetData<String>('habits_subtitle', habitsSubtitle);
      await HomeWidget.saveWidgetData<String>('habits_subtitle_short', habitsSubtitleShort);
      await HomeWidget.saveWidgetData<String>('habits_btn_title', habitsBtnTitle);
      await HomeWidget.saveWidgetData<String>('habits_state', habitsState);
      await HomeWidget.saveWidgetData<String>('habits_action', habitsAction);

      final remainingHabits = todayHabits.where((h) => h.id != primaryHabit?.id).toList();
      final orderedHabits = [
        ...remainingHabits.where((h) => h.score < 1.0),
        ...remainingHabits.where((h) => h.score >= 1.0),
      ];
      for (int i = 0; i < 6; i++) {
        final n = i + 1;
        if (i < orderedHabits.length) {
          final h = orderedHabits[i];
          final prog = h.targetPerDay > 1 ? ' (${h.currentCount}/${h.targetPerDay})' : '';
          final isDone = h.score >= 1.0;
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_text', '${h.title}$prog');
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_short', h.title);
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_done', isDone ? 'true' : 'false');
          await HomeWidget.saveWidgetData<String>(
            'habits_row_${n}_action',
            isDone ? '' : 'hagomwidget://checkhabit?id=${Uri.encodeComponent(h.id)}',
          );
        } else {
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_text', '');
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_short', '');
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_done', 'false');
          await HomeWidget.saveWidgetData<String>('habits_row_${n}_action', '');
        }
      }
      await HomeWidget.updateWidget(name: habitsProvider, androidName: habitsProvider);

      // -------------------------------------------------------------
      // 4) 할일 / 일정 위젯
      // -------------------------------------------------------------
      final now = DateTime.now();
      final todayTasks = state.getTasksForDay(now);
      final pendingTasks = todayTasks.where((t) => !t.isCompleted).toList();
      final primaryTask = pendingTasks.isNotEmpty
          ? pendingTasks.first
          : (todayTasks.isNotEmpty ? todayTasks.first : null);
      final doneTasks = todayTasks.where((t) => t.isCompleted).length;

      String calTag = '오늘의 할일';
      String calProgress = todayTasks.isEmpty ? '0/0' : '$doneTasks/${todayTasks.length} 완료';
      String calTitle;
      String calSubtitle;
      String calSubtitleShort;
      String calBtnTitle;
      String calAllDone;
      String calAction;

      if (primaryTask == null) {
        calTitle = '오늘 예정된 할일 없음';
        calSubtitle = '달력에서 오늘의 할일을 추가해 보세요';
        calSubtitleShort = '일정 없음';
        calBtnTitle = '열기';
        calAllDone = 'false';
        calAction = '';
      } else {
        calTitle = primaryTask.title;
        calSubtitle = '${primaryTask.time ?? "시간 자유"} · ${primaryTask.repeatSummary}';
        calSubtitleShort = primaryTask.time ?? '오늘';
        calBtnTitle = primaryTask.isCompleted ? '완료' : '체크';
        calAllDone = primaryTask.isCompleted ? 'true' : 'false';
        calAction = 'hagomwidget://checktask?id=${Uri.encodeComponent(primaryTask.id)}';
      }

      await HomeWidget.saveWidgetData<String>('calendar_tag', calTag);
      await HomeWidget.saveWidgetData<String>('calendar_progress', calProgress);
      await HomeWidget.saveWidgetData<String>('calendar_title', calTitle);
      await HomeWidget.saveWidgetData<String>('calendar_subtitle', calSubtitle);
      await HomeWidget.saveWidgetData<String>('calendar_subtitle_short', calSubtitleShort);
      await HomeWidget.saveWidgetData<String>('calendar_btn_title', calBtnTitle);
      await HomeWidget.saveWidgetData<String>('calendar_all_done', calAllDone);
      await HomeWidget.saveWidgetData<String>('calendar_action', calAction);

      final remainingTasks = todayTasks.where((t) => t.id != primaryTask?.id).toList();
      final orderedTasks = [
        ...remainingTasks.where((t) => !t.isCompleted),
        ...remainingTasks.where((t) => t.isCompleted),
      ];
      for (int i = 0; i < 6; i++) {
        final n = i + 1;
        if (i < orderedTasks.length) {
          final t = orderedTasks[i];
          final timeStr = t.time != null ? ' (${t.time})' : '';
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_text', '${t.title}$timeStr');
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_short', t.title);
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_done', t.isCompleted ? 'true' : 'false');
          await HomeWidget.saveWidgetData<String>(
            'cal_row_${n}_action',
            'hagomwidget://checktask?id=${Uri.encodeComponent(t.id)}',
          );
        } else {
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_text', '');
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_short', '');
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_done', 'false');
          await HomeWidget.saveWidgetData<String>('cal_row_${n}_action', '');
        }
      }
      await HomeWidget.updateWidget(name: calendarProvider, androidName: calendarProvider);

      // -------------------------------------------------------------
      // 5) 4x4 한 달 기록 달력 위젯
      // -------------------------------------------------------------
      // 5) 4x4 한 달 기록 달력 위젯 (이전달/다음달 이동 오프셋 반영)
      // -------------------------------------------------------------
      final offset = state.widgetMonthOffset;
      final displayMonth = DateTime(now.year, now.month + offset, 1);
      final monthStr = '${displayMonth.year}년 ${displayMonth.month}월 기록 달력';

      // 🌟 [핵심 UX]: 위젯에서 특정 날짜를 탭해 선택 중인 경우 해당 날짜의 복약/습관/할일 요약 표시, 아니면 오늘치 표시
      final selDate = state.widgetSelectedDate;
      final targetDate = selDate ?? now;
      final isInspectingOtherDay = (targetDate.year != now.year || targetDate.month != now.month || targetDate.day != now.day);
      final isTargetFuture = targetDate.isAfter(DateTime(now.year, now.month, now.day));

      final targetSlots = <_MedSlotEntry>[];
      for (final med in state.medications) {
        if (!med.isDueOn(targetDate)) continue;
        for (int i = 0; i < med.doseSlots.length; i++) {
          final isDone = state.isSlotCompletedForDay(targetDate, med.id, i);
          targetSlots.add(_MedSlotEntry(med: med, slotIndex: i, slot: DoseSlot(label: med.doseSlots[i].label, scheduledTime: med.doseSlots[i].scheduledTime, isCompleted: isDone)));
        }
      }
      final targetCompMeds = isTargetFuture ? 0 : targetSlots.where((e) => e.slot.isCompleted).length;
      final targetDueHabits = state.habits.where((h) => h.isDueOn(targetDate)).toList();
      final targetDoneHabits = isTargetFuture ? 0 : targetDueHabits.where((h) => (state.getHabitScoreForDay(targetDate, h.id) ?? 0.0) >= 1.0).length;
      final targetTasks = state.getTasksForDay(targetDate);
      final targetPendingTasks = targetTasks.where((t) => !t.isCompleted).length;

      final datePrefix = isInspectingOtherDay ? '${targetDate.month}/${targetDate.day} ' : '';
      final monthMeds = isTargetFuture
          ? '${datePrefix}복약 ${targetSlots.length}개 예정'
          : '${datePrefix}복약 $targetCompMeds/${targetSlots.length} 완료';
      final monthHabits = isTargetFuture
          ? '${datePrefix}습관 ${targetDueHabits.length}개 예정'
          : '${datePrefix}습관 $targetDoneHabits/${targetDueHabits.length} 완료';
      final monthTasks = targetTasks.isEmpty
          ? '0개'
          : (isTargetFuture ? '${targetTasks.length}개 예정' : (targetPendingTasks > 0 ? '$targetPendingTasks개 남음' : '모두 완료'));

      await HomeWidget.saveWidgetData<String>('month_title', monthStr);
      await HomeWidget.saveWidgetData<String>('month_meds', monthMeds);
      await HomeWidget.saveWidgetData<String>('month_habits', monthHabits);
      await HomeWidget.saveWidgetData<String>('month_tasks', monthTasks);
      final targetDateIso = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('month_inspecting_iso', isInspectingOtherDay ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_date', selDate != null ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_day', selDate != null ? selDate.day.toString() : '');
      final todayOnly = DateTime(now.year, now.month, now.day);
      // 🌟 [어떤 달이든 100% 실제 달력 반영]:
      // 1일의 시작 요일(일=0, 월=1, ..., 토=6)과 해당 월의 총 일수(28~31일)를 정밀 계산!
      final firstDayWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday % 7; // 일요일=0
      final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day; // 이번달 말일

      for (int i = 0; i < 42; i++) {
        final dayNum = i - firstDayWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          // 이전달/다음달 빈 셀
          await HomeWidget.saveWidgetData<String>('cell_${i}_text', '');
          await HomeWidget.saveWidgetData<String>('cell_${i}_status', 'empty');
          await HomeWidget.saveWidgetData<String>('cell_${i}_day', '');
          await HomeWidget.saveWidgetData<String>('cell_${i}_date', '');
          continue;
        }

        final cellDate = DateTime(displayMonth.year, displayMonth.month, dayNum);
        final isTodayCell = (cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day);
        final isFutureCell = cellDate.isAfter(todayOnly);
        final isBeforeTrack = state.isBeforeTrackingStart(cellDate);
        final tasks = state.getTasksForDay(cellDate);
        final hasT = tasks.isNotEmpty;

        String status = '';
        if (isTodayCell) {
          final mRate = state.getMedRateForDay(cellDate);
          final hRate = state.getHabitRateForDay(cellDate);
          if (!isBeforeTrack && mRate != null && mRate >= 1.0 && hRate != null && hRate >= 1.0) {
            status = hasT ? 'today_done_pin' : 'today_done';
          } else {
            status = hasT ? 'today_pin' : 'today';
          }
        } else if (!isBeforeTrack && !isFutureCell) {
          final mRate = state.getMedRateForDay(cellDate);
          final hRate = state.getHabitRateForDay(cellDate);
          final isMissedP = state.hasMissedPrescriptionForDay(cellDate);

          if (mRate != null && mRate >= 1.0 && hRate != null && hRate >= 1.0) {
            status = hasT ? 'all_done_pin' : 'all_done';
          } else if (isMissedP) {
            status = hasT ? 'missed_med_pin' : 'missed_med';
          } else if (mRate != null && mRate > 0.0) {
            status = hasT ? 'partial_pin' : 'partial';
          } else if (hasT) {
            status = 'pin_only';
          }
        } else if (hasT) {
          status = 'pin_only';
        }

        final dateIso = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        await HomeWidget.saveWidgetData<String>('cell_${i}_text', dayNum.toString());
        await HomeWidget.saveWidgetData<String>('cell_${i}_status', status);
        await HomeWidget.saveWidgetData<String>('cell_${i}_day', dayNum.toString());
        await HomeWidget.saveWidgetData<String>('cell_${i}_date', dateIso);
      }

      // 달력 위젯에 선택된 날짜(또는 오늘) 할일 전체 목록 전달 (최대 5개)
      for (int i = 0; i < 5; i++) {
        final n = i + 1;
        if (i < targetTasks.length) {
          final t = targetTasks[i];
          final timeStr = t.time != null ? ' (${t.time})' : '';
          final check = t.isCompleted ? '완료' : '예정';
          await HomeWidget.saveWidgetData<String>(
            'month_today_task_$n',
            '${t.title}$timeStr - $check',
          );
        } else {
          await HomeWidget.saveWidgetData<String>('month_today_task_$n', '');
        }
      }

      await HomeWidget.updateWidget(name: monthCalendarProvider, androidName: monthCalendarProvider);
    } catch (e) {
      debugPrint('Native widget update error: $e');
    }
  }
}

class _MedSlotEntry {
  final MedicationItem med;
  final int slotIndex;
  final DoseSlot slot;
  _MedSlotEntry({required this.med, required this.slotIndex, required this.slot});
}
