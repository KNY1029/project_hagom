import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import 'main_navigation_shell.dart';

/// 앱 시작 화면 (SplashScreen)
/// 
/// [화면 흐름도]:
/// 1. 앱을 켜면 시작 모드(바로 시작 / 온보딩 튜토리얼 / 개발자 모드) 선택 확인:
///    - 처음 접속하거나 설정에서 초기화한 경우: 화면 중앙에 3가지 시작 모드 선택 다이얼로그 노출.
/// 2. 모드 선택이 완료(또는 기선택)되면:
///    - 오늘 첫 접속인 경우:
///      👉 화면 전체(100% Full Screen)에 하곰이 환영 GIF 애니메이션과 함께
///         "오늘도 와줘서 고마워!" 환영 인트로 화면 노출!
///         ([오늘 하루도 편안하게 시작하기] 버튼을 누르면 메인으로 진입)
///    - 오늘 이미 환영을 본 재실행인 경우:
///      👉 1.2초 빠른 로고 스플래시 후 곧바로 메인 화면으로 진입!
class SplashScreen extends StatefulWidget {
  final bool forceGreetingPreview; // 설정 등에서 다시 보기 호출용
  const SplashScreen({super.key, this.forceGreetingPreview = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppStateManager _state = AppStateManager();
  bool _isFirstLaunchToday = false;
  bool _startTutorialOnMain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStartFlow();
    });
  }

  Future<void> _initStartFlow() async {
    // SharedPreferences 로드 보장 대기
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (widget.forceGreetingPreview) {
      setState(() => _isFirstLaunchToday = true);
      return;
    }

    // 1. 처음 한 번만 묻는 시작 모드 선택 여부 확인
    if (!_state.isInitialModeSelected) {
      _showInitialModeDialog();
    } else {
      _checkGreetingAndProceed();
    }
  }

  /// 🌟 1) 최초 1회 시작 모드 선택 다이얼로그 (3가지 선택지)
  void _showInitialModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.start, color: AppColors.primaryPurple, size: 24),
            SizedBox(width: 8),
            Text('시작 모드 선택', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '하곰이 앱을 어떻게 시작할까요?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              '• 바로 시작: 튜토리얼이나 복잡한 설정 없이 내 일과로 바로 진입해요.\n• 온보딩 튜토리얼: 핵심 기능(복약·습관·달력·방)을 직접 누르며 체험해요.\n• 개발자 모드: 전체 가상 복약·과거 달력 기록을 복원하여 앱 전체를 검증해요.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          // 1) ⚡ 바로 시작하기 (기본 클린 상태)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              onPressed: () async {
                Navigator.of(dCtx).pop();
                await _state.markInitialModeSelected();
                _startTutorialOnMain = false;
                _checkGreetingAndProceed();
              },
              child: const Text('바로 시작하기 (기본 클린 상태)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            ),
          ),
          const SizedBox(height: 8),

          // 2) 🎓 온보딩 튜토리얼 시작
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              onPressed: () async {
                Navigator.of(dCtx).pop();
                await _state.markInitialModeSelected();
                await _state.setupTutorialDemoData();
                _startTutorialOnMain = true;
                _checkGreetingAndProceed();
              },
              child: const Text('온보딩 튜토리얼 시작 (체험형 가이드)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
            ),
          ),
          const SizedBox(height: 8),

          // 3) 🛠️ 개발자 모드 (전체 예시 데이터 복원)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () async {
                Navigator.of(dCtx).pop();
                await _state.markInitialModeSelected();
                await _state.restoreDevFullSimulationData();
                _startTutorialOnMain = false;
                _checkGreetingAndProceed();
              },
              child: const Text('개발자 모드 (전체 예시 데이터 복원)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 2) 오늘 첫 접속 환영 화면 여부 판별
  Future<void> _checkGreetingAndProceed() async {
    final shouldGreet = _state.shouldShowDailyGreeting();

    if (shouldGreet) {
      // 오늘 첫 접속! 풀스크린 하곰이 환영 화면 표시
      if (mounted) {
        setState(() {
          _isFirstLaunchToday = true;
        });
      }
      // 접속 완료 기록 저장
      await _state.markDailyGreetingShown();
    } else {
      // 이미 오늘 환영을 본 경우: 1초 후 부드럽게 메인으로 이동
      await Future.delayed(const Duration(milliseconds: 1000));
      _proceedToMain();
    }
  }

  void _proceedToMain() {
    if (!mounted) return;
    if (widget.forceGreetingPreview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationShell(startWithTutorial: _startTutorialOnMain),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLaunchToday) {
      return _buildDailyGreetingFullScreen();
    }
    return _buildStandardSplashScreen();
  }

  /// 🌟 [그날 첫 실행 시 화면 중앙에 크게 집중되는 하곰이 환영 뷰]
  Widget _buildDailyGreetingFullScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 🐻 1. 화면 중앙에 훨씬 더 크고 또렷하게 움직이는 하곰이 GIF
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Image.asset(
                    AppAssets.dailyGreetingGif,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🌟 2. 군더더기 없는 미니멀하고 따뜻한 한 줄 인사
              const Text(
                '오늘도 와줘서 고마워!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(flex: 1),

              // 🚀 3. 깔끔한 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _proceedToMain,
                  child: const Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 🌟 [일반 재실행 시 노출되는 산뜻한 기본 스플래시]
  Widget _buildStandardSplashScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.lightLavender,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AppAssets.splashMascot,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '하곰이와 함께하는',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '복약 & 습관 케어',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
