import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../models/task_item.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/app_time_picker.dart';

/// 📅 [달력 & 할일 탭: 복약(바)·습관(바탕)·할일(핀) 3대 요소 1:1 독립 규격]
///
/// 1. 날짜 셀 컬러링 알고리즘:
///    - 습관(바탕색): 100% 실천 시 셀 전체 연초록 파스텔 틴트(#E6F8F0) / 미완료 시 흰색
///    - 복약(하단 바, 3.5px): 100% 완료 시 딥 포레스트 그린 바(#044E36) / 처방약 미복용 시 레드 바(#EF4444) / 일부 미완료 시 파스텔 연보라 바(#B39DDB)
///    - 할일(모서리 핀, 5.5px): 완료 시 딥 포레스트 그린 핀(#044E36) / 미완료 시 밝은 파스텔 연보라 핀(#C4B5FD)
///    - 오늘 날짜: 보라색 테두리(#7B61A8)
///    - 미래 날짜: 진행도 바/틴트 일체 미표시 (완전 깨끗한 초기화)
/// 2. 데일리 상세 아코디언:
///    - 날짜 터치 시 하단에 그날의 종합 복약/습관/할일 브리핑 펼침
///    - 과거 날짜 복약 완료 사후 수정 지원 ➔ "소급 축하 토스트" 즉시 발동!
/// 3. 할일 관리:
///    - 체크박스 완료 토글
///    - [+ 할일 추가] 모달 지원
class CalendarTabView extends StatefulWidget {
  const CalendarTabView({super.key});

  @override
  State<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends State<CalendarTabView> {
  final AppStateManager _state = AppStateManager();
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _isMedDetailsExpanded = false; // 복약 상세 펼침 여부 (기본은 접힘)
  bool _isHabitDetailsExpanded = false; // 습관 상세 펼침 여부 (기본은 접힘)
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
    _state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (_state.requestedCalendarDate != null) {
      final req = _state.requestedCalendarDate!;
      setState(() {
        _selectedDate = DateTime(req.year, req.month, req.day);
        _currentMonth = DateTime(req.year, req.month, 1);
      });
      _state.requestedCalendarDate = null;
    } else {
      setState(() {});
    }
  }

