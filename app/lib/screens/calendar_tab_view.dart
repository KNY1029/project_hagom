import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../models/task_item.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/app_time_picker.dart';
/// 📅 [달력 & 할일 탭: PRD 5.3절 신규 6안 공식 규격]
/// 
/// 1. 6안 날짜 셀 컬러링 알고리즘:
///    - 100% 완료: 날짜 셀 전체 '통으로' 연초록 파스텔 틴트(#E6F8F0) + 짙은 초록 숫자(#065F46)
///    - 부분 달성: 흰색 배경 + 하단 오렌지 캡슐 바(#F59E0B)
///    - 0% 미복용: 비처벌적 중립 소프트 그레이 바(#D1D5DB)로 안심 피드백
///    - 오늘 날짜: 보라색 테두리(#7B61A8)
///    - 미래 날짜: 진행도 바/틴트 일체 미표시 (완전 깨끗한 초기화)
///    - 할일 핀: 셀 우측 상단 모서리(top: 4, right: 4)에 라벤더 닷(• #7B61A8)
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
    if (mounted) setState(() {});
  }

  // 월 이동
  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
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

  // 할일/한일 추가 및 수정 모달
  void _showTaskModal({TaskItem? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    String selectedTime = task?.time ?? '오후 6:00';
    // 다중 선택 알림 목록
    final List<String> selectedReminders = List<String>.from(task?.reminders ?? ['30분 전']);
    bool isRepeated = task?.isRepeated ?? false;
    String repeatCycle = task?.repeatCycle ?? '매주 특정 요일';
    final List<String> selectedRepeatDays = List<String>.from(task?.repeatDays ?? []);
    final availableReminders = [
      '정시', '30분 전', '1시간 전', '하루 전'
    ];
    final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = _selectedDate.isBefore(today);
    final modalActionName = task != null ? '일정 수정' : (isPast ? '한일 추가' : '할일 추가');

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
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4)),
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
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // 시간 선택 버튼
                Row(
                  children: [
                    const Text('예정 시각', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final t = await AppTimePicker.show(context, initialTime: TimeOfDay.now(), title: '예정 시각 설정');
                        if (t != null) {
                          setMState(() {
                            final p = t.period == DayPeriod.am ? '오전' : '오후';
                            final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                            final m = t.minute.toString().padLeft(2, '0');
                            selectedTime = '$p $h:$m';
                          });
                        }
                      },
                      child: Text(selectedTime, style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 🔔 다중 알림 선택 섹션 (복수 선택 가능 & 직접 N일/시간/분 추가 지원!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('알림 설정 (중복 선택 가능)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      onPressed: () {
                        // 🌟 복합 시간(N시간 N분 전) 및 N일 전 직접 추가 다이얼로그
                        String mode = '시간/분'; // '시간/분' 또는 '일'
                        int? hours;
                        int? minutes;
                        int days = 1;
                        showDialog(
                          context: context,
                          builder: (dCtx) => StatefulBuilder(
                            builder: (ctx, setDState) => AlertDialog(
                              title: const Text('직접 알림 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 모드 선택 탭
                                  Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text('시간 / 분 전'),
                                        selected: mode == '시간/분',
                                        showCheckmark: false,
                                        selectedColor: AppColors.lightLavender,
                                        onSelected: (_) => setDState(() => mode = '시간/분'),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('며칠 전'),
                                        selected: mode == '일',
                                        showCheckmark: false,
                                        selectedColor: AppColors.lightLavender,
                                        onSelected: (_) => setDState(() => mode = '일'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  if (mode == '시간/분')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                            ),
                                            onChanged: (v) => hours = int.tryParse(v),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('시간', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 50,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                            ),
                                            onChanged: (v) => minutes = int.tryParse(v),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('분 전', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              hintText: '',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                            ),
                                            onChanged: (v) => days = int.tryParse(v) ?? 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('일 전', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dCtx).pop(),
                                  child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    String customRem = '';
                                    final h = hours ?? 0;
                                    final m = minutes ?? 0;
                                    if (mode == '시간/분') {
                                      if (h > 0 && m > 0) {
                                        customRem = '$h시간 $m분 전';
                                      } else if (h > 0) {
                                        customRem = '$h시간 전';
                                      } else if (m > 0) {
                                        customRem = '$m분 전';
                                      } else {
                                        customRem = '정시';
                                      }
                                    } else {
                                      customRem = '$days일 전';
                                    }

                                    if (!availableReminders.contains(customRem)) {
                                      availableReminders.add(customRem);
                                    }
                                    if (!selectedReminders.contains(customRem)) {
                                      selectedReminders.add(customRem);
                                    }
                                    setMState(() {});
                                    Navigator.of(dCtx).pop();
                                  },
                                  child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('직접 추가', style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
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
                        fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                        color: isChecked ? AppColors.primaryPurple : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.lightLavender,
                      backgroundColor: const Color(0xFFF9FAFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isChecked ? AppColors.primaryPurple.withOpacity(0.5) : AppColors.divider,
                        ),
                      ),
                      onSelected: (val) {
                        setMState(() {
                          if (val) {
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
                    const Text('반복 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Switch(
                      value: isRepeated,
                      activeColor: AppColors.primaryPurple,
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
                          color: isSel ? AppColors.primaryPurple : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.lightLavender,
                        backgroundColor: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSel ? AppColors.primaryPurple.withOpacity(0.5) : AppColors.divider),
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
                              color: isDaySel ? AppColors.lightLavender : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDaySel ? AppColors.primaryPurple : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isDaySel ? FontWeight.bold : FontWeight.w500,
                                color: isDaySel ? AppColors.primaryPurple : AppColors.textSecondary,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          title: '일정 수정 완료 ✏️',
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
                          title: isPast ? '한일 등록 완료 👏' : '새 일정 등록 완료 🗓️',
                          message: '\'${titleCtrl.text.trim()}\' 일정이 기록되었어요!',
                        );
                      }
                    },
                    child: Text(task != null ? '수정 완료' : '일정 저장', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // 🌟 과거 복약 완료 기록 시 복용 시간 묻는 다이얼로그 (모름/기억 안 남 포함!)
  void _showPastMedTimeDialog(MedicationItem med, int slotIdx, DoseSlot slot) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('${med.name} ${slot.label} 복용 시간', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_selectedDate.month}월 ${_selectedDate.day}일에 이 약을 언제 복용하셨나요?'),
            const SizedBox(height: 8),
            const Text(
              '정확한 시간이 기억나지 않아도 괜찮아요.\n알고 계신 만큼만 기록해도 충분해요 🌿',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // 1) 잘 모르겠음 / 기억 안 남 버튼
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료! 👏',
                message: '${med.name} ${slot.label} 복용을 기록했어요 (복용 시간 미지정).',
              );
            },
            child: const Text('기억 안 남 (모름)', style: TextStyle(color: AppColors.textSecondary)),
          ),
          // 2) 예정 시각 그대로 복용 버튼
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료! 👏',
                message: '${med.name} ${slot.label} 예정 시각에 잘 챙겨 드셨어요!',
              );
            },
            child: Text('${slot.scheduledTime ?? '예정 시각'}에 복용', style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
          ),
          // 3) 직접 시간 선택 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              final t = await AppTimePicker.show(context, initialTime: TimeOfDay.now(), title: '${med.name} 복용 시각');
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              final timeStr = t != null
                  ? '${t.period == DayPeriod.am ? '오전' : '오후'} ${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')}'
                  : '복용 완료';
              CelebrationToast.show(
                context,
                title: '소중한 기록 완료! 👏',
                message: '${med.name} $timeStr에 복약한 기록을 남겼어요.',
              );
            },
            child: const Text('직접 시간 입력', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 과거 복약 되돌리기 확인 다이얼로그
  void _showPastMedRevertDialog(MedicationItem med, int slotIdx, DoseSlot slot) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('복약 상태 되돌리기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('${_selectedDate.month}월 ${_selectedDate.day}일 \'${med.name} ${slot.label}\' 복약 완료 기록을 미완료(대기)로 되돌릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
              CelebrationToast.show(
                context,
                title: '되돌리기 완료 🌿',
                message: '${med.name} ${slot.label} 상태를 미완료로 되돌렸어요.',
              );
            },
            child: const Text('되돌리기 확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('습관 상태 되돌리기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('${_selectedDate.month}월 ${_selectedDate.day}일 \'${habit.title}\' 실천 상태를 대기로 되돌릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '되돌리기 완료 🌿',
                message: '\'${habit.title}\' 실천 상태를 대기로 되돌렸어요.',
              );
            },
            child: const Text('되돌리기 확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('\'${habit.title}\' 실천 기록', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('${_selectedDate.month}월 ${_selectedDate.day}일에 이 습관을 어떻게 실천하셨나요?'),
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
            child: const Text('대기 (미실천)', style: TextStyle(color: AppColors.textSecondary)),
          ),
          // 2) 조금 실천
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '작은 발걸음 기록 🐾',
                message: '조금이라도 실천한 것이 정말 큰 의미가 있어요 :)',
              );
            },
            child: const Text('조금 실천', style: TextStyle(color: AppColors.partialText, fontWeight: FontWeight.bold)),
          ),
          // 3) 완료
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.resetPastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              _state.advancePastHabitProgress(_selectedDate, habit.id);
              CelebrationToast.show(
                context,
                title: '습관 실천 완료! 👏',
                message: '\'${habit.title}\' 목표를 달성했어요! 언제든 멋져요 ✨',
              );
            },
            child: const Text('완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // 일요일=0

    final selectedDayTasks = _state.getTasksForDay(_selectedDate);
    final isSelectedDatePast = _selectedDate.isBefore(today);
    final isSelectedDateToday = _selectedDate.isAtSameMomentAs(today);
    final selectedMedRate = _state.getMedRateForDay(_selectedDate);
    final selectedHabitRate = _state.getHabitRateForDay(_selectedDate);
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
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.textSecondary),
                  onPressed: () => _changeMonth(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.textSecondary),
                  onPressed: () => _changeMonth(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              icon: const Icon(Icons.today, size: 16, color: AppColors.primaryPurple),
              label: const Text('오늘', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _goToToday,
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
            border: Border.all(color: AppColors.divider.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // 요일 헤더 (안티-슬롭 폰트 웨이트 정돈: w600으로 단정하게)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('일', style: TextStyle(color: AppColors.missedRed, fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('월', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('화', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('수', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('목', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('금', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('토', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 6),

              // 날짜 셀 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42, // 6주 x 7일
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (ctx, idx) {
                  final dayOffset = idx - firstWeekday + 1;
                  if (dayOffset < 1 || dayOffset > daysInMonth) {
                    return const SizedBox.shrink(); // 이전/다음달 빈칸
                  }

                  final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayOffset);
                  final isToday = cellDate.isAtSameMomentAs(today);
                  final isSelected = cellDate.isAtSameMomentAs(_selectedDate);
                  final medRate = _state.getMedRateForDay(cellDate);
                  final habitRate = _state.getHabitRateForDay(cellDate);
                  final hasTasks = _state.getTasksForDay(cellDate).isNotEmpty;
                  final hasMissedPrescription = _state.hasMissedPrescriptionForDay(cellDate);

                  final isFuture = cellDate.isAfter(today);

                  // 🌟 [통 연초록 틴트 규격]: "약과 습관 둘 다 100% 완료했을 때만" 통으로 연초록! (미래 날짜는 완전 순백색 초기화)
                  final isMed100 = medRate != null && medRate >= 1.0;
                  final isHabit100 = habitRate != null && habitRate >= 1.0;
                  final isAll100Done = !isFuture && isMed100 && isHabit100;

                  final isPartial = medRate != null && medRate > 0.0 && medRate < 1.0;
                  final isZero = medRate != null && medRate == 0.0;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = cellDate;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAll100Done ? AppColors.successBg : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPurple
                              : (isToday ? AppColors.primaryPurple.withOpacity(0.5) : Colors.transparent),
                          width: isSelected ? 1.8 : (isToday ? 1.2 : 0),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 🌟 PRD 5.3절 [할일 라벤더 닷 모서리 핀]: top: 4, right: 4 단독 배치
                          if (hasTasks)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                          // 날짜 숫자
                          Center(
                            child: Text(
                              '$dayOffset',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                                // 전체 완료한 날이라도 일요일이면 빨간색 유지! 평일은 기본 텍스트 색 유지!
                                color: cellDate.weekday == DateTime.sunday
                                    ? AppColors.missedRed
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // 🌟 사용자 제안 3단계 극단적 단순화 규격:
                          // 1) 전부 다 한 날: 통 연초록 틴트 (#E6F8F0) + 하단 바 없음!
                          // 2) 처방약 안 먹은 날: 흰색 셀 + 🚨 빨간색 바 (#EF4444)
                          // 3) 뭔가 덜 한 날: 흰색 셀 + 🟤 웜브라운 바 (#8B5E3C)
                          // 4) 아직 오지 않은 날짜(미래): 바 일체 없이 완전 깨끗한 순백색 초기화!
                          if (!isFuture && !isAll100Done) ...[
                            if (hasMissedPrescription)
                              Positioned(
                                bottom: 4,
                                left: 8,
                                right: 8,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: AppColors.missedRed, // 선명한 처방약 미복용 경고 레드 바
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 4,
                                left: 8,
                                right: 8,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: AppColors.warmBrown.withOpacity(0.6), // 일반약이든 습관이든 뭔가 덜 한 날 웜브라운 바
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
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
            border: Border.all(color: AppColors.divider.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                        '${_selectedDate.month}월 ${_selectedDate.day}일',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelectedDateToday ? AppColors.lightLavender : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSelectedDateToday ? '오늘' : (isSelectedDatePast ? '지난 기록' : '예정일'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelectedDateToday ? AppColors.primaryPurple : AppColors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16, color: AppColors.primaryPurple),
                          const SizedBox(width: 2),
                          Text(
                            isSelectedDatePast ? '한일 추가' : '할일 추가',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
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

              // 1. 🗓️ [할일 및 일정 영역] - 최상단 우선 배치!
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🗓️ 그날의 할일', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      Text(
                        '(${selectedDayTasks.length}건)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (selectedDayTasks.isNotEmpty)
                    Text(
                      '${selectedDayTasks.where((t) => t.isCompleted).length}/${selectedDayTasks.length} 완료',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 할일 목록 리스트
              if (selectedDayTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Center(
                    child: Text('등록된 일정이 없어요. [+ 할일 추가]로 일정을 기록해보세요 🌱', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                )
              else
                Column(
                  children: selectedDayTasks.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: t.isExpanded ? AppColors.primaryPurple.withOpacity(0.3) : AppColors.divider.withOpacity(0.5),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: t.isCompleted,
                                    activeColor: AppColors.primaryPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (_) {
                                      _state.toggleTaskCompleted(t.id);
                                      if (!t.isCompleted) {
                                        CelebrationToast.show(
                                          context,
                                          title: '일정 완료! 🌸',
                                          message: '\'${t.title}\'을(를) 잘 마쳤어요.',
                                        );
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                            color: t.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (t.time != null || t.reminders.isNotEmpty || t.isRepeated)
                                          Text(
                                            [
                                              if (t.time != null) t.time!,
                                              if (t.reminders.isNotEmpty) t.reminderSummary,
                                              if (t.isRepeated) t.repeatSummary,
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                      ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _showTaskModal(task: t),
                                    child: const Text('정보 수정', style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (t.isCompleted)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        _state.toggleTaskCompleted(t.id);
                                        CelebrationToast.show(
                                          context,
                                          title: '되돌리기 완료',
                                          message: '\'${t.title}\' 일정을 미완료 상태로 되돌렸어요.',
                                        );
                                      },
                                      child: const Text('되돌리기', style: TextStyle(color: AppColors.warmBrown, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      _state.deleteTask(t.id);
                                      CelebrationToast.show(
                                        context,
                                        title: '삭제 완료',
                                        message: '\'${t.title}\' 일정을 삭제했어요.',
                                      );
                                    },
                                    child: const Text('삭제', style: TextStyle(color: AppColors.neutralDark, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 2. 💊 [복약 상태 요약 및 과거 기록 수정 아코디언]
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isSelectedDatePast
                    ? () {
                        setState(() {
                          _isMedDetailsExpanded = !_isMedDetailsExpanded;
                        });
                      }
                    : null, // 오늘/미래 날짜는 탭 비활성화 (조회 전용)
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('복약 현황', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          // 전체 완료 여부 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedMedRate != null && selectedMedRate >= 1.0
                                  ? AppColors.completedBg
                                  : (selectedMedRate != null && selectedMedRate > 0.0
                                      ? AppColors.partialOrange.withOpacity(0.12)
                                      : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(5),
                              border: selectedMedRate != null && selectedMedRate >= 1.0 ? Border.all(color: AppColors.completedBorder) : null,
                            ),
                            child: Text(
                              selectedMedRate == null
                                  ? '기록 대기'
                                  : (selectedMedRate >= 1.0 ? '전체 완료' : (selectedMedRate > 0.0 ? '일부 복용' : '건너뜀/미기록')),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: selectedMedRate != null && selectedMedRate >= 1.0
                                    ? AppColors.completedText
                                    : (selectedMedRate != null && selectedMedRate > 0.0 ? AppColors.partialOrange : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 🌟 과거 날짜일 때만 [수정하기/접기] 버튼 노출! 오늘은 버튼 없이 조회만 가능!
                      if (isSelectedDatePast)
                        Text(
                          _isMedDetailsExpanded ? '접기' : '수정하기',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              // 펼쳤을 때만 나오는 상세 약별 / 회차별 핀셋 수정 카드
              if (_isMedDetailsExpanded) ...[
                const SizedBox(height: 10),
                Column(
                  children: _state.medications.map((med) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                med.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                med.dosage,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 회차별 칩 (클릭 시 소급 토글 및 하곰이 소급 축하!)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: med.doseSlots.asMap().entries.map((entry) {
                              final slotIdx = entry.key;
                              final slot = entry.value;
                              final isDone = _state.isSlotCompletedForDay(_selectedDate, med.id, slotIdx);

                              return InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  if (!isDone) {
                                    // 🌟 복약 완료로 기록할 때: 언제 복용했는지 묻는 다이얼로그 (모름/기억 안 남 포함!)
                                    _showPastMedTimeDialog(med, slotIdx, slot);
                                  } else {
                                    // 이미 완료된 슬롯: 되돌리기 다이얼로그
                                    _showPastMedRevertDialog(med, slotIdx, slot);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDone ? AppColors.successBg : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDone ? AppColors.successGreen.withOpacity(0.4) : AppColors.divider,
                                      width: isDone ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 13,
                                        color: isDone ? AppColors.successGreen : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${slot.label} ${isDone ? "복용 완료" : "미복용"}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                                          color: isDone ? AppColors.successGreen : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 3. 🌱 [습관 현황 요약 및 펼침 아코디언]
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isSelectedDatePast
                    ? () {
                        setState(() {
                          _isHabitDetailsExpanded = !_isHabitDetailsExpanded;
                        });
                      }
                    : null, // 오늘은 비활성화 (조회 전용)
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('습관 현황', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          // 습관 완료 여부 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedHabitRate != null && selectedHabitRate >= 1.0
                                  ? AppColors.completedBg
                                  : (selectedHabitRate != null && selectedHabitRate > 0.0
                                      ? AppColors.partialOrange.withOpacity(0.12)
                                      : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(5),
                              border: selectedHabitRate != null && selectedHabitRate >= 1.0 ? Border.all(color: AppColors.completedBorder) : null,
                            ),
                            child: Text(
                              selectedHabitRate == null
                                  ? '기록 대기'
                                  : (selectedHabitRate >= 1.0
                                      ? '전체 달성'
                                      : (selectedHabitRate > 0.0
                                          ? '${(selectedHabitRate * _state.habits.length).toStringAsFixed(1)}/${_state.habits.length}개 실천'
                                          : '미실천/기록 없음')),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: selectedHabitRate != null && selectedHabitRate >= 1.0
                                    ? AppColors.completedText
                                    : (selectedHabitRate != null && selectedHabitRate > 0.0 ? AppColors.partialOrange : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 🌟 과거 날짜일 때만 [수정하기/접기] 버튼 노출! 오늘은 버튼 없이 조회만 가능!
                      if (isSelectedDatePast)
                        Text(
                          _isHabitDetailsExpanded ? '접기' : '수정하기',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),

              // 펼쳤을 때 나오는 개별 습관 실천 상태 및 소급 체크
              if (_isHabitDetailsExpanded) ...[
                const SizedBox(height: 10),
                Column(
                  children: _state.habits.map((habit) {
                    final hScore = _state.getHabitScoreForDay(_selectedDate, habit.id);
                    final isFull = hScore >= 1.0;
                    final isPart = hScore > 0.0 && hScore < 1.0;
                    String label = '대기';
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  habit.subtitle,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 습관 실천 소급 상태 선택 버튼 (클릭 시 확인 다이얼로그 팝업)
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _showPastHabitChoiceDialog(habit, isFull, isPart),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: border, width: isFull ? 1.2 : 1.0),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textCol),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
