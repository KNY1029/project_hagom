import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../state/app_state_manager.dart';
import '../widgets/responsive_content.dart';

/// 📱 스마트폰 홈 위젯 쇼룸
///
/// 실제 안드로이드 공식 네이티브 위젯(XML 규격)과 1:1 픽셀 단위로 일치시킨 실시간 쇼룸:
/// 1) 🐻 하곰이 출석 응원 위젯 (2×1 규격 / 탭 시 대사 순환)
/// 2) 💊 복약 1-Tap 즉시 체크 위젯 (2×1 규격 / 100% 완료 시 하곰이 축하 화면 자동 전환)
/// 3) 🌱 습관 1-Tap 즉시 실천 위젯 (2×1 규격 / 100% 완료 시 하곰이 축하 화면 자동 전환)
/// 4) 🗓️ 할일 1-Tap 즉시 완료 위젯 (2×1 규격 / 100% 완료 시 하곰이 축하 화면 자동 전환)
/// 5) 📅 한 달 기록 달력 대시보드 위젯 (4×4 규격 / 42칸 실천 그래픽 / 상단 대칭 헤더 / 최하단 2분할 상태 바)
/// 6) 🔲 원하는 크기로 자유롭게 조절 (마스코트, 복약, 습관, 할일)
class WidgetSimulatorScreen extends StatefulWidget {
  const WidgetSimulatorScreen({super.key});

  @override
  State<WidgetSimulatorScreen> createState() => _WidgetSimulatorScreenState();
}

class _WidgetSimulatorScreenState extends State<WidgetSimulatorScreen> {
  final AppStateManager _state = AppStateManager();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // 실제 안드로이드 위젯 XML 레이아웃과 100% 동일한 색상 상수 (hagom_widget_*.xml)
  static const Color _widgetBg = Color(0xFFFAF8F5);
  static const Color _widgetDarkBg = Color(0xFF1E1B24);
  static const Color _widgetBorder = Color(0xFFE5E7EB);
  static const Color _widgetDarkBorder = Color(0xFF374151);

  static const Color _tagPurpleBg = Color(0xFFF3EDF9);
  static const Color _tagPurpleText = Color(0xFF7B61A8);

  static const Color _tagGreenBg = Color(0xFFE6F8F0);
  static const Color _tagGreenText = Color(0xFF044E36);

  static const Color _btnPurple = Color(0xFF7B61A8);

  static const Color _textMain = Color(0xFF1F2937);
  static const Color _textSub = Color(0xFF6B7280);

