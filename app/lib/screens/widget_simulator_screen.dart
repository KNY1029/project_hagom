import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/medication_item.dart';
import '../models/task_item.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/responsive_content.dart';

/// 📱 스마트폰 홈 위젯 시뮬레이터 & 쇼룸 화면 (최신 홈 위젯 1:1 완벽 동기화)
///
/// 안드로이드 홈 화면에 등록되는 4대 공식 홈 위젯을 앱 내에서 동일하게 체험:
/// 1) 🐻 마스코트 응원 위젯 (3×1 규격 / 9단계 출석 표정 & 18개 대사 / 탭 시 대사 순환)
/// 2) 💊 복약 1-Tap 즉시 체크 위젯 (2×1 규격)
/// 3) 🌱 습관 1-Tap 즉시 실천 위젯 (2×1 규격)
/// 4) 🗓️ 할일 1-Tap 즉시 완료 위젯 (2×1 규격)
/// 5) 📅 한 달 기록 달력 대시보드 대형 위젯 (4×4 규격 / 3색 상태 바 & 날짜별 요약)
class WidgetSimulatorScreen extends StatefulWidget {
  const WidgetSimulatorScreen({super.key});

  @override
  State<WidgetSimulatorScreen> createState() => _WidgetSimulatorScreenState();
}

class _WidgetSimulatorScreenState extends State<WidgetSimulatorScreen> {
  final AppStateManager _state = AppStateManager();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => AppColors.cardSurface;
  Color get _inputSurface => AppColors.inputSurface;
  Color get _softBorder => AppColors.divider;

  // 마스코트 9단계 상태 정의 (실제 위젯과 100% 동일)
  static const List<Map<String, dynamic>> _mascotStages = [
    {
      'badge': '1. 기대',
      'quotes': [
        '하곰이는 언제나 여기 있어요!',
        '내일도 힘내서 가보자고요✨',
      ],
      'asset': 'assets/images/hagom_widget_stage_1.webp',
      'desc': '오늘 출석 완료 · 환영 표정',
    },
    {
      'badge': '2. 기다림',
      'quotes': [
        '하곰은(뚠뚠) 오늘도(뚠뚠) 접속을~ 기다리네(뚠뚠)',
        '오늘 할 일도 마치고 오실 때까지, 조용히 기다릴게요!',
      ],
      'asset': 'assets/images/hagom_widget_stage_2.webp',
      'desc': '어제 출석함 · 리셋 3시간 전',
    },
    {
      'badge': '3. 부담',
      'quotes': [
        '있죠 나 알고 있어요, 유저님은 할 수 있는 아이라는 거~',
        '유저니이임!! 나를 두고 어디 가신 거예요오오!!!!',
      ],
      'asset': 'assets/images/hagom_widget_stage_3.webp',
      'desc': '어제 출석함 · 리셋 임박 (3시간 이내)',
    },
    {
      'badge': '4. 당황',
      'quotes': [
        '하곰이 조금은 슬플지도 몰라요...',
        '어라...? 연속 방문 기록이 깨지고 있어요😳',
      ],
      'asset': 'assets/images/hagom_widget_stage_4.webp',
      'desc': '결석 1일째',
    },
    {
      'badge': '5. 분노',
      'quotes': [
        '요즘 많이 바쁜가 봐요...!!',
        '충격: 하곰이 앱 이용횟수 급감해',
      ],
      'asset': 'assets/images/hagom_widget_stage_5.webp',
      'desc': '결석 3일째',
    },
    {
      'badge': '6. 슬픔',
      'quotes': [
        '너 떠난 이곳은 잠겨 눈물로🎵',
        '유저님, 큰일이에요!! 애써 쌓은 기록이...',
      ],
      'asset': 'assets/images/hagom_widget_stage_6.webp',
      'desc': '결석 5일째',
    },
    {
      'badge': '7. 피로',
      'quotes': [
        '(진짜 안 올 거예요?? 아니 진짜로?)',
        '우리... 좋았잖아요.....',
      ],
      'asset': 'assets/images/hagom_widget_stage_7.webp',
      'desc': '결석 7일째',
    },
    {
      'badge': '8. 절망',
      'quotes': [
        '하곰이는 늘 유저님뿐이었는데ㅠ',
        '어쩜... 다른 앱으로 갈아타버린 거예요?',
      ],
      'asset': 'assets/images/hagom_widget_stage_8.webp',
      'desc': '결석 10일째',
    },
    {
      'badge': '9. 붕괴',
      'quotes': [
        '그럼 하곰이... 삭제돼도 되니...?',
        '하... 유저님- 아니, 당신. 이런 관계 하곰이는 이제 지쳤어요.',
      ],
      'asset': 'assets/images/hagom_widget_stage_9.webp',
      'desc': '결석 15일 이상 장기 미접속',
    },
  ];

