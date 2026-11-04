import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import '../widgets/celebration_toast.dart';

/// 📱 스마트폰 홈 위젯 시뮬레이터 & 쇼룸 화면 (v0.22.82)
/// 
/// 카카오톡 기획 논의 및 2x1 규격 공식 사양:
/// [그룹 1: 마스코트 의욕 및 미접속 4대 감정 위젯 (2x1)]
///  1) 기쁨 (올클리어: 오늘 할 일 끝냄)
///  2) 할 수 있어! (평소 응원: 오늘 할 일 진행 중)
///  3) 돌아와... (1~3일 미접속: 무난하고 애절한 복귀 유도)
///  4) 왜 안 들어와 (4일 이상 미접속: 듀오링고 모드 부담 집중)
/// 
/// [그룹 2: 인체공학적 1-Tap 즉시 체크 통합 위젯 (2x1)]
///  5) 복약 원탭 체크 (왼쪽: 복약 상세 / 오른쪽: 1-Tap 복용 완료)
///  6) 습관 원탭 체크 (왼쪽: 습관 상세 / 오른쪽: 1-Tap 실천 완료)
///  7) 할일 원탭 체크 (왼쪽: 일정 상세 / 오른쪽: 1-Tap 완료)
class WidgetSimulatorScreen extends StatefulWidget {
  const WidgetSimulatorScreen({super.key});

  @override
  State<WidgetSimulatorScreen> createState() => _WidgetSimulatorScreenState();
}

class _WidgetSimulatorScreenState extends State<WidgetSimulatorScreen> {
  final AppStateManager _state = AppStateManager();

  // 감정 모드 시뮬레이션 상태: 'auto'(앱 상태 자동 연동), 'joy', 'encourage', 'miss1to3', 'miss4plus'
  String _emotionMode = 'auto';

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

