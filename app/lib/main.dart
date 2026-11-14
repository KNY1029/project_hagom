import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'services/hagom_native_widget_sync.dart';
import 'state/app_state_manager.dart';

final GlobalKey<NavigatorState> hagomNavigatorKey = GlobalKey<NavigatorState>();

/// 위젯 액션/딥링크 실행기.
///
/// 정책: 위젯에서는 실수로 인한 기록 유실을 막기 위해 '완료/실천/체크'만 수행하고
/// 이미 완료된 항목을 되돌리거나 취소하는 동작은 하지 않는다(수정은 앱 내부에서만).
Future<void> handleWidgetUriAction(Uri? uri) async {
  if (uri == null) return;

  final state = AppStateManager();
  state.suspendWidgetSync = true; // 🌟 백그라운드 위젯 역주행 덮어쓰기 원천 봉쇄!
  await state.ensureInitialized();
  await state.reloadFromDisk();

  final rawAction = uri.host.isNotEmpty
      ? uri.host
      : uri.path.replaceAll('/', '');
  final action = rawAction.toLowerCase();
  if (action == 'noop') {
    // 이미 완료된 복약/습관 버튼 탭: 앱 실행도 취소도 하지 않고 버튼 터치감만 제공
    return;
  }
  await state.recordAccessDay();
  final id = uri.queryParameters['id'];
  final slotParam = uri.queryParameters['slot'];

  if (action == 'checkmed') {
    if (id != null && slotParam != null) {
      final slotIdx = int.tryParse(slotParam) ?? -1;
      final idx = state.medications.indexWhere((m) => m.id == id);
      if (idx != -1 &&
          slotIdx >= 0 &&
          slotIdx < state.medications[idx].doseSlots.length) {
        final med = state.medications[idx];
        final slot = med.doseSlots[slotIdx];
        if (!slot.isCompleted) {
          state.completeSlot(med.id, slotIdx);
          // 🌟 복약 회차 완료 시 0.8초 딜레이 뒤에 즉시 위젯을 재정렬하여 완료된 회차가 아래로 내려가도록 갱신!
          state.suspendWidgetSync = false;
          await state.flushForWidget();
        }
        return;
      }
    }
    for (final med in state.medications) {
      if (!med.isDueToday) continue;
      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (!slot.isCompleted && !slot.isSkipped) {
          state.completeSlot(med.id, i);
          state.suspendWidgetSync = false;
          await state.flushForWidget();
          return;
        }
      }
    }
  } else if (action == 'checkhabit') {
    if (id != null && state.habits.any((h) => h.id == id)) {
      final habit = state.habits.firstWhere((h) => h.id == id);
      if (habit.score < 1.0) {
        state.advanceHabitProgress(habit.id);
        // 🌟 [핵심 해결]: 완료(score >= 1.0)에 도달했을 때만 0.8초 딜레이 뒤에 완료 항목이 아래로 내려가도록 위젯 재정렬 실행!
        // 진행 중(1/4회, 조금 실천 등)일 때는 재정렬 없이 제자리에서 숫자만 전진!
        if (habit.score >= 1.0) {
          state.suspendWidgetSync = false;
          await state.flushForWidget();
        } else {
          await state.flushDataToDiskOnly();
        }
      }
      return;
    }
    final todayHabits = state.habits.where((h) => h.isDueToday).toList();
    for (final habit in todayHabits) {
      if (habit.score < 1.0) {
        state.advanceHabitProgress(habit.id);
        if (habit.score >= 1.0) {
          state.suspendWidgetSync = false;
          await state.flushForWidget();
        } else {
          await state.flushDataToDiskOnly();
        }
        return;
      }
    }
  } else if (action == 'checktask') {
    // 할일은 위젯에서도 완료 <-> 취소 토글을 자유롭게 허용
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
  } else if (action == 'openhabits') {
    state.setTargetTab(1);
  } else if (action == 'opencalendar') {
    DateTime? targetDate;
    final dateParam = uri.queryParameters['date'];
    if (dateParam != null) {
      targetDate = DateTime.tryParse(dateParam);
    }
    state.setTargetTab(2, calendarDate: targetDate);
  } else if (action == 'selectday') {
    final dateParam = uri.queryParameters['date'];
    if (dateParam != null) {
      final parsed = DateTime.tryParse(dateParam);
      if (parsed != null) {
        state.selectWidgetDate(parsed);
        await state.flushForCalendarWidgetOnly();
      }
    } else {
      final dayStr = uri.queryParameters['day'];
      if (dayStr != null) {
        final day = int.tryParse(dayStr);
        if (day != null) {
          final now = DateTime.now();
          final displayMonth = DateTime(
            now.year,
            now.month + state.widgetMonthOffset,
            1,
          );
          state.selectWidgetDate(
            DateTime(displayMonth.year, displayMonth.month, day),
          );
          await state.flushForCalendarWidgetOnly();
        }
      }
    }
  } else if (action == 'prevmonth') {
    state.changeWidgetMonthOffset(-1);
    await state.flushForCalendarWidgetOnly();
  } else if (action == 'nextmonth') {
    state.changeWidgetMonthOffset(1);
    await state.flushForCalendarWidgetOnly();
  } else if (action == 'openroom') {
    state.setTargetTab(0, openRoom: true);
  } else if (action == 'next_mascot_stage') {
    state.nextMascotStage();
    await state.flushForWidget();
  }
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await handleWidgetUriAction(uri);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // 무료 Apple 계정 빌드에서는 App Group을 사용하지 않고 Android 위젯만 동기화해요.
    // 🌟 백그라운드 위젯 터치 핸들러가 SharedPreferences에 완전히 각인될 때까지 await 보장!
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
  runApp(const HagomApp());
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final state = AppStateManager();
    state.ensureInitialized().then((_) async {
      final widgetDay = await HomeWidget.getWidgetData<String>(
        'hagom_widget_access_day',
      );
      await state.recordAccessDay(widgetDay);
      HagomNativeWidgetSync.updateNativeWidget(state);
    });
  }
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
    if (!kIsWeb) {
      if (lifecycleState == AppLifecycleState.resumed) {
        AppStateManager().reloadFromDisk();
      } else if (lifecycleState == AppLifecycleState.paused ||
          lifecycleState == AppLifecycleState.inactive ||
          lifecycleState == AppLifecycleState.hidden) {
        // 🌟 [앱 내 되돌리기/취소 즉시 위젯 반영]:
        // 앱 안에서 복약/습관 '되돌리기'를 누른 후 홈 화면으로 나가면(paused/inactive/hidden)
        // 위젯을 즉시 최신 상태로 강제 동기화하여 앱 재시작 없이도 취소 내역이 위젯에 100% 반영!
        final state = AppStateManager();
        state.suspendWidgetSync = false;
        HagomNativeWidgetSync.updateNativeWidget(state);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateManager();
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: hagomNavigatorKey,
          title: '하곰이 복약 & 습관 케어',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: state.currentThemeKey == AppColors.themeDark
                ? Brightness.dark
                : Brightness.light,
            scaffoldBackgroundColor: AppColors.activeBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.activePrimary,
              brightness: state.currentThemeKey == AppColors.themeDark
                  ? Brightness.dark
                  : Brightness.light,
              primary: AppColors.activePrimary,
              secondary: AppColors.activeWarmAccent,
              surface: AppColors.cardSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.cardSurface,
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppColors.cardSurface,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: AppColors.inputSurface,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.cardSurface,
              foregroundColor: AppColors.activeTextPrimary,
              elevation: 0,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