  // 마스코트 9단계 상태 정의 (실제 위젯 데이터와 100% 동일)
  static const List<Map<String, dynamic>> _mascotStages = [
    {
      'badge': '1. 기대',
      'quotes': [
        '하곰이는 언제나 여기 있어요!',
        '내일도 힘내서 가보자고요✨',
      ],
      'sub': '천천히 편안한 속도로 가요',
      'asset': 'assets/images/hagom_widget_stage_1.webp',
      'desc': '오늘 출석 완료 · 환영 표정',
    },
    {
      'badge': '2. 기다림',
      'quotes': [
        '하곰은(뚠뚠) 오늘도(뚠뚠) 접속을~ 기다리네(뚠뚠)',
        '오늘 할 일도 마치고 오실 때까지, 조용히 기다릴게요!',
      ],
      'sub': '유저님을 기다리는 중...',
      'asset': 'assets/images/hagom_widget_stage_2.webp',
      'desc': '어제 출석함 · 리셋 3시간 전',
    },
    {
      'badge': '3. 부담',
      'quotes': [
        '있죠 나 알고 있어요, 유저님은 할 수 있는 아이라는 거~',
        '유저니이임!! 나를 두고 어디 가신 거예요오오!!!!',
      ],
      'sub': '오늘이 끝나가고 있어요!',
      'asset': 'assets/images/hagom_widget_stage_3.webp',
      'desc': '어제 출석함 · 리셋 임박 (3시간 이내)',
    },
    {
      'badge': '4. 당황',
      'quotes': [
        '하곰이 조금은 슬플지도 몰라요...',
        '어라...? 연속 방문 기록이 깨지고 있어요😳',
      ],
      'sub': '하곰이와 눈 마주치기👀',
      'asset': 'assets/images/hagom_widget_stage_4.webp',
      'desc': '결석 1일째',
    },
    {
      'badge': '5. 분노',
      'quotes': [
        '요즘 많이 바쁜가 봐요...!!',
        '충격: 하곰이 앱 이용횟수 급감해',
      ],
      'sub': '하곰이가 지켜보고 있어요',
      'asset': 'assets/images/hagom_widget_stage_5.webp',
      'desc': '결석 3일째',
    },
    {
      'badge': '6. 슬픔',
      'quotes': [
        '너 떠난 이곳은 잠겨 눈물로🎵',
        '유저님, 큰일이에요!! 애써 쌓은 기록이...',
      ],
      'sub': '보고 싶어요😢',
      'asset': 'assets/images/hagom_widget_stage_6.webp',
      'desc': '결석 5일째',
    },
    {
      'badge': '7. 피로',
      'quotes': [
        '(진짜 안 올 거예요?? 아니 진짜로?)',
        '우리... 좋았잖아요.....',
      ],
      'sub': '지친 하곰이...',
      'asset': 'assets/images/hagom_widget_stage_7.webp',
      'desc': '결석 7일째',
    },
    {
      'badge': '8. 절망',
      'quotes': [
        '하곰이는 늘 유저님뿐이었는데ㅠ',
        '어쩜... 다른 앱으로 갈아타버린 거예요?',
      ],
      'sub': '마음이 무너지는 중...',
      'asset': 'assets/images/hagom_widget_stage_8.webp',
      'desc': '결석 10일째',
    },
    {
      'badge': '9. 붕괴',
      'quotes': [
        '그럼 하곰이... 삭제돼도 되니...?',
        '하... 유저님- 아니, 당신. 이런 관계 하곰이는 이제 지쳤어요.',
      ],
      'sub': '이웃집 녹색 부엉이가 위치추적기를 빌려준대요',
      'asset': 'assets/images/hagom_widget_stage_9.webp',
      'desc': '결석 15일 이상 장기 미접속',
    },
  ];

  static const int _currentQuoteIndex = 0;

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

  int get _activeStageIndex {
    return _state.attendanceMascotStageIndex.clamp(0, _mascotStages.length - 1);
  }

  // 실제 위젯 카드 기본 데코레이션 (@drawable/hagom_widget_bg)
  BoxDecoration _widgetBoxDecoration({bool isToday = false}) {
    return BoxDecoration(
      color: _isDark ? _widgetDarkBg : _widgetBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isToday
            ? _btnPurple
            : (_isDark ? _widgetDarkBorder : _widgetBorder),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
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
          '홈 위젯 쇼룸',
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
                color: _isDark ? AppColors.cardSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(12),
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
                          '스마트폰 홈 위젯 쇼룸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '실제 스마트폰 홈 화면의 공식 위젯과 100% 동일한 비주얼과 여백으로 미리 볼 수 있습니다.',
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
            // [위젯 1: 2×1 마스코트 출석 응원 위젯]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '1. 하곰이 출석 응원 위젯 (2×1 규격)',
              subtitle: '홈 화면에서 따뜻한 응원을 전하는 마스코트 위젯',
            ),
            const SizedBox(height: 10),

            _buildMascotWidgetCard(),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // [위젯 2: 1-Tap 즉시 체크 위젯 3종 (2×1 규격)]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '2. 인체공학적 1-Tap 즉시 체크 위젯 (2×1 규격)',
              subtitle: '우측 64×42dp 버튼으로 즉시 실천 · 100% 완료 시 축하 화면 전환',
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
              subtitle: '상단 헤더 · 42칸 실천 그래픽 · 하단 할일 바 & 습관/복약 2분할 상태 카드',
            ),
            const SizedBox(height: 10),

