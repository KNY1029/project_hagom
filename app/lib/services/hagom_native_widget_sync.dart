import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/medication_item.dart';
import '../models/task_item.dart';
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
      // Save accent colors before providers refresh from HomeWidget preferences.
      // -------------------------------------------------------------
      // 1) 마스코트 응원 위젯 (9단계 상태 지원)
      // -------------------------------------------------------------
      const List<Map<String, String>> mascotStages = [
        {
          'badge': '1. 기대',
          'quote': '유저가 접속해서 기록을 이어갈 것이라 믿고 웃어주는 모습',
          'sub': '비처벌적 푸시',
          'image': 'hagom_widget_stage_1',
        },
        {
          'badge': '2. 기다림',
          'quote': '생각보다 유저의 귀환이 늦어져서 슬슬 초조해지는 모습',
          'sub': '하곰이와 상호작용할 도덕적 의무감 부여',
          'image': 'hagom_widget_stage_2',
        },
        {
          'badge': '3. 부담',
          'quote': '어째서 돌아오지 않는지 알고 싶어하는 모습',
          'sub': '앱 접속이 오래 끊겼다는 걸 확대이미지를 통해 강조',
          'image': 'hagom_widget_stage_3',
        },
        {
          'badge': '4. 당황',
          'quote': '정말로 발걸음이 끊겼다는 걸 받아들이지 못하는 모습',
          'sub': '하곰이의 불안과 당혹감',
          'image': 'hagom_widget_stage_4',
        },
        {
          'badge': '5. 분노',
          'quote': '하곰이의 듀오링고적 면 살짝 보여주고 싶었음',
          'sub': '흑화 가능하다는 가능성 시사',
          'image': 'hagom_widget_stage_5',
        },
        {
          'badge': '6. 슬픔',
          'quote': '눈물이 점점 차오르는 모습',
          'sub': '어 한번 들어가봐야 하나 싶도록 존재감 어필',
          'image': 'hagom_widget_stage_6',
        },
        {
          'badge': '7. 피로',
          'quote': '다 울고 나서 바싹 마른 모습',
          'sub': '기존 이미지와 다르게 망가지는 표현으로 재접속 시도',
          'image': 'hagom_widget_stage_7',
        },
        {
          'badge': '8. 절망',
          'quote': '극적인 표현과 명암대비로 시선 붙잡기',
          'sub': '시선 붙잡고 재접속 유도',
          'image': 'hagom_widget_stage_8',
        },
        {
          'badge': '9. 붕괴',
          'quote': '최종단계로 완전히 고장난/고사한 모습',
          'sub': '다마고치 사망 같은 무게감의 엔딩',
          'image': 'hagom_widget_stage_9',
        },
      ];

      final currentStage = mascotStages[state.mascotStageIndex.clamp(0, mascotStages.length - 1)];

      await HomeWidget.saveWidgetData<String>('mascot_badge', currentStage['badge']!);
      await HomeWidget.saveWidgetData<String>('mascot_quote', currentStage['quote']!);
      await HomeWidget.saveWidgetData<String>('mascot_sub', currentStage['sub']!);
      await HomeWidget.saveWidgetData<String>('mascot_image', currentStage['image']!);

      await HomeWidget.updateWidget(
        name: mascotProvider,
        androidName: mascotProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$mascotProvider',
      );
      // -------------------------------------------------------------
      // 2) 복약 관리 위젯
      // -------------------------------------------------------------
      final totalMeds = state.totalDoseSlots;
      final compMeds = state.completedDoseSlots;
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
      await HomeWidget.updateWidget(
        name: medsProvider,
        androidName: medsProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$medsProvider',
      );
      // -------------------------------------------------------------
      // 3) 습관 관리 위젯
      // -------------------------------------------------------------
      final todayHabits = state.habits.where((h) => h.isDueToday).toList();
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
      await HomeWidget.updateWidget(
        name: habitsProvider,
        androidName: habitsProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$habitsProvider',
      );
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
      await HomeWidget.updateWidget(
        name: calendarProvider,
        androidName: calendarProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$calendarProvider',
      );

      // -------------------------------------------------------------
      // 5) 4x4 한 달 기록 달력 위젯
      // -------------------------------------------------------------
      // 5) 4x4 한 달 기록 달력 위젯 (이전달/다음달 이동 오프셋 반영)
      // -------------------------------------------------------------
      final offset = state.widgetMonthOffset;
      final displayMonth = DateTime(now.year, now.month + offset, 1);
      final monthStr = '${displayMonth.year}년 ${displayMonth.month}월 기록 달력';
      final monthShortStr = '${displayMonth.month}월';
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

      final monthMeds = isTargetFuture
          ? '복약 ${targetSlots.length}개 예정'
          : '복약 $targetCompMeds/${targetSlots.length} 완료';
      final monthHabits = isTargetFuture
          ? '습관 ${targetDueHabits.length}개 예정'
          : '습관 $targetDoneHabits/${targetDueHabits.length} 완료';

      // 🌟 [할일 라벨 통일]: MM/dd 두 자리(01/30, 11/07 등) 고정 폭 표기로 텍스트 덜컹거림 원천 차단!
      final todayOnly = DateTime(now.year, now.month, now.day);
      final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final mStr = targetDate.month.toString().padLeft(2, '0');
      final dStr = targetDate.day.toString().padLeft(2, '0');
      final String taskSectionLabel;
      if (targetDateOnly.isBefore(todayOnly)) {
        taskSectionLabel = '$mStr/$dStr 그날의 한일';
      } else if (targetDateOnly.isAfter(todayOnly)) {
        taskSectionLabel = '$mStr/$dStr 그날의 할일';
      } else {
        taskSectionLabel = '$mStr/$dStr 오늘의 할일';
      }

      // 할일 요약도 복약/습관처럼 '완료수/전체수 완료' 형식으로 완벽 통일
      final targetDoneTasks = targetTasks.where((t) => t.isCompleted).length;
      final monthTasks = targetTasks.isEmpty
          ? '0개'
          : (isTargetFuture ? '${targetTasks.length}개 예정' : '$targetDoneTasks/${targetTasks.length} 완료');

      await HomeWidget.saveWidgetData<String>('month_title', monthStr);
      await HomeWidget.saveWidgetData<String>('month_title_short', monthShortStr);
      await HomeWidget.saveWidgetData<String>('month_meds', monthMeds);
      await HomeWidget.saveWidgetData<String>('month_habits', monthHabits);
      await HomeWidget.saveWidgetData<String>('month_tasks', monthTasks);
      await HomeWidget.saveWidgetData<String>('month_tasks_label', taskSectionLabel);
      final targetDateIso = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('month_inspecting_iso', isInspectingOtherDay ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_date', selDate != null ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_day', selDate != null ? selDate.day.toString() : '');
      // 🌟 [어떤 달이든 100% 실제 달력 반영]:
      // 1일의 시작 요일(일=0, 월=1, ..., 토=6)과 해당 월의 총 일수(28~31일)를 정밀 계산!
      final firstDayWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday % 7; // 일요일=0
      final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day; // 이번달 말일

      // 🌟 [성능 극대화]: 168개의 saveWidgetData를 직렬 await 하지 않고 Future.wait 병렬 배치 처리!
      final List<Future<bool?>> batchSaves = [];

      for (int i = 0; i < 42; i++) {
        final dayNum = i - firstDayWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_text', ''));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_status', 'empty'));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_day', ''));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_date', ''));
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
          final isHabitDone = hRate != null && hRate >= 1.0;
          final isMedDone = mRate != null && mRate >= 1.0;

          if (isHabitDone) {
            // 습관 완료 (배경 연초록)
            if (isMedDone) {
              status = hasT ? 'hdone_mdone_pin' : 'hdone_mdone';
            } else if (isMissedP) {
              status = hasT ? 'hdone_mmissed_pin' : 'hdone_mmissed';
            } else if (mRate != null && mRate > 0.0) {
              status = hasT ? 'hdone_mpartial_pin' : 'hdone_mpartial';
            } else {
              status = hasT ? 'all_done_pin' : 'all_done'; // 습관만 완료 (초록 배경만)
            }
          } else {
            // 습관 미완료 (배경 흰색)
            if (isMedDone) {
              status = hasT ? 'mdone_pin' : 'mdone';
            } else if (isMissedP) {
              status = hasT ? 'missed_med_pin' : 'missed_med';
            } else if (mRate != null && mRate > 0.0) {
              status = hasT ? 'partial_pin' : 'partial';
            } else if (hasT) {
              status = 'pin_only';
            }
          }
        } else if (hasT) {
          status = 'pin_only';
        }

        final dateIso = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_text', dayNum.toString()));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_status', status));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_day', dayNum.toString()));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_date', dateIso));
      }

      await Future.wait(batchSaves);

      // 🌟 [할일 정렬 및 전달]:
      // 1) 미완료(false) 항목을 완료(true) 항목보다 최우선 정렬
      // 2) 중요 정보인 '(시간) - 상태'를 보존하며 긴 제목만 스마트하게 말줄임(...)
      final sortedTasks = List<TaskItem>.from(targetTasks)..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1; // 미완료 우선!
        }
        return 0;
      });

      for (int i = 0; i < 10; i++) {
        final n = i + 1;
        if (i < sortedTasks.length) {
          final t = sortedTasks[i];
          final timeStr = t.time != null ? ' (${t.time})' : '';
          final check = t.isCompleted ? '완료' : '예정';
          final suffix = '$timeStr - $check';

          // 제목이 너무 길면 (시간)-상태를 지키고 앞 제목만 스마트하게 말줄임(...)
          String title = t.title.trim();
          if (title.length > 20) {
            title = '${title.substring(0, 18)}...';
          }
          await HomeWidget.saveWidgetData<String>('month_today_task_$n', '$title$suffix');
        } else {
          await HomeWidget.saveWidgetData<String>('month_today_task_$n', '');
        }
      }
      await HomeWidget.updateWidget(
        name: monthCalendarProvider,
        androidName: monthCalendarProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$monthCalendarProvider',
      );
    } catch (e) {
      debugPrint('Native widget update error: $e');
    }
  }

  /// ⚡ [초고속 단독 갱신]: 달력 날짜 탭 또는 월 이동 시 다른 4개 위젯 연산을 건너뛰고 달력 위젯만 즉시 갱신!
  static Future<void> updateMonthCalendarOnly(AppStateManager state) async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      final offset = state.widgetMonthOffset;
      final displayMonth = DateTime(now.year, now.month + offset, 1);
      final monthStr = '${displayMonth.year}년 ${displayMonth.month}월 기록 달력';
      final monthShortStr = '${displayMonth.month}월';
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

      final monthMeds = isTargetFuture
          ? '복약 ${targetSlots.length}개 예정'
          : '복약 $targetCompMeds/${targetSlots.length} 완료';
      final monthHabits = isTargetFuture
          ? '습관 ${targetDueHabits.length}개 예정'
          : '습관 $targetDoneHabits/${targetDueHabits.length} 완료';

      final todayOnly = DateTime(now.year, now.month, now.day);
      final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final mStr = targetDate.month.toString().padLeft(2, '0');
      final dStr = targetDate.day.toString().padLeft(2, '0');
      final String taskSectionLabel;
      if (targetDateOnly.isBefore(todayOnly)) {
        taskSectionLabel = '$mStr/$dStr 그날의 한일';
      } else if (targetDateOnly.isAfter(todayOnly)) {
        taskSectionLabel = '$mStr/$dStr 그날의 할일';
      } else {
        taskSectionLabel = '$mStr/$dStr 오늘의 할일';
      }

      final targetDoneTasks = targetTasks.where((t) => t.isCompleted).length;
      final monthTasks = targetTasks.isEmpty
          ? '0개'
          : (isTargetFuture ? '${targetTasks.length}개 예정' : '$targetDoneTasks/${targetTasks.length} 완료');

      await HomeWidget.saveWidgetData<String>('month_title', monthStr);
      await HomeWidget.saveWidgetData<String>('month_title_short', monthShortStr);
      await HomeWidget.saveWidgetData<String>('month_meds', monthMeds);
      await HomeWidget.saveWidgetData<String>('month_habits', monthHabits);
      await HomeWidget.saveWidgetData<String>('month_tasks', monthTasks);
      await HomeWidget.saveWidgetData<String>('month_tasks_label', taskSectionLabel);
      final targetDateIso = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('month_inspecting_iso', isInspectingOtherDay ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_date', selDate != null ? targetDateIso : '');
      await HomeWidget.saveWidgetData<String>('month_selected_day', selDate != null ? selDate.day.toString() : '');

      final firstDayWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday % 7;
      final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;

      final List<Future<bool?>> batchSaves = [];
      for (int i = 0; i < 42; i++) {
        final dayNum = i - firstDayWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_text', ''));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_status', 'empty'));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_day', ''));
          batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_date', ''));
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
          final isHabitDone = hRate != null && hRate >= 1.0;
          final isMedDone = mRate != null && mRate >= 1.0;

          if (isHabitDone) {
            // 습관 완료 (배경 연초록)
            if (isMedDone) {
              status = hasT ? 'hdone_mdone_pin' : 'hdone_mdone';
            } else if (isMissedP) {
              status = hasT ? 'hdone_mmissed_pin' : 'hdone_mmissed';
            } else if (mRate != null && mRate > 0.0) {
              status = hasT ? 'hdone_mpartial_pin' : 'hdone_mpartial';
            } else {
              status = hasT ? 'all_done_pin' : 'all_done'; // 습관만 완료
            }
          } else {
            // 습관 미완료 (배경 흰색)
            if (isMedDone) {
              status = hasT ? 'mdone_pin' : 'mdone';
            } else if (isMissedP) {
              status = hasT ? 'missed_med_pin' : 'missed_med';
            } else if (mRate != null && mRate > 0.0) {
              status = hasT ? 'partial_pin' : 'partial';
            } else if (hasT) {
              status = 'pin_only';
            }
          }
        } else if (hasT) {
          status = 'pin_only';
        }

        final dateIso = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_text', dayNum.toString()));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_status', status));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_day', dayNum.toString()));
        batchSaves.add(HomeWidget.saveWidgetData<String>('cell_${i}_date', dateIso));
      }
      await Future.wait(batchSaves);

      final sortedTasks = [
        ...targetTasks.where((t) => !t.isCompleted),
        ...targetTasks.where((t) => t.isCompleted),
      ];

      for (int i = 0; i < 6; i++) {
        final n = i + 1;
        if (i < sortedTasks.length) {
          final t = sortedTasks[i];
          final timeStr = t.time != null ? ' (${t.time})' : '';
          final check = t.isCompleted ? '완료' : '예정';
          final suffix = '$timeStr - $check';

          String title = t.title.trim();
          if (title.length > 20) {
            title = '${title.substring(0, 18)}...';
          }
          await HomeWidget.saveWidgetData<String>('month_today_task_$n', '$title$suffix');
        } else {
          await HomeWidget.saveWidgetData<String>('month_today_task_$n', '');
        }
      }

      await HomeWidget.updateWidget(
        name: monthCalendarProvider,
        androidName: monthCalendarProvider,
        qualifiedAndroidName: 'com.healthpharma.hagom_app.$monthCalendarProvider',
      );
    } catch (e) {
      debugPrint('Fast month calendar update error: $e');
    }
  }
}

class _MedSlotEntry {
  final MedicationItem med;
  final int slotIndex;
  final DoseSlot slot;
  _MedSlotEntry({required this.med, required this.slotIndex, required this.slot});
}
