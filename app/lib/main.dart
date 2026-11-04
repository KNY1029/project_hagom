import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'state/app_state_manager.dart';

final GlobalKey<NavigatorState> hagomNavigatorKey = GlobalKey<NavigatorState>();

/// 위젯 액션/딥링크 실행기.
///
/// 주의: Dart의 Uri.parse('hagomwidget://openHabits').host는 자동으로 소문자('openhabits')로
/// 정규화되므로, 반드시 toLowerCase()로 비교해야 한다.
Future<void> handleWidgetUriAction(Uri? uri) async {
  if (uri == null) return;

  final state = AppStateManager();
  await state.ensureInitialized();
  // 백그라운드 isolate나 이전 위젯 탭으로 디스크가 바뀐 경우를 반영
  await state.reloadFromDisk();

  final rawAction = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
  final action = rawAction.toLowerCase();
  final id = uri.queryParameters['id'];
  final slotParam = uri.queryParameters['slot'];

  if (action == 'checkmed') {
    if (id != null && slotParam != null) {
      final slotIdx = int.tryParse(slotParam) ?? -1;
      final idx = state.medications.indexWhere((m) => m.id == id);
      if (idx != -1 && slotIdx >= 0 && slotIdx < state.medications[idx].doseSlots.length) {
        final med = state.medications[idx];
        final slot = med.doseSlots[slotIdx];
        if (slot.isCompleted) {
          state.cancelSpecificSlot(med.id, slotIdx);
        } else {
          state.completeSlot(med.id, slotIdx);
        }
        await state.flushForWidget();
        return;
      }
    }
    for (final med in state.medications) {
      if (!med.isDueToday) continue;
      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (!slot.isCompleted && !slot.isSkipped) {
          state.completeSlot(med.id, i);
          await state.flushForWidget();
          return;
        }
      }
    }
  } else if (action == 'checkhabit') {
    if (id != null && state.habits.any((h) => h.id == id)) {
      final habit = state.habits.firstWhere((h) => h.id == id);
      if (habit.score >= 1.0) {
        state.resetHabitProgress(habit.id);
      } else {
        state.advanceHabitProgress(habit.id);
      }
      await state.flushForWidget();
      return;
    }
    final todayHabits = state.habits.where((h) => h.isDueToday).toList();
    for (final habit in todayHabits) {
      if (habit.score < 1.0) {
        state.advanceHabitProgress(habit.id);
        await state.flushForWidget();
        return;
      }
    }
  } else if (action == 'checktask') {
    if (id != null && state.tasks.any((t) => t.id == id)) {
      state.toggleTaskCompleted(id);
      await state.flushForWidget();
      return;
    }
    final todayTasks = state.getTasksForDay(DateTime.now());
    if (todayTasks.isNotEmpty) {
      state.toggleTaskCompleted(todayTasks.first.id);
      await state.flushForWidget();
    }
  } else if (action == 'openmeds') {
    state.setTargetTab(0);
  } else if (action == 'openhabits') {
    state.setTargetTab(1);
  } else if (action == 'opencalendar') {
    state.setTargetTab(2);
  } else if (action == 'openroom') {
    state.setTargetTab(0, openRoom: true);
  }
}

/// 안드로이드 위젯 버튼 백그라운드 콜백
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

class HagomApp extends StatefulWidget {
  const HagomApp({super.key});

  @override
  State<HagomApp> createState() => _HagomAppState();
}

class _HagomAppState extends State<HagomApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && !kIsWeb) {
      // 홈 화면 위젯에서 체크한 내용이 앱에 즉시 반영되도록 디스크에서 다시 로드
      AppStateManager().reloadFromDisk();
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
