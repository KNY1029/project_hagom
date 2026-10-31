import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HagomApp());
}

/// 하곰이 복약 & 습관 케어 애플리케이션의 루트 위젯
class HagomApp extends StatelessWidget {
  const HagomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하곰이 복약 & 습관 케어',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryPurple,
          secondary: AppColors.warmBrown,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
