import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/companion_room_screen.dart';
import 'state/app_state_manager.dart';

final GlobalKey<NavigatorState> hagomNavigatorKey = GlobalKey<NavigatorState>();

/// 🚀 [공통 위젯 액션 실행기]
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
  } else if (action == 'openMeds') {
    state.setTargetTab(0);
    _navigateToTargetTab(0);
  } else if (action == 'openHabits') {
    state.setTargetTab(1);
    _navigateToTargetTab(1);
  } else if (action == 'openCalendar') {
    state.setTargetTab(2);
    _navigateToTargetTab(2);
  } else if (action == 'openRoom') {
    state.setTargetTab(0, openRoom: true);
    final nav = hagomNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const CompanionRoomScreen()));
    }
  }
}

void _navigateToTargetTab(int tabIndex) {
  final nav = hagomNavigatorKey.currentState;
  if (nav != null) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigationShell(initialTabIndex: tabIndex)),
      (route) => false,
    );
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
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) {
          handleWidgetUriAction(uri);
        }
      });

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
      navigatorKey: hagomNavigatorKey,
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
