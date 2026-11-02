import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import 'main_navigation_shell.dart';

/// 앱 실행 시 가장 먼저 노출되는 시작 화면
/// 
/// [1안 연출 사양]:
/// - 그날 첫 실행인 경우:
///   화면 전체(100% Full Screen)에 하곰이 환영 GIF 애니메이션과 함께
///   "오늘도 와줘서 고마워!" 따뜻한 출석 지지 멘트 노출
///   (사용자가 [오늘 시작하기]를 누르거나 3초 후 메인으로 자동 전환)
/// - 당일 이미 접속했던 재실행인 경우:
///   산뜻하고 빠른 1.5초 로고 스플래시 후 바로 메인 이동
class SplashScreen extends StatefulWidget {
  final bool forceGreetingPreview; // 설정 등에서 다시 보기 호출용
  const SplashScreen({super.key, this.forceGreetingPreview = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppStateManager _state = AppStateManager();
  bool _isFirstLaunchToday = false;

  @override
  void initState() {
    super.initState();
    _checkDailyGreetingAndNavigate();
  }

  Future<void> _checkDailyGreetingAndNavigate() async {
    // 저장소 로드 보장
    await Future.delayed(const Duration(milliseconds: 300));
    final shouldGreet = widget.forceGreetingPreview || _state.shouldShowDailyGreeting();

    if (mounted) {
      setState(() {
        _isFirstLaunchToday = shouldGreet;
      });
    }

    if (shouldGreet) {
      // 접속 기록 완료 처리
      await _state.markDailyGreetingShown();
      // 첫 접속 환영 화면은 3.5초 감상 후 자동 전환 (버튼으로 즉시 넘어가기도 가능)
      await Future.delayed(const Duration(milliseconds: 3500));
      _proceedToMain();
    } else {
      // 일반 재실행: 1.2초 빠른 스플래시
      await Future.delayed(const Duration(milliseconds: 1200));
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
            const MainNavigationShell(),
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

  /// 🌟 [그날 첫 실행 시 100% 전체 화면에 뜨는 하곰이 환영 인트로 뷰]
  Widget _buildDailyGreetingFullScreen() {
    final resetHourStr = '${_state.dailyResetHour.toString().padLeft(2, '0')}:00';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // 🐻 1. 화면 한가운데에 큼직하게 움직이는 하곰이 환영 애니메이션 GIF
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    AppAssets.dailyGreetingGif,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🌟 2. 접속 환영 타이틀
              const Text(
                '오늘도 와줘서 고마워!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // 💬 3. 따뜻한 지지 멘트
              const Text(
                '앱을 켜고 나를 마주한 것만으로도\n오늘 치료를 위한 큰 한 걸음을 내딛은 거예요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ⏰ 4. 갱신 기준 시각 칩 안내
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '매일 오전 $resetHourStr 기준 새 하루가 시작돼요',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // 🚀 5. 하단 [오늘 하루 시작하기] 버튼
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
                    '오늘 하루도 편안하게 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
