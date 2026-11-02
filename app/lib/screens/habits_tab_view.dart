import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/habit_item.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/app_time_picker.dart';
/// 
/// 1. 다중 알림 시각 지원:
///    - 하루 여러 번 하는 습관에 맞춰 [+ 시각 추가]로 여러 알림 시각을 등록 및 삭제 가능!
/// 2. 균형 잡힌 버튼 레이아웃:
///    - [수정 내용 저장] 버튼이 오른쪽으로 치우치지 않고 시원하고 균형 있게 배치됨
/// 3. 습관 카드 펼침 메뉴에 [🗑️ 삭제] 버튼 및 확인창 추가
/// 4. 주 N회 입력란 스타일을 깔끔하게 정돈
class HabitsTabView extends StatefulWidget {
  const HabitsTabView({super.key});

  @override
  State<HabitsTabView> createState() => _HabitsTabViewState();
}

class _HabitsTabViewState extends State<HabitsTabView> {
  final AppStateManager _state = AppStateManager();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // 습관 삭제 확인 다이얼로그
  void _confirmDeleteHabit(HabitItem habit) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('습관 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('\'${habit.title}\' 습관을 목록에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neutralDark),
            onPressed: () {
              _state.deleteHabit(habit.id);
              Navigator.of(dCtx).pop();
            },
            child: const Text('삭제하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 습관 추가 및 정보 수정 모달
  void _showHabitEditModal({HabitItem? habit}) {
    final isEditing = habit != null;

    final titleCtrl = TextEditingController(text: isEditing ? habit.title : '');
    final subCtrl = TextEditingController(text: isEditing ? habit.subtitle : '');

    String recurrenceType = isEditing
        ? (habit.recurrenceSummary.startsWith('매주')
            ? '요일 선택'
            : (habit.recurrenceSummary.contains('주') ? '주간 횟수' : (habit.recurrenceSummary == '오늘만' ? '오늘만' : '매일')))
        : '매일';

    List<String> selectedDays = isEditing ? List.from(habit.repeatDays) : [];

    final weeklyTimesCtrl = TextEditingController(
      text: isEditing && habit.recurrenceSummary.contains('주')
          ? habit.recurrenceSummary.replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );

    final targetPerDayCtrl = TextEditingController(
      text: isEditing ? habit.targetPerDay.toString() : '1',
    );

    // 🌟 복수 알림 시간 지원 (여러 개 시각 리스트)
    List<String> scheduledTimes = isEditing ? List.from(habit.scheduledTimes) : [];

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? '습관 정보 수정' : '새로운 습관 추가',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. 습관 이름
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: '습관 이름',
                      hintText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. 작은 목표 설명 & 하루 목표 횟수
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: subCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: '작은 목표 설명',
                            hintText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: targetPerDayCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: '하루 목표',
                            suffixText: '회',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. 실천 주기 (매일, 요일 선택, 주 N회, 오늘만)
                  const Text('실천 주기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['매일', '요일 선택', '주간 횟수', '오늘만'].map((type) {
                      final isSel = recurrenceType == type;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(type),
                        selected: isSel,
                        selectedColor: AppColors.lightLavender,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.primaryPurple : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11.5,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              recurrenceType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  // 요일 선택 (7개 요일 균등 1줄 정렬)
                  if (recurrenceType == '요일 선택') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
                        final isDaySel = selectedDays.contains(day);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isDaySel) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDaySel ? AppColors.primaryPurple : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDaySel ? AppColors.primaryPurple : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDaySel ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 주간 횟수 직접 입력 (디자인 통일)
                  if (recurrenceType == '주간 횟수') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Text('일주일에 ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: weeklyTimesCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('번 실천하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 4. 복수 알림 시간 설정
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('알림 시각', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        icon: const Icon(Icons.add, size: 14, color: AppColors.primaryPurple),
                        label: const Text('시각 추가', style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final time = await AppTimePicker.show(
                            context,
                            initialTime: TimeOfDay.now(),
                            title: '새로운 알림 시각 추가',
                          );
                          if (time != null) {
                            final period = time.period == DayPeriod.am ? '오전' : '오후';
                            final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                            final min = time.minute.toString().padLeft(2, '0');
                            setModalState(() {
                              scheduledTimes.add('$period $hour:$min');
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (scheduledTimes.isEmpty)
                    const Text('시각 미지정 (원할 때 자유롭게 실천)', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: scheduledTimes.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightLavender,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    scheduledTimes.remove(t);
                                  });
                                },
                                child: const Icon(Icons.close, size: 13, color: AppColors.primaryPurple),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 22),

                  // 5. 저장 / 삭제 버튼 (정중앙 균형 잡힌 레이아웃)
                  Row(
                    children: [
                      if (isEditing) ...[
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _confirmDeleteHabit(habit);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.neutralDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, size: 17, color: AppColors.neutralDark),
                              SizedBox(width: 4),
                              Text('삭제', style: TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;

                              String recSummary = '매일';
                              if (recurrenceType == '요일 선택') {
                                recSummary = selectedDays.isEmpty ? '매일' : '매주 ${selectedDays.join(",")}';
                              } else if (recurrenceType == '주간 횟수') {
                                final n = weeklyTimesCtrl.text.trim().isEmpty ? '3' : weeklyTimesCtrl.text.trim();
                                recSummary = '주 $n회';
                              } else if (recurrenceType == '오늘만') {
                                recSummary = '오늘만';
                              }

                              final targetCount = int.tryParse(targetPerDayCtrl.text.trim()) ?? 1;

                              if (isEditing) {
                                _state.updateHabit(
                                  id: habit.id,
                                  title: titleCtrl.text.trim(),
                                  subtitle: subCtrl.text.trim().isEmpty ? '가볍게 실천' : subCtrl.text.trim(),
                                  recurrenceSummary: recSummary,
                                  repeatDays: recurrenceType == '요일 선택' ? selectedDays : [],
                                  scheduledTimes: scheduledTimes,
                                  targetPerDay: targetCount > 0 ? targetCount : 1,
                                );
                              } else {
                                _state.addHabit(
                                  title: titleCtrl.text.trim(),
                                  subtitle: subCtrl.text.trim().isEmpty ? '가볍게 실천' : subCtrl.text.trim(),
                                  recurrenceSummary: recSummary,
                                  repeatDays: recurrenceType == '요일 선택' ? selectedDays : [],
                                  scheduledTimes: scheduledTimes,
                                  targetPerDay: targetCount > 0 ? targetCount : 1,
                                );
                              }
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              isEditing ? '수정 내용 저장' : '습관 추가 완료',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 오늘 실천해야 하는 습관 vs 이미 이번 주에 완료되어 오늘은 쉴 수 있는 습관 분리!
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final otherHabits = _state.habits.where((h) => !h.isDueToday).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSlimProgressHeader(),
        const SizedBox(height: 12),

        // 1. 오늘의 습관 카드들
        ...todayHabits.map((habit) => _buildHabitCard(habit)),

        // 2. 오늘은 아니지만 관리 중인 습관 (하단에 아주 얇고 조용한 1줄로 표시!)
        if (otherHabits.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...otherHabits.map((habit) => _buildCompactOtherHabitCard(habit)),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            child: const Text(
              '작은 습관 추가',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => _showHabitEditModal(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryPurple, width: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 🌟 오늘은 아니거나 이미 완료된 습관을 위한 극도로 슬림하고 단정한 1줄 미니멀 표시
  Widget _buildCompactOtherHabitCard(HabitItem habit) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showHabitEditModal(habit: habit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.successGreen, // 이미 완료되었음을 나타내는 단정한 그린 닷
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${habit.title} (${habit.recurrenceSummary})',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            const Text(
              '이번 주 달성 완료',
              style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlimProgressHeader() {
    // 🌟 오늘 실천 대상 습관들만 기준으로 정확한 점수 및 달성률 계산!
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final total = todayHabits.length;
    final score = todayHabits.fold(0.0, (sum, item) => sum + item.score);
    final rate = total == 0 ? 0.0 : (score / total);

    String formatScore(double s) {
      if (s == s.roundToDouble()) {
        return '${s.toInt()}';
      } else {
        // 정확한 실천 수치(소수점 1자리)를 친절하게 표시!
        return s.toStringAsFixed(1);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '오늘 습관',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$total개 중 ${formatScore(score)}개',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
              Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: AppColors.lightLavender,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(HabitItem habit) {
    Color getStatusColor() {
      final s = habit.score;
      if (s >= 1.0) return AppColors.completedText;
      if (s > 0.0) return AppColors.partialText;
      return AppColors.textSecondary;
    }

    Color getStatusBg() {
      final s = habit.score;
      if (s >= 1.0) return AppColors.completedBg;
      if (s > 0.0) return AppColors.partialBg;
      return const Color(0xFFF3F4F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habit.isExpanded ? AppColors.primaryPurple.withOpacity(0.35) : AppColors.divider.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
        child: Column(
          children: [
            InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _state.toggleHabitExpanded(habit.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 5,
                          children: [
                            Text(
                              habit.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: habit.score >= 1.0
                                    ? AppColors.successGreen
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.lightLavender,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                habit.recurrenceSummary,
                                style: const TextStyle(fontSize: 9.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (habit.targetPerDay > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.warmBrown.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '하루 ${habit.targetPerDay}회',
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.warmBrown, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ...habit.scheduledTimes.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                )),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          habit.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🔒 [우측 상태 칩: 76x32dp 복약 탭과 칼정렬]
                  GestureDetector(
                    onTap: () {
                      final advanced = _state.advanceHabitProgress(habit.id);
                      if (advanced) {
                        if (habit.score >= 1.0) {
                          CelebrationToast.show(
                            context,
                            title: '습관 실천 완료 🌱',
                            message: '\'${habit.title}\' 목표를 달성했어요! 훌륭해요 👏',
                          );
                        } else if (habit.score > 0.0) {
                          CelebrationToast.show(
                            context,
                            title: '작은 발걸음 성공 🐾',
                            message: '조금이라도 실천한 것이 정말 큰 의미가 있어요 :)',
                          );
                        }
                      } else {
                        // 이미 완료된 상태에서 다시 눌렀을 때 토스트 안에서 바로 1초 되돌리기 지원!
                        CelebrationToast.show(
                          context,
                          title: '이미 완료한 습관이에요 ✨',
                          message: '\'${habit.title}\' 목표를 달성한 상태예요.',
                          actionLabel: '되돌리기',
                          onAction: () {
                            _state.resetHabitProgress(habit.id);
                            CelebrationToast.show(
                              context,
                              title: '되돌리기 완료 🌿',
                              message: '\'${habit.title}\' 상태를 대기로 되돌렸어요.',
                            );
                          },
                        );
                      }
                    },
                    child: SizedBox(
                      width: 76,
                      height: 32,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: getStatusBg(),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: habit.score >= 1.0
                                ? AppColors.completedBorder
                                : (habit.score > 0.0 ? AppColors.partialBorder : AppColors.divider),
                          ),
                        ),
                        child: Text(
                          habit.statusLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: getStatusColor(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 카드 탭 시 펼쳐지는 아코디언 옵션 메뉴
          if (habit.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showHabitEditModal(habit: habit),
                    child: const Text('정보 수정', style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (habit.score > 0.0)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        _state.resetHabitProgress(habit.id);
                        CelebrationToast.show(
                          context,
                          title: '되돌리기 완료',
                          message: '\'${habit.title}\' 실천 상태를 대기로 되돌렸어요.',
                        );
                      },
                      child: const Text('되돌리기', style: TextStyle(color: AppColors.warmBrown, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