  // 월 이동
  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
        1,
      );
    });
  }

  // 오늘로 이동
  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  TimeOfDay? _parseTaskTime(String value) {
    final match = RegExp(r'^(오전|오후)\s*(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    var hour = int.tryParse(match.group(2) ?? '');
    final minute = int.tryParse(match.group(3) ?? '');
    if (hour == null || minute == null || hour < 1 || hour > 12 || minute > 59) {
      return null;
    }
    if (match.group(1) == '오후' && hour != 12) hour += 12;
    if (match.group(1) == '오전' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _showCalendarLegend() {
    Widget row({required Widget marker, required String label}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 42, child: Center(child: marker)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
    Widget bar(Color color) => Container(
      width: 28,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    Widget dot(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    Widget cell(Color color) => Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.divider),
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('달력 표시 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(marker: bar(AppColors.missedRed), label: '처방약 미복용'),
            row(marker: bar(AppColors.successGreen), label: '복약 완료'),
            row(marker: bar(const Color(0xFF9CA3AF)), label: '복약 미완료'),
            const Divider(),
            row(marker: dot(AppColors.successGreen), label: '할일 완료'),
            row(marker: dot(const Color(0xFFD1D5DB)), label: '할일 미완료'),
            const Divider(),
            row(marker: cell(AppColors.successBg), label: '습관 완료'),
            row(marker: cell(Colors.white), label: '습관 미완료'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 🌟 [전체 달 공통 완료 초록 컬러]: 5월의 싱그럽고 선명한 에메랄드 그린 (Emerald 600 #059669)으로 통일!
  Color _getDoneGreenColor(int m) {
    return AppColors.successGreen;
  }

  // 할일/한일 추가 및 수정 모달
  void _showTaskModal({TaskItem? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    String? selectedTime = task?.time;
    // 다중 선택 알림 목록
    final List<String> selectedReminders = List<String>.from(
      task?.reminders ?? ['정시', '하루 전'],
    );
    if (selectedTime == null) {
      selectedReminders
        ..remove('정시')
        ..remove('30분 전')
        ..remove('1시간 전')
        ..removeWhere((item) => item.contains('시간') || item.contains('분'));
      if (!selectedReminders.contains('하루 전')) selectedReminders.add('하루 전');
    }
    bool isRepeated = task?.isRepeated ?? false;
    String repeatCycle = task?.repeatCycle ?? '매주 특정 요일';
    final List<String> selectedRepeatDays = List<String>.from(
      task?.repeatDays ?? [],
    );
    final availableReminders = selectedTime == null
        ? ['당일', '하루 전']
        : ['정시', '30분 전', '1시간 전', '하루 전'];
    final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = _selectedDate.isBefore(today);
    final modalActionName = task != null
        ? '일정 수정'
        : (isPast ? '한일 추가' : '할일 추가');

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (mCtx) => StatefulBuilder(
        builder: (ctx, setMState) => Container(
          margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.month}월 ${_selectedDate.day}일 $modalActionName',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: task == null,
                  decoration: InputDecoration(
                    hintText: '',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primaryPurple),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 시간 선택 버튼
                Row(
                  children: [
                    Text(
                      '예정 시각',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                        onPressed: () => setMState(() {
                          selectedTime = null;
                          selectedReminders
                            ..remove('정시')
                            ..remove('30분 전')
                            ..remove('1시간 전')
                            ..removeWhere((item) => item.contains('시간') || item.contains('분'));
                          if (!selectedReminders.contains('하루 전')) {
                            selectedReminders.add('하루 전');
                          }
                          availableReminders
                            ..clear()
                            ..addAll(['당일', '하루 전']);
                        }),
                        child: const Text('시각 설정 안 함'),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final t = await AppTimePicker.show(
                          context,
                          initialTime: selectedTime == null ? null : _parseTaskTime(selectedTime!),
                          title: '예정 시각 설정',
                        );
                        if (t == null) return;
                        setMState(() {
                          final p = t.period == DayPeriod.am ? '오전' : '오후';
                          final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                          selectedTime = '$p $h:${t.minute.toString().padLeft(2, '0')}';
                          availableReminders..clear()..addAll(['정시', '30분 전', '1시간 전', '하루 전']);
                          selectedReminders.remove('당일');
                          if (selectedReminders.isEmpty) selectedReminders.add('정시');
                        });
                      },
                      child: Text(selectedTime ?? '시각 미설정'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 🔔 알림 설정
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '알림 설정 (중복 선택 가능)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                        // 🌟 복합 시간(N시간 N분 전) 및 N일 전 직접 추가 다이얼로그
                        String mode = selectedTime == null ? '일' : '시간/분';
                        int? hours;
                        int? minutes;
                        int days = 1;
                        showDialog(
                          context: context,
                          builder: (dCtx) => StatefulBuilder(
                            builder: (ctx, setDState) => AlertDialog(
                              title: const Text(
                                '직접 알림 추가',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 모드 선택 탭
                                  Row(
                                    children: [
                                      if (selectedTime != null)
                                        ChoiceChip(
                                        label: const Text('시간 / 분 전'),
                                        selected: mode == '시간/분',
                                        showCheckmark: false,
                                        selectedColor: AppColors.lightLavender,
                                        onSelected: (_) =>
                                            setDState(() => mode = '시간/분'),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('며칠 전'),
                                        selected: mode == '일',
                                        showCheckmark: false,
                                        selectedColor: AppColors.lightLavender,
                                        onSelected: (_) =>
                                            setDState(() => mode = '일'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  if (mode == '시간/분')
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) =>
                                                hours = int.tryParse(v),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '시간',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 50,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) =>
                                                minutes = int.tryParse(v),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '분 전',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) =>
                                                days = int.tryParse(v) ?? 0,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '일 전',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dCtx).pop(),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    String customRem = '';
                                    final h = hours ?? 0;
                                    final m = minutes ?? 0;
                                    if (mode == '시간/분') {
                                      if (selectedTime == null) return;
                                      if (h > 0 && m > 0) {
                                        customRem = '$h시간 $m분 전';
                                      } else if (h > 0) {
                                        customRem = '$h시간 전';
                                      } else if (m > 0) {
                                        customRem = '$m분 전';
                                      } else {
                                        return;
                                      }
                                    } else {
                                      if (days < 1) return;
                                      customRem = '$days일 전';
                                    }

                                    if (!availableReminders.contains(
                                      customRem,
                                    )) {
                                      availableReminders.add(customRem);
                                    }
                                    if (!selectedReminders.contains(
                                      customRem,
                                    )) {
                                      selectedReminders.add(customRem);
                                    }
                                    setMState(() {});
                                    Navigator.of(dCtx).pop();
                                  },
                                  child: const Text(
                                    '추가',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        },
                        child: Text(
                          '직접 추가',
                          style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availableReminders.map((rem) {
                    final isChecked = selectedReminders.contains(rem);
                    return ChoiceChip(
                      label: Text(rem),
                      selected: isChecked,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isChecked
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isChecked
                            ? AppColors.primaryPurple
                            : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.lightLavender,
                      backgroundColor: const Color(0xFFF9FAFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isChecked
                              ? AppColors.primaryPurple.withValues(alpha: 0.5)
                              : AppColors.divider,
                        ),
                      ),
                      onSelected: (val) {
                        setMState(() {
                          if (val) {
                            if (selectedTime == null &&
                                (rem == '정시' ||
                                    rem.contains('시간') ||
                                    rem.contains('분'))) {
                              return;
                            }
                            selectedReminders.add(rem);
                          } else {
                            selectedReminders.remove(rem);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 🔁 반복 설정 섹션
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '반복 설정',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Switch(
                      value: isRepeated,
                      activeThumbColor: AppColors.primaryPurple,
                      onChanged: (val) => setMState(() => isRepeated = val),
                    ),
                  ],
                ),
                if (isRepeated) ...[
                  const SizedBox(height: 6),
                  // 반복 주기 라디오/칩 (매일, 특정 요일, 매달 이 날)
                  Wrap(
                    spacing: 8,
                    children: ['매일', '매주 특정 요일', '매달 이 날'].map((cycle) {
                      final isSel = repeatCycle == cycle;
                      return ChoiceChip(
                        label: Text(cycle),
                        selected: isSel,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel
                              ? AppColors.primaryPurple
                              : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.lightLavender,
                        backgroundColor: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primaryPurple.withValues(alpha: 0.5)
                                : AppColors.divider,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setMState(() => repeatCycle = cycle);
                        },
                      );
                    }).toList(),
                  ),
                  if (repeatCycle == '매주 특정 요일') ...[
                    const SizedBox(height: 8),
                    // 요일 다중 선택 칩
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekDayLabels.map((day) {
                        final isDaySel = selectedRepeatDays.contains(day);
                        return InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            setMState(() {
                              if (isDaySel) {
                                selectedRepeatDays.remove(day);
                              } else {
                                selectedRepeatDays.add(day);
                              }
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDaySel
                                  ? AppColors.lightLavender
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDaySel
                                    ? AppColors.primaryPurple
                                    : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isDaySel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isDaySel
                                    ? AppColors.primaryPurple
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      if (task != null) {
                        _state.updateTask(
                          id: task.id,
                          title: titleCtrl.text.trim(),
                          time: selectedTime,
                          reminders: selectedReminders,
                          isRepeated: isRepeated,
                          repeatCycle: repeatCycle,
                          repeatDays: selectedRepeatDays,
                        );
                        Navigator.of(ctx).pop();
                        CelebrationToast.show(
                          context,
                          title: '일정 수정 완료',
                          message: '\'${titleCtrl.text.trim()}\' 내용이 수정되었어요.',
                        );
                      } else {
                        _state.addTask(
                          title: titleCtrl.text.trim(),
                          date: _selectedDate,
                          time: selectedTime,
                          reminders: selectedReminders,
                          isRepeated: isRepeated,
                          repeatCycle: repeatCycle,
                          repeatDays: selectedRepeatDays,
                        );
                        Navigator.of(ctx).pop();
                        CelebrationToast.show(
                          context,
                          title: isPast ? '한일 등록 완료' : '새 일정 등록 완료',
                          message: '\'${titleCtrl.text.trim()}\' 일정이 기록되었어요.',
                        );
                      }
                    },
                    child: Text(
                      task != null ? '수정 완료' : '일정 저장',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskMemoEditor(TaskItem task) async {
    final memoController = TextEditingController(text: task.memo);
    final editable = !_selectedDate.isAfter(DateTime.now());
    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('할일 메모'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: memoController,
              readOnly: !editable,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: '메모를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(editable ? '취소' : '닫기'),
            ),
            if (editable)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(memoController.text),
                child: const Text('저장'),
              ),
          ],
        ),
      );
      if (result != null && mounted) {
        _state.updateTask(
          id: task.id,
          title: task.title,
          time: task.time,
          memo: result,
          reminders: task.reminders,
          isRepeated: task.isRepeated,
          repeatCycle: task.repeatCycle,
          repeatDays: task.repeatDays,
        );
      }
    } finally {
      memoController.dispose();
    }
  }

  // 🌟 과거 복약 완료 기록 시 복용 시간 묻는 다이얼로그 (모름/기억 안 남 포함!)
  void _showPastMedTimeDialog(MedicationItem med, int slotIdx, DoseSlot slot) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(
          '${med.name} ${slot.label} 복용 시간',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedDate.month}월 ${_selectedDate.day}일에 이 약을 언제 복용하셨나요?',
            ),
            const SizedBox(height: 8),
            Text(
              '정확한 시간이 기억나지 않아도 괜찮아요.\n알고 계신 만큼만 기록해도 충분해요.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // 1) 기억 안 남 버튼
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료',
                message: '${med.name} ${slot.label} 복용을 기록했어요 (복용 시간 미지정).',
              );
            },
            child: Text(
              '기억 안 남 (모름)',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          // 2) 예정 시각 그대로 복용 버튼
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료',
                message: '${med.name} ${slot.label} 예정 시각에 잘 챙겨 드셨어요.',
              );
            },
            child: Text(
              '${slot.scheduledTime ?? '예정 시각'}에 복용',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 3) 직접 시간 선택 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              final t = await AppTimePicker.show(
                context,
                initialTime: null,
                title: '${med.name} 복용 시각',
              );
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              final timeStr = t != null
                  ? '${t.period == DayPeriod.am ? '오전' : '오후'} ${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')}'
                  : '복용 완료';
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료',
                message: '${med.name} $timeStr에 복약한 기록을 남겼어요.',
              );
            },
            child: const Text(
              '직접 시간 입력',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 과거 복약 되돌리기 확인 다이얼로그
  void _showPastMedRevertDialog(
    MedicationItem med,
    int slotIdx,
    DoseSlot slot,
  ) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text(
          '복약 상태 되돌리기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_selectedDate.month}월 ${_selectedDate.day}일 \'${med.name} ${slot.label}\' 복약 완료 기록을 미완료(대기)로 되돌릴까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '되돌리기 완료',
                message: '${med.name} ${slot.label} 상태를 미완료로 되돌렸어요.',
              );
            },
            child: const Text(
              '되돌리기 확정',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 과거 습관 되돌리기 확인 다이얼로그
  void _showPastHabitRevertDialog(HabitItem habit) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text(
          '습관 상태 되돌리기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_selectedDate.month}월 ${_selectedDate.day}일 \'${habit.title}\' 실천 상태를 대기로 되돌릴까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '되돌리기 완료',
                message: '\'${habit.title}\' 실천 상태를 대기로 되돌렸어요.',
              );
            },
            child: const Text(
              '되돌리기 확정',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 과거 습관 수정 시 바로 바뀌지 않고 상태를 신중히 선택하는 다이얼로그
  void _showPastHabitChoiceDialog(HabitItem habit, bool isFull, bool isPart) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(
          '\'${habit.title}\' 실천 기록',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_selectedDate.month}월 ${_selectedDate.day}일에 이 습관을 어떻게 실천하셨나요?',
        ),
        actions: [
          // 1) 대기로 되돌리기
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '대기 상태로 변경',
                message: '\'${habit.title}\'을(를) 대기로 변경했어요.',
              );
            },
            child: Text(
              '대기 (미실천)',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          // 2) 조금 실천
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '작은 발걸음 기록',
                message: '조금이라도 실천한 것이 정말 큰 의미가 있어요.',
              );
            },
            child: const Text(
              '조금 실천',
              style: TextStyle(
                color: AppColors.partialText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 3) 완료
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '습관 실천 완료',
                message: '\'${habit.title}\' 목표를 달성했어요. 언제든 멋져요.',
              );
            },
            child: const Text(
              '완료',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday %
        7; // 일요일=0

    final selectedDayTasks = _state.getTasksForDay(_selectedDate);
    final isSelectedDatePast = _selectedDate.isBefore(today);
    final isSelectedDateToday = _selectedDate.isAtSameMomentAs(today);
    final isSelectedDateFuture = _selectedDate.isAfter(today);
    final isSelectedDateBeforeTracking = _state.isBeforeTrackingStart(
      _selectedDate,
    );
    final selectedMedRate = _state.getMedRateForDay(_selectedDate);
    final selectedHabitRate = _state.getHabitRateForDay(_selectedDate);
    final selectedMedComplete =
        !isSelectedDateBeforeTracking &&
        selectedMedRate != null &&
        selectedMedRate >= 1.0;
    final selectedMedPartial =
        !isSelectedDateBeforeTracking &&
        selectedMedRate != null &&
        selectedMedRate > 0.0;
    final selectedHabitComplete =
        !isSelectedDateBeforeTracking &&
        selectedHabitRate != null &&
        selectedHabitRate >= 1.0;
    final selectedHabitPartial =
        !isSelectedDateBeforeTracking &&
        selectedHabitRate != null &&
        selectedHabitRate > 0.0;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. 월 네비게이션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '${_currentMonth.year}년 ${_currentMonth.month}월',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _changeMonth(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _changeMonth(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  icon: Icon(Icons.today, size: 16, color: AppColors.primaryPurple),
                  label: Text(
                    '오늘',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _goToToday,
                ),
                IconButton(
                  tooltip: '달력 표시 안내',
                  onPressed: _showCalendarLegend,
                  icon: const Icon(Icons.info_outline, size: 19),
                  color: AppColors.primaryPurple,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. 6안 캘린더 그리드 컨테이너
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 요일 헤더 (안티-슬롭 폰트 웨이트 정돈: w600으로 단정하게)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '일',
                      style: TextStyle(
                        color: AppColors.missedRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '월',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '화',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '수',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '목',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '금',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '토',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 6),

              // 날짜 셀 그리드
              LayoutBuilder(
                builder: (context, constraints) {
                  // 태블릿에서도 날짜 숫자와 상태 표시가 셀 크기와 함께 커지도록 한다.
                  final calendarScale = (constraints.maxWidth / 336.0).clamp(
                    1.0,
                    1.6,
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 42, // 6주 x 7일
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      // 🌟 전체 달 공통 레이아웃 (8월 비교안: 가로로 긴 독립형 카드)
                      // 칸 자체는 서로 붙지 않고, 하단 바도 각 날짜 안에서만 표시한다.
                      crossAxisSpacing: 0,
                      childAspectRatio: 1.02,
                    ),
                    itemBuilder: (ctx, idx) {
                      final dayOffset = idx - firstWeekday + 1;
                      if (dayOffset < 1 || dayOffset > daysInMonth) {
                        return const SizedBox.shrink(); // 이전/다음달 빈칸
                      }

                      final cellDate = DateTime(
                        _currentMonth.year,
                        _currentMonth.month,
                        dayOffset,
                      );
                      final isToday = cellDate.isAtSameMomentAs(today);
                      final isSelected = cellDate.isAtSameMomentAs(
                        _selectedDate,
                      );
                      final medRate = _state.getMedRateForDay(cellDate);
                      final habitRate = _state.getHabitRateForDay(cellDate);
                      final dayTasks = _state.getTasksForDay(cellDate);
                      final hasTasks = dayTasks.isNotEmpty;
                      final isTasksAllDone =
                          hasTasks && dayTasks.every((t) => t.isCompleted);
                      final hasMissedPrescription = _state
                          .hasMissedPrescriptionForDay(cellDate);
                      // 🌟 26년 12월 등 미래 날짜에 하단 바 추가되던 예외를 완전히 떼어내고, 실제 미래 날짜는 깨끗하게 비표시!
                      final isFuture = cellDate.isAfter(today);
                      final isBeforeTracking = _state.isBeforeTrackingStart(
                        cellDate,
                      );

                      // 🌟 [전체 달 공통 레이아웃 & 5월 컬러 팔레트 전면 통일]:
                      // - 레이아웃: 8월 비교안 (가로로 긴 독립형 카드, 모서리 8px, 하단 바 좌우 여백 8px)
                      // - 색상: 5월 컬러 팔레트 (완료: 에메랄드 #059669, 미완료: 소프트 쿨그레이 #9CA3AF, 핀: 쿨그레이 #D1D5DB, 처방약 누락: 빨강 #EF4444)
                      final Color currentDoneGreen = AppColors.successGreen;
                      const Color pendingBarColor = Color(0xFF9CA3AF);
                      const Color pendingPinColor = Color(0xFFD1D5DB);
                      final double barThickness = (3.5 * calendarScale).clamp(
                        3.5,
                        5.5,
                      );
                      final BorderRadius cellRadius = BorderRadius.circular(
                        (8 * calendarScale).clamp(8, 12),
                      );
                      final isMed100 = medRate != null && medRate >= 1.0;
                      final isHabit100 =
                          !isFuture &&
                          !isBeforeTracking &&
                          habitRate != null &&
                          habitRate >= 1.0;
                      final selectedBorderWidth = isSelected && isToday
                          ? 3.2
                          : (isSelected ? 1.8 : (isToday ? 1.2 : 0.0));

                      Color medBarColor = currentDoneGreen;
                      bool hasMedBar = false;

                      if (!isFuture && !isBeforeTracking && medRate != null) {
                        if (isMed100) {
                          medBarColor = currentDoneGreen;
                          hasMedBar = true;
                        } else if (!isToday) {
                          if (hasMissedPrescription) {
                            medBarColor = AppColors.missedRed;
                            hasMedBar = true;
                          } else {
                            medBarColor = pendingBarColor;
                            hasMedBar = true;
                          }
                        }
                      }
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = cellDate;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isHabit100
                                ? AppColors.successBg
                                : Colors.white,
                            borderRadius: cellRadius,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : (isToday
                                        ? AppColors.primaryPurple.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.transparent),
                              // 오늘을 선택한 경우에만 현재 위치가 확실히 보이도록 더 굵게 표시한다.
                              width: selectedBorderWidth,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 🌟 [할일 모서리 핀]:
                              // - 할일 전부 완료: 연초록 바탕에서도 선명하게 구분되는 딥 포레스트 그린(Deep Forest Green #044E36)
                              // - 할일 덜 끝냄/미완료: 초록색과 명도 대비가 극명하게 나는 밝고 부드러운 파스텔 연보라(#C4B5FD)
                              if (hasTasks)
                                Positioned(
                                  top: 4 * calendarScale,
                                  right: 4 * calendarScale,
                                  child: Container(
                                    width: 5.5 * calendarScale,
                                    height: 5.5 * calendarScale,
                                    decoration: BoxDecoration(
                                      color: isTasksAllDone
                                          ? currentDoneGreen // 🌟 생생한 완료 초록 반영!
                                          : pendingPinColor, // 🌟 월별 미완료 색상 (연보라 or 쿨그레이)
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                              // 날짜 숫자
                              Center(
                                child: Text(
                                  '$dayOffset',
                                  style: TextStyle(
                                    fontSize: 13 * calendarScale,
                                    fontWeight: (isToday || isSelected)
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    // 전체 완료한 날이라도 일요일이면 빨간색 유지! 평일은 기본 텍스트 색 유지!
                                    color: cellDate.weekday == DateTime.sunday
                                        ? AppColors.missedRed
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              // 🌟 [복약 독립 하단 바 규격 (두께 3.5px 도톰하게 개선)]:
                              // 1) 복약 100% 완료: 할일 핀 완료색과 같은 짙은 딥 포레스트 그린 바 (#044E36)
                              // 2) 처방약 놓친 날: 🚨 선명한 경고 레드 바 (#EF4444)
                              // 3) 일부 복용/일반약 미완료: 차분하고 통일감 있는 연보라 바 (#B39DDB)
                              // - 과거 날짜: 상태에 따라 3가지 바 중 하나 표시
                              // - 오늘 날짜: 아직 하루가 진행 중이므로 완료했을 때만 초록 바를 띄우고 미완료 경고는 보류
                              if (hasMedBar)
                                Positioned(
                                  bottom: 4 * calendarScale,
                                  // 🌟 8월 레이아웃 통일: 좌우 8px 여백, 두께 3.5px, 둥근 모서리
                                  left: 8 * calendarScale,
                                  right: 8 * calendarScale,
                                  child: Container(
                                    height: barThickness,
                                    decoration: BoxDecoration(
                                      color: medBarColor,
                                      borderRadius: BorderRadius.circular(
                                        barThickness / 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. 하단 데일리 종합 아코디언 패널
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 선택 날짜 및 일정 수
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelectedDateToday
                              ? AppColors.lightLavender
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSelectedDateToday
                              ? '오늘'
                              : (isSelectedDatePast ? '지난 기록' : '예정일'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelectedDateToday
                                ? AppColors.primaryPurple
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 일정 추가 버튼
                  InkWell(
                    onTap: () => _showTaskModal(),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isSelectedDatePast ? '한일 추가' : '할일 추가',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 1. 🗓️ [할일 및 일정 영역] - 과거: 그날의 한일, 오늘: 오늘의 할일, 미래: 그날의 할일
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final sel = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  );
                  final String taskHeaderTitle = sel.isBefore(today)
                      ? '그날의 한일'
                      : (sel.isAtSameMomentAs(today) ? '오늘의 할일' : '그날의 할일');

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            taskHeaderTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${selectedDayTasks.length}건)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (selectedDayTasks.isNotEmpty)
                        Text(
                          '${selectedDayTasks.where((t) => !isSelectedDateFuture && t.isCompleted).length}/${selectedDayTasks.length} 완료',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // 할일 목록 리스트
              if (selectedDayTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Center(
                    child: Text(
                      '등록된 일정이 없어요.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) => child,
                  itemCount: selectedDayTasks.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    _state.reorderTasksForDay(_selectedDate, oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final t = selectedDayTasks[index];
                    final taskIsCompleted =
                        !isSelectedDateFuture && t.isCompleted;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('task_${t.id}'),
                      index: index,
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: t.isExpanded
                              ? AppColors.primaryPurple.withValues(alpha: 0.3)
                              : AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                t.isExpanded = !t.isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: taskIsCompleted,
                                    activeColor: AppColors.primaryPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: isSelectedDateFuture
                                        ? null
                                        : (_) {
                                      final wasCompleted = t.isCompleted;
                                      _state.toggleTaskCompleted(t.id);
                                      if (!wasCompleted) {
                                        CelebrationToast.show(
                                          context,
                                          title: '일정 완료',
                                          message: '\'${t.title}\'을(를) 잘 마쳤어요.',
                                        );
                                      } else {
                                        CelebrationToast.show(
                                          context,
                                          title: '일정 완료 취소',
                                          message: '\'${t.title}\' 완료를 취소했어요.',
                                        );
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            decoration: taskIsCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: taskIsCompleted
                                                ? AppColors.textMuted
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (t.time != null ||
                                            t.reminders.isNotEmpty ||
                                            t.isRepeated)
                                          Text(
                                            [
                                              if (t.time != null) t.time!,
                                              if (t.reminders.isNotEmpty)
                                                t.reminderSummary,
                                              if (t.isRepeated) t.repeatSummary,
                                            ].join(' · '),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showTaskMemoEditor(t),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 4,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        '메모',
                                        style: TextStyle(
                                          color: AppColors.primaryPurple,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 🌟 카드를 톡 눌렀을 때만 아래로 펼쳐지는 복약/습관 스타일의 아코디언 메뉴!
                          if (t.isExpanded) ...[
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _showTaskModal(task: t),
                                    child: Text(
                                      '정보 수정',
                                      style: TextStyle(
                                        color: AppColors.primaryPurple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      _state.deleteTask(t.id);
                                      CelebrationToast.show(
                                        context,
                                        title: '삭제 완료',
                                        message: '\'${t.title}\' 일정을 삭제했어요.',
                                      );
                                    },
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(
                                        color: AppColors.neutralDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 2. 💊 [복약 상태 요약 및 과거 기록 수정 아코디언]
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap:
                    (isSelectedDatePast ||
                        isSelectedDateToday ||
                        isSelectedDateFuture)
                    ? () {
                        setState(() {
                          _isMedDetailsExpanded = !_isMedDetailsExpanded;
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '복약 현황',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 전체 완료 여부 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selectedMedComplete
                                  ? AppColors.completedBg
                                  : (selectedMedPartial
                                        ? AppColors.partialOrange.withValues(
                                            alpha: 0.12,
                                          )
                                        : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(5),
                              border: selectedMedComplete
                                  ? Border.all(color: AppColors.completedBorder)
                                  : null,
                            ),
                            child: Text(
                              isSelectedDateBeforeTracking ||
                                  (!isSelectedDateFuture &&
                                      !_state.allMedications.any(
                                        (m) =>
                                            !m.isArchived &&
                                            m.isDueOn(_selectedDate) &&
                                            m.recurrenceSummary != '필요 시' &&
                                            m.recurrenceSummary != '오늘만',
                                      ))
                                  ? '기록 전'
                                  : (isSelectedDateFuture || selectedMedRate == null
                                        ? '기록 대기'
                                        : (selectedMedRate >= 1.0
                                              ? '전체 완료'
                                              : (selectedMedRate > 0.0
                                                    ? '일부 복용'
                                                    : '미복용'))),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: selectedMedComplete
                                    ? AppColors.completedText
                                    : (selectedMedPartial
                                          ? AppColors.partialOrange
                                          : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSelectedDatePast ||
                          isSelectedDateToday ||
                          isSelectedDateFuture)
                        Text(
                          _isMedDetailsExpanded
                              ? '접기'
                              : (isSelectedDatePast ? '수정하기' : '확인하기'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 펼쳤을 때만 나오는 상세 약별 / 회차별 핀셋 수정 카드
              if (_isMedDetailsExpanded) ...[
                const SizedBox(height: 10),
                Column(
                  children: _state.allMedications
                      .where((m) => m.isDueOn(_selectedDate))
                      .map((med) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF3F4F6)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    med.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    med.dosage,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 회차별 칩 (클릭 시 소급 토글 및 하곰이 소급 축하!)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: med.doseSlots
                                    .asMap()
                                    .entries
                                    .where((entry) {
                                      if (med.recurrenceSummary != '필요 시') {
                                        return true;
                                      }
                                      final date = entry.value.takenDate;
                                      return date != null &&
                                          date.year == _selectedDate.year &&
                                          date.month == _selectedDate.month &&
                                          date.day == _selectedDate.day;
                                    })
                                    .map((entry) {
                                      final slotIdx = entry.key;
                                      final slot = entry.value;
                                      final isDone = _state
                                          .isSlotCompletedForDay(
                                            _selectedDate,
                                            med.id,
                                            slotIdx,
                                          );

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: isSelectedDatePast
                                            ? () {
                                                if (!isDone) {
                                                  _showPastMedTimeDialog(
                                                    med,
                                                    slotIdx,
                                                    slot,
                                                  );
                                                } else {
                                                  _showPastMedRevertDialog(
                                                    med,
                                                    slotIdx,
                                                    slot,
                                                  );
                                                }
                                              }
                                            : null, // 오늘 날짜는 확인만 가능 (수정은 복약 탭에서)
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? AppColors.successBg
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isDone
                                                  ? AppColors.successGreen
                                                        .withValues(alpha: 0.4)
                                                  : AppColors.divider,
                                              width: isDone ? 1.2 : 1.0,
                                            ),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final takenTime = _state
                                                  .getSlotTakenTimeForDay(
                                                    _selectedDate,
                                                    med.id,
                                                    slotIdx,
                                                  );
                                              final timePart =
                                                  takenTime != null &&
                                                      takenTime.isNotEmpty
                                                  ? ' ${takenTime.split(' ').last}'
                                                  : (slot.scheduledTime != null
                                                        ? ' ${slot.scheduledTime!.split(' ').last}'
                                                        : '');
                                              final statusText = isDone
                                                  ? '${slot.label}$timePart'
                                                  : (isSelectedDateBeforeTracking
                                                        ? '${slot.label} 기록 전'
                                                        : (isSelectedDateFuture
                                                              ? '${slot.label} 기록 대기'
                                                              : '${slot.label} 미복용'));

                                              return Text(
                                                statusText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isDone
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isDone
                                                      ? AppColors.completedText
                                                      : AppColors.textSecondary,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 3. 🌱 [습관 현황 요약 및 펼침 아코디언]
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap:
                    (isSelectedDatePast ||
                        isSelectedDateToday ||
                        isSelectedDateFuture)
                    ? () {
                        setState(() {
                          _isHabitDetailsExpanded = !_isHabitDetailsExpanded;
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '습관 현황',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 습관 완료 여부 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selectedHabitComplete
                                  ? AppColors.completedBg
                                  : (selectedHabitPartial
                                        ? AppColors.partialOrange.withValues(
                                            alpha: 0.12,
                                          )
                                        : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(5),
                              border: selectedHabitComplete
                                  ? Border.all(color: AppColors.completedBorder)
                                  : null,
                            ),
                            child: Text(
                              isSelectedDateBeforeTracking ||
                                  (!isSelectedDateFuture &&
                                      !_state.allHabits.any(
                                        (h) => !h.isArchived && h.isDueOn(_selectedDate),
                                      ))
                                  ? '기록 전'
                                  : (isSelectedDateFuture || selectedHabitRate == null
                                        ? '기록 대기'
                                        : (selectedHabitRate >= 1.0
                                              ? '전체 달성'
                                              : (selectedHabitRate > 0.0
                                                    ? '${(selectedHabitRate * _state.allHabits.where((h) => h.isDueOn(_selectedDate)).length).toStringAsFixed(1)}/${_state.allHabits.where((h) => h.isDueOn(_selectedDate)).length}개 실천'
                                                    : '미실천'))),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: selectedHabitComplete
                                    ? AppColors.completedText
                                    : (selectedHabitPartial
                                          ? AppColors.partialOrange
                                          : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSelectedDatePast ||
                          isSelectedDateToday ||
                          isSelectedDateFuture)
                        Text(
                          _isHabitDetailsExpanded
                              ? '접기'
                              : (isSelectedDatePast ? '수정하기' : '확인하기'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 펼쳤을 때 나오는 개별 습관 실천 상태 및 소급 체크
              if (_isHabitDetailsExpanded) ...[
                const SizedBox(height: 10),
                Column(
                  children: _state.allHabits
                      .where((h) => h.isDueOn(_selectedDate))
                      .map((habit) {
                        final hScore = _state.getHabitScoreForDay(
                          _selectedDate,
                          habit.id,
                        );
                        final isFull =
                            !isSelectedDateBeforeTracking && hScore >= 1.0;
                        final isPart =
                            !isSelectedDateBeforeTracking &&
                            hScore > 0.0 &&
                            hScore < 1.0;
                        String label = isSelectedDateBeforeTracking &&
                                hScore == 0.0
                            ? '기록 전'
                            : (isSelectedDateFuture ? '기록 대기' : '대기');
                        Color bg = Colors.white;
                        Color border = AppColors.divider;
                        Color textCol = AppColors.textSecondary;

                        if (isFull) {
                          label = '완료';
                          bg = AppColors.completedBg;
                          border = AppColors.completedBorder;
                          textCol = AppColors.completedText;
                        } else if (isPart) {
                          label = '조금 실천';
                          bg = AppColors.partialBg;
                          border = AppColors.partialBorder;
                          textCol = AppColors.partialText;
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF3F4F6)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      habit.subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 습관 실천 소급 상태 선택 버튼 (클릭 시 확인 다이얼로그 팝업)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: isSelectedDatePast
                                    ? () => _showPastHabitChoiceDialog(
                                        habit,
                                        isFull,
                                        isPart,
                                      )
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: border,
                                      width: isFull ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