  // 마스코트 테스트 모드: -1 = 실제 앱 출석 데이터 자동 연동, 0~8 = 단계 강제 지정
  int _manualStageIndex = -1;
  int _currentQuoteIndex = 0;

  // 4x4 달력 대시보드 시뮬레이션 상태
  late DateTime _calendarMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
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

  // 현재 활성화된 마스코트 단계 인덱스 (0~8)
  int get _activeStageIndex {
    if (_manualStageIndex >= 0 && _manualStageIndex < _mascotStages.length) {
      return _manualStageIndex;
    }
    // 앱의 실제 출석 상태 및 리셋 시각 기준 자동 계산
    return _state.attendanceMascotStageIndex.clamp(0, _mascotStages.length - 1);
  }

  void _nextMascotQuote() {
    setState(() {
      _currentQuoteIndex = (_currentQuoteIndex + 1) % 2;
    });
    CelebrationToast.show(
      context,
      title: '위젯 탭 동작',
      message: '위젯을 터치하여 다음 대사로 순환했어요!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '홈 위젯 쇼룸 & 시뮬레이터',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 💡 안내 배너
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.widgets_rounded,
                      color: AppColors.primaryPurple,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안드로이드 홈 위젯 실시간 쇼룸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '휴대폰 홈 화면에 배치되는 4가지 공식 위젯과 동일한 디자인 및 실시간 터치 동작을 직접 체험해 보세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // -------------------------------------------------------------
            // [위젯 1: 3×1 마스코트 출석 응원 위젯]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '1. 하곰이 출석 응원 위젯 (3×1 규격)',
              subtitle: '출석 상태 및 결석 일수에 따라 9단계 표정 자동 적용 · 탭 시 대사 전환',
            ),
            const SizedBox(height: 8),

            // 단계 선택 칩 스크롤 바
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStageChip(-1, '✨ 출석 자동 연동'),
                  for (int i = 0; i < _mascotStages.length; i++)
                    _buildStageChip(i, _mascotStages[i]['badge'] as String),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3x1 마스코트 위젯 실제 렌더링 카드
            _buildMascot3x1WidgetCard(),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // [위젯 2: 1-Tap 즉시 체크 위젯 3종 (2×1 규격)]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '2. 인체공학적 1-Tap 즉시 체크 위젯 (2×1 규격)',
              subtitle: '왼쪽엔 상세 정보, 오른쪽엔 한 손으로 즉시 누르는 대형 실천 버튼',
            ),
            const SizedBox(height: 10),

            // 2-1: 복약 1-Tap
            _buildMedOneTapWidget(),
            const SizedBox(height: 12),

            // 2-2: 습관 1-Tap
            _buildHabitOneTapWidget(),
            const SizedBox(height: 12),

