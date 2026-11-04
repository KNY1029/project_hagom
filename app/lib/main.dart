import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'state/app_state_manager.dart';

/// 🚀 [안드로이드 위젯 1-Tap 백그라운드 콜백 핸들러]
/// - 앱이 꺼져있거나 닫혀있어도 홈 화면 위젯 버튼을 누르면
///   앱을 켜지 않고 백그라운드에서 복약/습관/할일 데이터를 즉시 완료 처리하고 위젯을 새로고침합니다!
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;

  final state = AppStateManager();
  // 로컬 DB 초기화 대기
  await state.ensureInitialized();

  final host = uri.host;
  final path = uri.path;
  final action = host.isNotEmpty ? host : path.replaceAll('/', '');

  if (action == 'checkMed') {
    // 다음 대기 중인 약 슬롯 복약 완료 처리
    for (final med in state.medications) {
      if (!med.isDueToday) continue;
      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (!slot.isCompleted && !slot.isSkipped) {
          state.completeSlot(med.id, i);
          return;
        }
      }
    }
  } else if (action == 'checkHabit') {
    // 첫 번째 실천 대기 습관 1-Tap 카운트 증가
    final todayHabits = state.habits.where((h) => h.isDueToday).toList();
    for (final habit in todayHabits) {
      if (habit.score < 1.0) {
        state.advanceHabitProgress(habit.id);
        return;
      }
    }
    // 다 완료된 경우 첫 번째 습관 다시 실천
    if (todayHabits.isNotEmpty) {
      state.advanceHabitProgress(todayHabits.first.id);
    }
  } else if (action == 'checkTask') {
    // 오늘 할일 완료 토글
    final now = DateTime.now();
    final todayTasks = state.getTasksForDay(now);
    if (todayTasks.isNotEmpty) {
      state.toggleTaskCompleted(todayTasks.first.id);
    } else if (state.tasks.isNotEmpty) {
      state.toggleTaskCompleted(state.tasks.first.id);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 웹이 아닐 때만 안드로이드 위젯 인터랙티브 콜백 등록
  if (!kIsWeb) {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

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
