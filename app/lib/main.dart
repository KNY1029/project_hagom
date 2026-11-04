import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'state/app_state_manager.dart';

/// 🚀 [공통 위젯 액션 실행기]
/// - 백그라운드 콜백이든, 위젯 1-Tap 클릭 딥링크이든 동일하게 실행!
Future<void> handleWidgetUriAction(Uri? uri) async {
  if (uri == null) return;

  final state = AppStateManager();
  await state.ensureInitialized();

  final host = uri.host;
  final path = uri.path;
  final action = host.isNotEmpty ? host : path.replaceAll('/', '');

  if (action == 'checkMed') {
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
    final todayHabits = state.habits.where((h) => h.isDueToday).toList();
    for (final habit in todayHabits) {
      if (habit.score < 1.0) {
        state.advanceHabitProgress(habit.id);
        return;
      }
    }
    if (todayHabits.isNotEmpty) {
      state.advanceHabitProgress(todayHabits.first.id);
    }
  } else if (action == 'checkTask') {
    final now = DateTime.now();
    final todayTasks = state.getTasksForDay(now);
    if (todayTasks.isNotEmpty) {
      state.toggleTaskCompleted(todayTasks.first.id);
    } else if (state.tasks.isNotEmpty) {
      state.toggleTaskCompleted(state.tasks.first.id);
    }
  }
}

/// 🚀 [안드로이드 위젯 1-Tap 백그라운드 콜백]
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await handleWidgetUriAction(uri);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  runApp(const HagomApp());
}

/// 하곰이 복약 & 습관 케어 애플리케이션의 루트 위젯
class HagomApp extends StatefulWidget {
  const HagomApp({super.key});

  @override
  State<HagomApp> createState() => _HagomAppState();
}

class _HagomAppState extends State<HagomApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // 1. 앱이 꺼져있을 때 위젯 1-Tap 버튼 눌러서 켜진 경우 처리
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) {
          handleWidgetUriAction(uri);
        }
      });

      // 2. 앱이 백그라운드에 떠있을 때 위젯 1-Tap 버튼 누른 경우 즉시 처리
      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null) {
          handleWidgetUriAction(uri);
        }
      });
    }
  }

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