            _buildMonthCalendar4x4WidgetCard(),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // [위젯 4: 원하는 크기로 자유롭게 조절]
            // -------------------------------------------------------------
            _buildSectionHeader(
              title: '4. 원하는 크기로 자유롭게 조절',
              subtitle: '홈 화면에서 위젯을 길게 눌러 원하는 크기로 늘리거나 줄일 수 있어요',
            ),
            const SizedBox(height: 10),

            _buildMini1x1WidgetsRow(),
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

  // -------------------------------------------------------------
  // [위젯 1: 2×1 하곰이 마스코트 위젯 (hagom_mascot_widget.xml과 100% 동일)]
  // -------------------------------------------------------------
  Widget _buildMascotWidgetCard() {
    final stageIdx = _activeStageIndex;
    final stage = _mascotStages[stageIdx];
    final quotes = stage['quotes'] as List<String>;
    final imageAsset = stage['asset'] as String;
    final quoteText = quotes[_currentQuoteIndex % quotes.length];
    final badgeText = stage['badge'] as String? ?? '하곰이의 응원';
    final subText = stage['sub'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _widgetBoxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌측 하곰이 캐릭터 (72dp × 72dp)
          Image.asset(
            imageAsset,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.pets_rounded,
              color: _btnPurple,
              size: 40,
            ),
          ),
          const SizedBox(width: 14),

          // 우측 따뜻한 텍스트 영역 (실제 hagom_mascot_widget.xml 규격과 100% 동일)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 뱃지 (widget_mascot_badge: paddingHorizontal 7dp, vertical 2dp, 10.5sp bold)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: _tagPurpleText,
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // 메인 대사 (widget_mascot_quote: 12.5sp bold, marginTop 5dp)
                Text(
                  quoteText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _isDark ? Colors.white : _textMain,
                    height: 1.35,
                  ),
                ),
                if (subText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  // 서브 멘트 (widget_mascot_sub: 11sp, marginTop 3dp)
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 11,
                      color: _isDark ? Colors.white70 : _textSub,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-1: 복약 1-Tap 체크 위젯 (hagom_meds_widget.xml과 100% 동일)]
  // ---------------------------------------------------------------------------
  Widget _buildMedOneTapWidget() {
    String medName = '복약 없음';
    String medDetail = '등록된 약이 없거나 오늘 약이 아닙니다';
    String medId = '';

    for (final med in _state.medications) {
      if (!med.isDueToday) continue;
      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (!slot.isCompleted) {
          medName = '${med.name} ${med.dosage}';
          final sTime = slot.scheduledTime ?? '예정 시간';
          medDetail = '$sTime · 식후 복용';
          medId = med.id;
          break;
        }
      }
      if (medId.isNotEmpty) break;
    }