  // 현재 감정 상태 계산 (앱의 실제 복약/습관 달성률 연동)
  String get _currentActiveEmotion {
    if (_emotionMode != 'auto') return _emotionMode;

    final totalMeds = _state.totalDoseSlots;
    final compMeds = _state.completedDoseSlots;
    final habitTotal = _state.habits.where((h) => h.isDueToday).length;
    final habitScore = _state.habitTotalScore;

    final bool isMedAll = totalMeds > 0 && compMeds >= totalMeds;
    final bool isHabitAll = habitTotal > 0 && habitScore >= habitTotal.toDouble();

    if (isMedAll && isHabitAll) {
      return 'joy'; // 오늘 할 일 끝냄 (기쁨)
    }
    return 'encourage'; // 할 수 있어! (진행 중)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '홈 위젯 쇼룸 & 시뮬레이터',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 💡 안내 배너
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.widgets_outlined, color: AppColors.primaryPurple, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트폰 홈 화면 2×1 위젯',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '환자가 앱을 켜지 않고도 홈 화면에서 마스코트의 지지를 받고 1초 만에 복약/습관을 체크하는 인체공학적 위젯이에요.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // [그룹 1: 마스코트 의욕 & 미접속 4대 감정 위젯]
          // -------------------------------------------------------------
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              '그룹 1. 마스코트 감정 및 의욕 증진 위젯 (2×1)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          // 감정 상태 강제 테스트 칩 바
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEmotionChip('auto', '앱 데이터 자동 연동'),
                _buildEmotionChip('joy', '기쁨 (올클리어)'),
                _buildEmotionChip('encourage', '할 수 있어요! (진행 중)'),
                _buildEmotionChip('miss1to3', '기다리고 있어요 (1~3일 미접속)'),
                _buildEmotionChip('miss4plus', '복약이 시급해요 (4일+ 미접속)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildGroup1WidgetCard(),
          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // [그룹 2: 인체공학적 1-Tap 즉시 체크 통합 위젯 3종]
          // -------------------------------------------------------------
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              '그룹 2. 인체공학적 1-Tap 즉시 체크 위젯 (2×1)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '왼쪽에 상세 정보, 오른쪽에 엄지손가락으로 즉시 누르는 대형 확인 버튼 배치',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),

          // 위젯 5: 복약 원탭 체크
          _buildMedOneTapWidget(),
          const SizedBox(height: 14),

          // 위젯 6: 습관 원탭 체크
          _buildHabitOneTapWidget(),
          const SizedBox(height: 14),

          // 위젯 7: 할일 원탭 체크
          _buildTaskOneTapWidget(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmotionChip(String mode, String label) {
    final isSel = _emotionMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        showCheckmark: false,
        selectedColor: AppColors.lightLavender,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
          color: isSel ? AppColors.primaryPurple : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSel ? AppColors.primaryPurple : AppColors.divider),
        ),
        onSelected: (val) {
          if (val) setState(() => _emotionMode = mode);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [그룹 1 위젯 카드 빌더: 4가지 감정 상태별 렌더링]
  // ---------------------------------------------------------------------------
  Widget _buildGroup1WidgetCard() {
    final emotion = _currentActiveEmotion;

    Color bg;
    Color border;
    Color tagBg;
    Color tagText;
    String tagLabel;
    String badgeEmoji;
    String mainQuote;
    String bottomChipText;
    Color bottomChipBg;
    Color bottomChipFg;

    if (emotion == 'joy') {
      bg = const Color(0xFFFAF7FF);
      border = const Color(0xFFE0D5F2);
      tagBg = const Color(0xFFEDE9FE);
      tagText = const Color(0xFF6D28D9);
      tagLabel = 'ALL CLEAR';
      badgeEmoji = '기쁨';
      mainQuote = '오늘 약과 루틴을 모두 완료했어요!\n스스로를 아끼는 마음이 정말 멋져요.';
      bottomChipText = '5일 연속 달성 · 오늘 복약 완료';
      bottomChipBg = const Color(0xFFEDE9FE);
      bottomChipFg = const Color(0xFF6D28D9);
    } else if (emotion == 'encourage') {
      bg = Colors.white;
      border = const Color(0xFFE5E7EB);
      tagBg = const Color(0xFFECFDF5);
      tagText = const Color(0xFF059669);
      tagLabel = 'MENTAL CARE';
      badgeEmoji = '할 수 있어요!';
      mainQuote = '한 가지만 실천해도 충분해요.\n오늘 약 하나만 챙겨도 대단한 거예요.';
      final nextMed = _getNextDoseSummary();
      bottomChipText = nextMed;
      bottomChipBg = const Color(0xFFECFDF5);
      bottomChipFg = const Color(0xFF047857);
    } else if (emotion == 'miss1to3') {
      bg = const Color(0xFFFAF9F7);
      border = const Color(0xFFEAE6E1);
      tagBg = const Color(0xFFF5EFE6);
      tagText = const Color(0xFF8C6D53);
      tagLabel = 'WE MISS YOU';
      badgeEmoji = '기다리고 있어요';
      mainQuote = '많이 바빴나요? 오늘 약은 챙겼어요?\n잠시 들러서 편안히 확인해 보세요.';
      bottomChipText = '연속 기록 유지까지 4시간 남음';
      bottomChipBg = const Color(0xFFF5EFE6);
      bottomChipFg = const Color(0xFF8C6D53);
    } else {
      // miss4plus (듀오링고 모드)
      bg = const Color(0xFFFFF5F5);
      border = const Color(0xFFFECACA);
      tagBg = const Color(0xFFFEE2E2);
      tagText = const Color(0xFFDC2626);
      tagLabel = 'DUOLINGO MODE';
      badgeEmoji = '복약이 시급해요';
      mainQuote = '기다리고 있어요.\n건강을 위해 오늘 약 복용을 꼭 챙겨주세요.';
      bottomChipText = '4일째 미접속 · 오늘 약 복용 시급!';
      bottomChipBg = const Color(0xFFFEE2E2);
      bottomChipFg = const Color(0xFFDC2626);
    }

    return Container(
      width: double.infinity,
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측: 마스코트 무대 (80x120)
          Container(
            width: 82,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    AppAssets.splashMascot,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeEmoji,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tagText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측: 와이드 컨텐츠 & 상태 바
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tagLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tagText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      '2×1 하곰이 위젯',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  mainQuote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    color: bottomChipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bottomChipText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: bottomChipFg,
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

  String _getNextDoseSummary() {
    for (final med in _state.medications) {
      if (!med.isDueToday) continue;
      for (final slot in med.doseSlots) {
        if (!slot.isCompleted) {
          final sTime = slot.scheduledTime ?? '예정';
          return '다음 복약: $sTime (${med.name})';
        }
      }
    }
    return '오늘 남은 복약이 없어요';
  }

  // ---------------------------------------------------------------------------
  // [위젯 5: 복약 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildMedOneTapWidget() {
    // 오늘 복용할 약 중 첫 번째 미완료 슬롯 찾기
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

    // 만약 모든 약이 완료되었다면 첫 번째 약의 완료 상태 표시
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
      height: 144,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                        color: const Color(0xFFF3EDF9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
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
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      medDetail,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    medType,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 확인 버튼 (인체공학적)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (medId.isEmpty) return;
              if (isCompleted) {
                // 이미 완료된 경우 취소 토글
                _state.cancelSpecificSlot(medId, slotIndex);
                CelebrationToast.show(
                  context,
                  title: '복약 취소',
                  message: '복약 기록을 취소했어요.',
                );
              } else {
                _state.completeSlot(medId, slotIndex);
                CelebrationToast.show(
                  context,
                  title: '복약 완료',
                  message: '위젯에서 1-Tap으로 복약 완료했어요!',
                );
              }
            },
            child: Container(
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.completedBg : AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? AppColors.completedBorder : AppColors.primaryPurple,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted ? AppColors.completedBorder : AppColors.primaryPurple).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCompleted ? '완료됨' : '복용',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? '탭하여 취소' : '1-Tap 완료',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.completedText.withOpacity(0.8) : Colors.white.withOpacity(0.9),
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
  // [위젯 6: 습관 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildHabitOneTapWidget() {
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final habit = todayHabits.isNotEmpty ? todayHabits.first : null;

    final String habitTitle = habit != null ? habit.title : '등록된 습관 없음';
    final String habitSubtitle = habit != null ? habit.subtitle : '습관 탭에서 새로운 습관을 추가해 보세요';
    final String statusLabel = habit != null ? habit.statusLabel : '대기';
    final bool isAllDone = habit != null && habit.score >= 1.0;

    final habitTotal = todayHabits.length;
    final habitScore = _state.habitTotalScore;

    return Container(
      width: double.infinity,
      height: 144,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '오늘의 습관',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '총 ${habitScore.toStringAsFixed(1)}/$habitTotal 실천 중',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      habitSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '현재 상태: $statusLabel',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 확인 버튼
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (habit == null) return;
              if (isAllDone) {
                habit.resetProgress();
                _state.notifyListeners();
                CelebrationToast.show(
                  context,
                  title: '습관 리셋',
                  message: '습관 진행을 초기화했어요.',
                );
              } else {
                _state.advanceHabitProgress(habit.id);
                CelebrationToast.show(
                  context,
                  title: '습관 실천',
                  message: '위젯에서 1-Tap으로 실천 완료했어요!',
                );
              }
            },
            child: Container(
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isAllDone ? AppColors.completedBg : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAllDone ? AppColors.completedBorder : const Color(0xFF10B981),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isAllDone ? AppColors.completedBorder : const Color(0xFF10B981)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAllDone ? '달성' : '실천',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isAllDone ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAllDone ? '탭하여 리셋' : '1-Tap 실천',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isAllDone ? AppColors.completedText.withOpacity(0.8) : Colors.white.withOpacity(0.9),
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
  // [위젯 7: 할일 원탭 체크 위젯 (2x1)]
  // ---------------------------------------------------------------------------
  Widget _buildTaskOneTapWidget() {
    final now = DateTime.now();
    final todayTasks = _state.getTasksForDay(now);
    final task = todayTasks.isNotEmpty ? todayTasks.first : (_state.tasks.isNotEmpty ? _state.tasks.first : null);

    final String taskTitle = task != null ? task.title : '등록된 할일 없음';
    final String taskRepeat = task != null ? task.repeatSummary : '일반';
    final String taskTime = (task != null && task.time != null) ? task.time! : '시간 미지정';
    final bool isCompleted = task != null && task.isCompleted;

    return Container(
      width: double.infinity,
      height: 144,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                        color: const Color(0xFFFEF3C7),
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
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '반복: $taskRepeat',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    isCompleted ? '상태: 완료됨' : '상태: 진행 대기',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 우측 대형 1-Tap 확인 버튼
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
                color: isCompleted ? AppColors.completedBg : const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? AppColors.completedBorder : const Color(0xFFD97706),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted ? AppColors.completedBorder : const Color(0xFFD97706)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCompleted ? '완료됨' : '체크',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.completedText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? '탭하여 취소' : '1-Tap 체크',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.completedText.withOpacity(0.8) : Colors.white.withOpacity(0.9),
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
}