            // 2-3: 할일 1-Tap
            _buildTaskOneTapWidget(),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // [위젯 3: 4×4 한 달 기록 달력 대시보드 위젯]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '3. 한 달 기록 달력 대시보드 위젯 (4×4 규격)',
              subtitle: '날짜별 복약·습관 3색 실천 바 & 날짜 터치 시 즉시 할일 요약 연동',
            ),
            const SizedBox(height: 10),

            _buildMonthCalendar4x4WidgetCard(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 1: 3x1 마스코트 위젯]
  // ---------------------------------------------------------------------------
  Widget _buildStageChip(int index, String label) {
    final isSelected = _manualStageIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: AppColors.primaryPurple.withValues(alpha: 0.15),
        backgroundColor: _surface,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColors.primaryPurple : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        onSelected: (val) {
          if (val) {
            setState(() {
              _manualStageIndex = index;
              _currentQuoteIndex = 0;
            });
          }
        },
      ),
    );
  }

  Widget _buildMascot3x1WidgetCard() {
    final stageIdx = _activeStageIndex;
    final stage = _mascotStages[stageIdx];
    final badge = stage['badge'] as String;
    final quotes = stage['quotes'] as List<String>;
    final imageAsset = stage['asset'] as String;
    final desc = stage['desc'] as String;
    final quoteText = quotes[_currentQuoteIndex % quotes.length];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _nextMascotQuote,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위젯 상단 라벨
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.touch_app_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  '탭하여 대사 전환',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 실제 안드로이드 3x1 위젯과 1:1 레이아웃
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측 마스코트 표정 이미지 (72x72)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _inputSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _softBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      imageAsset,
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.pets_rounded,
                          color: AppColors.primaryPurple,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 우측 따뜻한 캐릭터 대사
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _inputSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _softBorder),
                    ),
                    child: Text(
                      quoteText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-1: 복약 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildMedOneTapWidget() {
    String medName = '복약 없음';
    String medDetail = '등록된 약이 없거나 오늘 약이 아닙니다';
    String medType = '일반';
    String medId = '';
    int slotIndex = 0;
    bool isCompleted = false;

    for (final med in _state.medications) {
      if (!med.isDueToday) continue;
      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (!slot.isCompleted) {
          medName = '${med.name} ${med.dosage}';
          final sTime = slot.scheduledTime ?? '예정 시간';
          medDetail = '$sTime · 식후 복용';
          medType = med.isPrescription ? '처방약 (시간 엄수)' : '일반약';
          medId = med.id;
          slotIndex = i;
          isCompleted = false;
          break;
        }
      }
      if (medId.isNotEmpty) break;
    }

    if (medId.isEmpty && _state.medications.isNotEmpty) {
      final firstMed = _state.medications.first;
      medName = '${firstMed.name} ${firstMed.dosage}';
      medDetail = '오늘 모든 복약 완료';
      medType = firstMed.isPrescription ? '처방약' : '일반약';
      medId = firstMed.id;
      slotIndex = 0;
      isCompleted = true;
    }

    final total = _state.totalDoseSlots;
    final comp = _state.completedDoseSlots;

    return Container(
      width: double.infinity,
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측 내용 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '다음 복약',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$comp/$total 완료',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      medDetail,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _inputSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Text(
                    medType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 확인 버튼 (실제 위젯 동작 일치)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (medId.isEmpty) return;
              if (isCompleted) {
                CelebrationToast.show(
                  context,
                  title: '복약 완료 상태',
                  message: '이미 완료된 복약은 기록 보호를 위해 앱 내 복약 탭에서 수정할 수 있어요.',
                );
              } else {
                _state.completeSlot(medId, slotIndex);
                CelebrationToast.show(
                  context,
                  title: '복용 완료',
                  message: '홈 위젯 1-Tap으로 복용을 완료했어요!',
                );
              }
            },
            child: Container(
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.completedBg
                    : AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.completedBorder
                      : AppColors.primaryPurple,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.medication_rounded,
                    color: isCompleted ? AppColors.completedText : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? '완료됨' : '복용',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? '앱에서 수정' : '1-Tap 완료',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.completedText.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-2: 습관 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildHabitOneTapWidget() {
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final habit = todayHabits.isNotEmpty ? todayHabits.first : null;

    final String habitTitle = habit != null ? habit.title : '등록된 습관 없음';
    final String habitSubtitle = habit != null
        ? '${habit.subtitle}${habit.scheduledTimes.isEmpty ? '' : ' (${habit.scheduledTimes.join(', ')})'}'
        : '습관 탭에서 새로운 습관을 추가해 보세요';
    final String statusLabel = habit != null ? habit.statusLabel : '대기';
    final bool isAllDone = habit != null && habit.score >= 1.0;

    return Container(
      width: double.infinity,
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측 내용 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '오늘의 습관',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '현재: $statusLabel',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habitTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      habitSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _inputSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Text(
                    isAllDone ? '오늘 목표 달성 완료 🌱' : '오늘 실천 진행 중',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isAllDone ? AppColors.successGreen : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 실천 버튼
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (habit == null) return;
              if (isAllDone) {
                CelebrationToast.show(
                  context,
                  title: '습관 실천 완료',
                  message: '이미 달성한 습관은 기록 보호를 위해 앱 내 습관 탭에서 수정할 수 있어요.',
                );
              } else {
                _state.advanceHabitProgress(habit.id);
                CelebrationToast.show(
                  context,
                  title: '습관 실천',
                  message: '위젯에서 1-Tap으로 실천을 기록했어요!',
                );
              }
            },
            child: Container(
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isAllDone
                    ? AppColors.completedBg
                    : AppColors.successGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAllDone
                      ? AppColors.completedBorder
                      : AppColors.successGreen,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAllDone ? Icons.eco_rounded : Icons.add_task_rounded,
                    color: isAllDone ? AppColors.completedText : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAllDone ? '달성' : '실천',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isAllDone ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAllDone ? '앱에서 수정' : '1-Tap 실천',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isAllDone
                          ? AppColors.completedText.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-3: 할일 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildTaskOneTapWidget() {
    final now = DateTime.now();
    final todayTasks = _state.getTasksForDay(now);
    final task = todayTasks.isNotEmpty
        ? todayTasks.first
        : (_state.tasks.isNotEmpty ? _state.tasks.first : null);

    final String taskTitle = task != null ? task.title : '등록된 할일 없음';
    final String taskRepeat = task != null ? task.repeatSummary : '일반';
    final String taskTime = (task != null && task.time != null) ? task.time! : '시간 미지정';
    final bool isCompleted = task != null && task.isCompleted;

    return Container(
      width: double.infinity,
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측 내용 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF493B24) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '오늘의 할일',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      taskTime,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '반복: $taskRepeat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _inputSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Text(
                    isCompleted ? '상태: 완료됨' : '상태: 진행 대기',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 체크 버튼
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (task == null) return;
              _state.toggleTaskCompleted(task.id);
              CelebrationToast.show(
                context,
                title: !isCompleted ? '할일 완료' : '할일 취소',
                message: !isCompleted ? '위젯에서 할일을 완료했어요!' : '할일 완료를 취소했어요.',
              );
            },
            child: Container(
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.completedBg
                    : const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.completedBorder
                      : const Color(0xFFD97706),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.check_box_outlined,
                    color: isCompleted ? AppColors.completedText : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? '완료됨' : '체크',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? '탭하여 취소' : '1-Tap 체크',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.completedText.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 3: 4×4 한 달 기록 달력 대시보드 위젯]
  // ---------------------------------------------------------------------------
  Widget _buildMonthCalendar4x4WidgetCard() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDayOfWeek = DateTime(year, month, 1).weekday % 7; // 0=일요일
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final totalCells = ((firstDayOfWeek + daysInMonth + 6) ~/ 7) * 7;
    final now = DateTime.now();

    final selectedTasks = _state.getTasksForDay(_selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1) 상단 헤더: 이전달(◀), 년월 타이틀 + 하곰이 아이콘, 다음달(▶)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                color: AppColors.primaryPurple,
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month - 1, 1);
                  });
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$year년 $month월 기록 달력',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/hagom_widget_stage_1.webp',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets_rounded,
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: AppColors.primaryPurple,
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 2) 요일 헤더
          Row(
            children: const [
              _WeekdayText('일', isSunday: true),
              _WeekdayText('월'),
              _WeekdayText('화'),
              _WeekdayText('수'),
              _WeekdayText('목'),
              _WeekdayText('금'),
              _WeekdayText('토'),
            ],
          ),
          const Divider(height: 12),

          // 3) 한 달 그리드 (실제 4x4 위젯과 동일한 셀 및 3색 바)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, i) {
              final dayNumber = i - firstDayOfWeek + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final isSunday = (i % 7) == 0;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _selectedDate = cellDate);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primaryPurple, width: 1.5)
                        : (isSelected
                            ? Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.5), width: 1.0)
                            : null),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: (isToday || isSelected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSunday
                              ? AppColors.missedRed
                              : (isSelected ? AppColors.primaryPurple : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 3색 미니 인디케이터 바
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 1.5),
                          Container(
                            width: 4,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // 4) 하단 선택 날짜 요약 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 18,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedDate.month}월 ${_selectedDate.day}일: 등록된 할 일 ${selectedTasks.length}건 · 복약/습관 기록',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayText extends StatelessWidget {
  final String label;
  final bool isSunday;
  const _WeekdayText(this.label, {this.isSunday = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSunday ? FontWeight.bold : FontWeight.w500,
            color: isSunday ? AppColors.missedRed : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
