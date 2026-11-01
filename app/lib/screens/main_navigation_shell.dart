import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../constants/hagom_dialogue.dart';
import 'meds_tab_view.dart';
import 'habits_tab_view.dart';
import 'calendar_tab_view.dart';
import 'companion_room_screen.dart';
import 'settings_screen.dart';

/// 메인 화면 셸 (Shell):
/// - 상단 헤더: 타이틀 + 설정 버튼 + 하곰이 미니 아바타
/// - 하단 탭 바: 복약 / 습관 / 달력
/// - 하곰이 미니 아바타:
///   * 누르는 즉시(지연 0초) 바로 아래 콤팩트한 말풍선이 즉각 반응하며 뜸
///   * 길게 누르거나 말풍선을 누르면 '하곰이의 방'으로 이동
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MedsTabView(),
    HabitsTabView(),
    CalendarTabView(),
  ];

  final List<String> _tabTitles = const [
    '복약 관리',
    '습관 관리',
    '기록 달력',
  ];

  String _currentBubbleMessage = '한 가지만 해도 충분해! 🐻✨';

  // 논블로킹 말풍선 표시 여부 및 자동 숨김 타이머
  bool _isBubbleVisible = false;
  Timer? _bubbleTimer;

  // 하곰이 클릭 시 지연 시간 없이 '즉시' 반응하도록 처리 (랜덤 대사 출력!)
  void _triggerCompanionBubble() {
    setState(() {
      _currentBubbleMessage = HagomDialogue.getRandomHeaderQuote();
      _isBubbleVisible = true;
    });

    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isBubbleVisible = false;
        });
      }
    });
  }

  // 하곰이의 방으로 화면 이동
  void _goToCompanionRoom() {
    _bubbleTimer?.cancel();
    setState(() {
      _isBubbleVisible = false;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CompanionRoomScreen()),
    );
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _tabTitles[_currentIndex],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '설정',
          ),
          const SizedBox(width: 4),
          // 🐻 상단 헤더 동반자 미니 아바타 (36x36dp)
          // onTapDown(마우스를 누르는 찰나의 순간)을 사용하여 0.3초 대기 없이 즉각 반응하도록 개선!
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _triggerCompanionBubble(),
            onLongPress: _goToCompanionRoom,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.headerCompanionAvatar,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 각 탭마다 독립된 Navigator를 부여하여 모달이 탭 내부에서 열리고, 하단 탭 바는 가려지지 않고 항상 최상단에 고정!
          IndexedStack(
            index: _currentIndex,
            children: [
              Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => const MedsTabView(),
                ),
              ),
              Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => const HabitsTabView(),
                ),
              ),
              Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => const CalendarTabView(),
                ),
              ),
            ],
          ),

          // 💬 헤더 하곰이 바로 아래에 뜨는 미니 콤팩트 말풍선
          if (_isBubbleVisible)
            Positioned(
              top: 8,
              right: 16,
              child: GestureDetector(
                onTap: _goToCompanionRoom, // 말풍선 탭 시 방으로 이동
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedOpacity(
                    opacity: _isBubbleVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 340), // 넉넉하게 확장하여 두 줄 줄바꿈 방지!
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _currentBubbleMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // 터치 시 물결 번짐 제거
          highlightColor: Colors.transparent, // 터치 시 배경 하이라이트 번짐 제거
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          enableFeedback: false,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: AppColors.textMuted,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: '복약',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: '습관', // '작은 습관' -> '습관' 깔끔하게 수정 완료
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: '달력',
          ),
        ],
      ),
    ),
  );
}
}
