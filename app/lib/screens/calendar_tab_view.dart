import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/task_item.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';

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

  // 할일 추가 모달
  void _showAddTaskModal() {
    final titleCtrl = TextEditingController();
    String selectedTime = '오후 6:00';
    String reminder = '30분 전';
    bool isRepeated = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (mCtx) => StatefulBuilder(
        builder: (ctx, setMState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.month}월 ${_selectedDate.day}일 할일 추가',
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
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '할일 제목을 입력하세요 (예: 병원 상담, 과제)',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              // 시간 및 알림 선택 바
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16, color: AppColors.primaryPurple),
                      label: Text(selectedTime, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) {
                          setMState(() {
                            final p = t.period == DayPeriod.am ? '오전' : '오후';
                            final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                            final m = t.minute.toString().padLeft(2, '0');
                            selectedTime = '$p $h:$m';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: reminder,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '정시', child: Text('정시 알림', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: '30분 전', child: Text('30분 전 알림', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: '1시간 전', child: Text('1시간 전 알림', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) setMState(() => reminder = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 반복 여부 스위치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('매주 반복', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Switch(
                    value: isRepeated,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (val) => setMState(() => isRepeated = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    _state.addTask(
                      title: titleCtrl.text.trim(),
                      date: _selectedDate,
                      time: selectedTime,
                      reminder: reminder,
                      isRepeated: isRepeated,
                    );
                    Navigator.of(ctx).pop();
                    CelebrationToast.show(
                      context,
                      title: '새 일정 등록 완료 🗓️',
                      message: '\'${titleCtrl.text.trim()}\' 일정이 달력에 등록되었어요!',
                    );
                  },
                  child: const Text('일정 저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // 요일 헤더
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('일', style: TextStyle(color: AppColors.missedRed, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('월', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('화', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('수', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('목', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('금', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('토', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1),
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
                  final hasTasks = _state.getTasksForDay(cellDate).isNotEmpty;

                  // 6안 시각화 상태:
                  // 100% 완료: 연초록 통 채움 (#E6F8F0)
                  final is100Done = medRate != null && medRate >= 1.0;
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
                        color: is100Done ? AppColors.successBg : Colors.white,
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
                                color: is100Done
                                    ? AppColors.successGreen
                                    : (cellDate.weekday == DateTime.sunday
                                        ? AppColors.missedRed
                                        : AppColors.textPrimary),
                              ),
                            ),
                          ),

                          // 🌟 하단 캡슐 바 (부분 달성: 오렌지 / 0% 미복용: 비처벌적 소프트 그레이 바)
                          if (isPartial)
                            Positioned(
                              bottom: 4,
                              left: 6,
                              right: 6,
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: AppColors.partialOrange,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          if (isZero)
                            Positioned(
                              bottom: 4,
                              left: 6,
                              right: 6,
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1D5DB), // 비처벌적 안심 슬레이트 그레이 바
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
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
                    onTap: _showAddTaskModal,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primaryPurple),
                          SizedBox(width: 2),
                          Text('할일 추가', style: TextStyle(fontSize: 12.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                                  title: '할일 완료! 🌸',
                                  message: '\'${t.title}\'을(를) 잘 마쳤어요. 훌륭해요!',
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
                                if (t.time != null)
                                  Text(
                                    '${t.time} · ${t.reminder}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _state.deleteTask(t.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 2. 💊 [복약 상태 요약 및 펼침 아코디언] - 하단 배치!
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _isMedDetailsExpanded = !_isMedDetailsExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('💊 복약 현황', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          // 전체 완료 여부 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedMedRate != null && selectedMedRate >= 1.0
                                  ? AppColors.successBg
                                  : (selectedMedRate != null && selectedMedRate > 0.0
                                      ? AppColors.partialOrange.withOpacity(0.12)
                                      : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              selectedMedRate == null
                                  ? '기록 대기'
                                  : (selectedMedRate >= 1.0 ? '✓ 전체 완료' : (selectedMedRate > 0.0 ? '일부 복용' : '건너뜀/미기록')),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: selectedMedRate != null && selectedMedRate >= 1.0
                                    ? AppColors.successGreen
                                    : (selectedMedRate != null && selectedMedRate > 0.0 ? AppColors.partialOrange : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _isMedDetailsExpanded ? '접기' : '자세히 보기',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _isMedDetailsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.primaryPurple,
                          ),
                        ],
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
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
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
                                  final nowCompleted = _state.togglePastSlotCompleted(_selectedDate, med.id, slotIdx);
                                  if (nowCompleted) {
                                    CelebrationToast.show(
                                      context,
                                      title: '소중한 기록 완료! 👏',
                                      message: '${med.name} ${slot.label} 약을 챙겨 먹었다고 알려줘서 고마워요. 하곰이가 칭찬해요 ✨',
                                    );
                                  } else {
                                    CelebrationToast.show(
                                      context,
                                      title: '복약 대기로 변경 🌿',
                                      message: '${med.name} ${slot.label} 상태를 다시 미완료로 편안하게 되돌렸어요.',
                                    );
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
            ],
          ),
        ),
      ],
    );
  }
}