    final total = _state.totalDoseSlots;
    final comp = _state.completedDoseSlots;
    final bool allDone = (total > 0 && comp >= total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: _widgetBoxDecoration(),
      child: allDone
          // 🎉 100% 완료 시 전환되는 하곰이 축하 화면 (meds_celebration_view)
          ? Row(
              children: [
                Image.asset(
                  'assets/images/hagom_widget_stage_1.webp',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _tagGreenBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '오늘 복약 완료 ($comp/$total 완료)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _tagGreenText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '오늘 약을 다 챙겨 드셨네요!\n스스로를 아끼는 마음이 멋져요.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // 💊 진행 중 일반 화면 (meds_normal_view)
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '다음 복약',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tagPurpleText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$comp/$total 완료',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _isDark ? Colors.white70 : _textSub,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        medName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medDetail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _isDark ? Colors.white70 : _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 우측 네이티브 규격 1-Tap 버튼 (64dp × 42dp / 쇼룸 순수 뷰)
                Container(
                  width: 64,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _btnPurple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      '복용',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-2: 습관 1-Tap 실천 위젯 (hagom_habits_widget.xml과 100% 동일)]
  // ---------------------------------------------------------------------------
  Widget _buildHabitOneTapWidget() {
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final habit = todayHabits.isNotEmpty ? todayHabits.first : null;

    final String habitTitle = habit != null ? habit.title : '등록된 습관 없음';
    final String habitSubtitle = habit != null
        ? '${habit.subtitle}${habit.scheduledTimes.isEmpty ? '' : ' (${habit.scheduledTimes.join(', ')})'}'
        : '습관 탭에서 새로운 습관을 추가해 보세요';

    final total = todayHabits.length;
    final comp = todayHabits.where((h) => h.score >= 1.0).length;
    final bool allDone = (total > 0 && comp >= total);

    final isHabitDone = habit != null && habit.score >= 1.0;
    final isHabitPartial = habit != null && habit.score > 0 && habit.score < 1.0;
    final String habitBtnText = isHabitDone
        ? '완료'
        : (isHabitPartial ? '${habit.currentCount}/${habit.targetPerDay}' : '실천');
    final Color habitBtnBg = isHabitDone
        ? const Color(0xFFEAF8F1)
        : (isHabitPartial ? const Color(0xFFF7F3EE) : const Color(0xFFF3F4F6));
    final Color habitBtnBorder = isHabitDone
        ? const Color(0xFFA3DBC0)
        : (isHabitPartial ? const Color(0xFFE5DDD0) : const Color(0xFFE5E7EB));
    final Color habitBtnTextColor = isHabitDone
        ? const Color(0xFF1B6B46)
        : (isHabitPartial ? const Color(0xFF8B5E3C) : const Color(0xFF6B7280));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: _widgetBoxDecoration(),
      child: allDone
          // 🎉 100% 완료 시 전환되는 하곰이 축하 화면 (habits_celebration_view)
          ? Row(
              children: [
                Image.asset(
                  'assets/images/hagom_widget_stage_1.webp',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _tagGreenBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '오늘 습관 달성 ($comp/$total 완료)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _tagGreenText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '오늘 목표한 습관을 완벽히 마쳤어요!\n꾸준함이 모여 건강한 내가 돼요.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // 🌱 진행 중 일반 화면 (habits_normal_view)
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '오늘의 습관',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tagPurpleText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$comp/$total 완료',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _isDark ? Colors.white70 : _textSub,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        habitTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habitSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _isDark ? Colors.white70 : _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 우측 네이티브 규격 1-Tap 버튼 (64dp × 42dp / 쇼룸 순수 뷰)
                Container(
                  width: 64,
                  height: 42,
                  decoration: BoxDecoration(
                    color: habitBtnBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: habitBtnBorder, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      habitBtnText,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: habitBtnTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 2-3: 할일 1-Tap 체크 위젯 (hagom_calendar_widget.xml과 100% 동일)]
  // ---------------------------------------------------------------------------
  Widget _buildTaskOneTapWidget() {
    final now = DateTime.now();
    final todayTasks = _state.getTasksForDay(now);
    final task = todayTasks.isNotEmpty
        ? todayTasks.first
        : (_state.tasks.isNotEmpty ? _state.tasks.first : null);

    final String taskTitle = task != null ? task.title : '등록된 할일 없음';
    final String taskSubtitle = (task != null && task.time != null)
        ? '${task.time!} · ${task.repeatSummary}'
        : (task != null ? '반복: ${task.repeatSummary}' : '할일 탭에서 새 일정을 추가해 보세요');

    final total = todayTasks.length;
    final comp = todayTasks.where((t) => t.isCompleted).length;
    final bool allDone = (total > 0 && comp >= total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: _widgetBoxDecoration(),
      child: allDone
          // 🎉 100% 완료 시 전환되는 하곰이 축하 화면 (calendar_celebration_view)
          ? Row(
              children: [
                Image.asset(
                  'assets/images/hagom_widget_stage_1.webp',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _tagGreenBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '오늘 할일 모두 완료 ($comp/$total 완료)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _tagGreenText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '오늘 예정된 할일을 다 마쳤어요!\n편안한 마음으로 쉬어가도 좋아요.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // 🗓️ 진행 중 일반 화면 (calendar_normal_view)
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '오늘의 할일',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tagPurpleText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$comp/$total 완료',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _isDark ? Colors.white70 : _textSub,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        taskTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : _textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        taskSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _isDark ? Colors.white70 : _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 우측 네이티브 규격 1-Tap 버튼 (64dp × 42dp / 쇼룸 순수 뷰)
                Container(
                  width: 64,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _btnPurple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      '체크',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // [위젯 3: 4×4 한 달 기록 달력 대시보드 위젯 (hagom_month_calendar_widget.xml과 100% 동일)]
  // ---------------------------------------------------------------------------
  Widget _buildMonthCalendar4x4WidgetCard() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final firstDayOfWeek = DateTime(year, month, 1).weekday % 7; // 0=일요일
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final totalCells = ((firstDayOfWeek + daysInMonth + 6) ~/ 7) * 7;

    final todayTasks = _state.getTasksForDay(now);
    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final hTotal = todayHabits.length;
    final hDone = todayHabits.where((h) => h.score >= 1.0).length;

    final mTotal = _state.totalDoseSlots;
    final mDone = _state.completedDoseSlots;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _widgetBoxDecoration(),
      child: Column(
        children: [
          // 1) 상단 대칭 헤더: 이전달(◀), 완벽한 중앙 대칭 하곰이 아이콘 + 월 제목, 다음달(▶)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    '◀',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _btnPurple,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$year년 $month월 기록 달력',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.white : _textMain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'assets/images/hagom_widget_stage_1.webp',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    '▶',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _btnPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

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
          const SizedBox(height: 4),
          Divider(height: 1, color: _isDark ? _widgetDarkBorder : const Color(0xFFE5E7EB)),
          const SizedBox(height: 4),

          // 3) 달력 그리드 (실제 네이티브 레이어-리스트 XML과 1:1 일치: 4.5dp 원형 닷 & 하단 2.5dp 복약 바)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.05,
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
              final isSunday = (i % 7) == 0;

              // 실제 네이티브 위젯 실천 데이터 연동
              final mRate = _state.getMedRateForDay(cellDate);
              final hRate = _state.getHabitRateForDay(cellDate);
              final isMissedP = _state.hasMissedPrescriptionForDay(cellDate);
              final isHabitDone = hRate != null && hRate >= 1.0;
              final isMedDone = mRate != null && mRate >= 1.0;
              final dayTasks = _state.getTasksForDay(cellDate);
              final hasTasks = dayTasks.isNotEmpty;

              return Container(
                decoration: BoxDecoration(
                  color: isHabitDone
                      ? (_isDark ? const Color(0xFF1E382A) : const Color(0xFFE6F8F0))
                      : (isToday
                          ? (_isDark ? const Color(0xFF2D2638) : Colors.white)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(5),
                  border: isToday
                      ? Border.all(color: _btnPurple.withValues(alpha: 0.5), width: 1.2)
                      : null,
                ),
                child: Stack(
                  children: [
                    // 중앙 날짜 텍스트
                    Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSunday
                              ? const Color(0xFFEF4444)
                              : (_isDark ? const Color(0xFFF3F0F7) : const Color(0xFF1F2937)),
                        ),
                      ),
                    ),

                    // 우측 상단 네이티브 규격 4.5dp 원형 닷 (task_dot)
                    if (hasTasks)
                      Positioned(
                        top: 2.5,
                        right: 2.5,
                        child: Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHabitDone
                                ? const Color(0xFF059669)
                                : const Color(0xFF7B61A8),
                          ),
                        ),
                      ),

                    // 하단 밀착 2.5dp 가로 복약 바 (bar_bottom)
                    if (isMedDone)
                      Positioned(
                        bottom: 2,
                        left: 3,
                        right: 3,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      )
                    else if (isMissedP)
                      Positioned(
                        bottom: 2,
                        left: 3,
                        right: 3,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // 4) 실제 네이티브 4x4에 존재하는 상세 할일 목록 카드 (widget_month_tasks_list / 2열 분할)
          if (todayTasks.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Builder(
                builder: (context) {
                  final activeTasks = todayTasks.take(6).toList();
                  final isTwoCol = activeTasks.length > 3;
                  final leftTasks = <String>[];
                  final rightTasks = <String>[];

                  if (isTwoCol) {
                    if (activeTasks.length == 4) {
                      leftTasks.add(activeTasks[0].title);
                      leftTasks.add(activeTasks[1].title);
                      rightTasks.add(activeTasks[2].title);
                      rightTasks.add(activeTasks[3].title);
                    } else {
                      for (int i = 0; i < 3; i++) {
                        leftTasks.add(activeTasks[i].title);
                      }
                      for (int i = 3; i < activeTasks.length; i++) {
                        rightTasks.add(activeTasks[i].title);
                      }
                    }
                  } else {
                    for (final t in activeTasks) {
                      leftTasks.add(t.title);
                    }
                  }

                  Widget buildCol(List<String> items) {
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((title) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                            child: Text(
                              '• $title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: _isDark ? const Color(0xFFE8E1F0) : const Color(0xFF374151),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCol(leftTasks),
                      if (isTwoCol) ...[
                        const SizedBox(width: 4),
                        buildCol(rightTasks),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          // 5) 선택 날짜(오늘) 할일 요약 헤더 (widget_month_tasks_header)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Text(
                  '오늘의 할일',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _tagPurpleText,
                  ),
                ),
                const Spacer(),
                Text(
                  todayTasks.isEmpty
                      ? '0개'
                      : '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length} 완료',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: _tagPurpleText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 6) 최하단 2분할 상태 바 (month_bottom_panel: 습관 박스 & 복약 박스)
          Row(
            children: [
              // 좌측 습관 박스 (widget_month_habits_box)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      todayHabits.isEmpty ? '습관 없음' : '습관 $hDone/$hTotal 완료',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tagPurpleText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 우측 복약 박스 (widget_month_meds_box)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF382B4A) : _tagPurpleBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      mTotal == 0 ? '복약 없음' : '복약 $mDone/$mTotal 완료',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tagPurpleText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // [위젯 4: 원하는 크기로 자유롭게 조절 (1×1 최소 크기 모드)]
  // -------------------------------------------------------------
  Widget _buildMini1x1WidgetsRow() {
    final mComp = _state.completedDoseSlots;
    final mTotal = _state.totalDoseSlots;
    final isMedsDone = mTotal > 0 && mComp >= mTotal;

    final todayHabits = _state.habits.where((h) => h.isDueToday).toList();
    final hComp = todayHabits.where((h) => h.score >= 1.0).length;
    final hTotal = todayHabits.length;
    final isHabitsDone = hTotal > 0 && hComp >= hTotal;

    final now = DateTime.now();
    final todayTasks = _state.getTasksForDay(now);
    final tComp = todayTasks.where((t) => t.isCompleted).length;
    final tTotal = todayTasks.length;
    final isTasksDone = tTotal > 0 && tComp >= tTotal;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1) 마스코트 1x1 (hagom_mascot_widget_1x1)
        _build1x1Card(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/hagom_widget_stage_1.webp',
              fit: BoxFit.contain,
            ),
          ),
        ),

        // 2) 복약 1x1 (hagom_meds_widget_1x1)
        _build1x1Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '복약',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _tagPurpleText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$mComp/$mTotal 완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : _textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMedsDone ? '완료' : '복용 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _isDark ? Colors.white70 : _textSub,
                ),
              ),
            ],
          ),
        ),

        // 3) 습관 1x1 (hagom_habits_widget_1x1)
        _build1x1Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '습관',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _tagPurpleText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$hComp/$hTotal 완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : _textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isHabitsDone ? '완료' : '실천 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _isDark ? Colors.white70 : _textSub,
                ),
              ),
            ],
          ),
        ),

        // 4) 할일 1x1 (hagom_calendar_widget_1x1)
        _build1x1Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '할일',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _tagPurpleText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$tComp/$tTotal 완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : _textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isTasksDone ? '완료' : '진행 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _isDark ? Colors.white70 : _textSub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build1x1Card({required Widget child}) {
    return Container(
      width: 78,
      height: 78,
      decoration: _widgetBoxDecoration(),
      child: child,
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
