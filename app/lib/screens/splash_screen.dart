import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import 'main_navigation_shell.dart';

/// 앱 실행 시 가장 먼저 노출되는 스플래시(시작) 화면
/// 
/// 귀여운 하곰이 마스코트와 앱 이름을 보여주고,
/// 1.5초 후 메인 네비게이션 화면으로 부드럽게 이동합니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  // 1.5초 후 메인 화면으로 이동
  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 하곰이 캐릭터 이미지
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
            // 앱 타이틀
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
            // 로딩 인디케이터
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
