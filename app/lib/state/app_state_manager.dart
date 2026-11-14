import 'dart:async';
import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../services/hagom_native_widget_sync.dart';
import '../services/hagom_alarm_manager.dart';
import '../models/task_item.dart';
import '../constants/app_colors.dart';

/// 앱 전체의 복약 및 습관 데이터를 로컬 DB에 영구 보존하고 실시간 알림을 보내는 상태 관리자
class AppStateManager extends ChangeNotifier {
  // 개발자 모드에서 달력 비교용으로 남겨둘 임시 데이터는 2026년 11월만 사용한다.
  static const int simulationPreviewYear = 2026;
  static const int simulationPreviewMonth = 11;

  // 싱글톤 패턴
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    ensureInitialized();
  }
  Completer<void>? _initCompleter;

  Future<void> ensureInitialized() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    await _initDataAndStorage();
    // 앱을 새로 열었을 때 저장된 복약·습관·할일 기준으로 알람을 복구한다.
    await HagomAlarmManager.syncScheduledAlarms(this);
    _initCompleter!.complete();
  }

  // 화면이 여러 번 갱신되는 동안 저장/위젯 작업이 겹쳐 실행되지 않도록
  // 짧은 시간 동안 발생한 변경을 하나의 동기화 작업으로 합친다.
  Timer? _persistenceDebounce;
  Future<void> _persistenceQueue = Future<void>.value();

  /// 백그라운드 위젯 콜백에서 변경된 내용을 디스크와 위젯에 즉시 확정 저장
  Future<void> flushForWidget() async {
    _persistenceDebounce?.cancel();
    _persistenceQueue = _persistenceQueue.then((_) async {
      await _saveDataToDisk();
      await HagomNativeWidgetSync.updateNativeWidget(this);
      await HagomAlarmManager.syncScheduledAlarms(this);
    });
    await _persistenceQueue;
  }

  /// 🌟 [백그라운드 전용]: 이미 네이티브가 위젯 UI를 최신 상태로 바꿨으므로,
  /// 플러터가 옛날 값으로 위젯을 덮어쓰지 않고 로컬 DB에 데이터만 조용히 영구 저장!
  Future<void> flushDataToDiskOnly() async {
    _persistenceDebounce?.cancel();
    _persistenceQueue = _persistenceQueue.then((_) => _saveDataToDisk());
    await _persistenceQueue;
  }

  /// ⚡ [초고속 Fast-path]: 달력 날짜 탭 시 불필요한 전체 위젯/디스크 연산을 건너뛰고 달력만 즉시 갱신!
  Future<void> flushForCalendarWidgetOnly() async {
    await HagomNativeWidgetSync.updateMonthCalendarOnly(this);
  }

  /// 앱이 포그라운드로 돌아올 때 위젯에서 변경한 최신 상태를 디스크에서 다시 읽어옴
  Future<void> reloadFromDisk() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.reload();
    await _loadDataFromDisk();
    // 위젯에서 바뀐 기록을 다시 읽은 뒤 알람도 최신 상태로 맞춘다.
    await HagomAlarmManager.syncScheduledAlarms(this);
  }

  bool suspendWidgetSync = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    // 가이드 체험 데이터는 실제 사용자 데이터로 저장하지 않는다.
    if (isTutorialDemoMode) return;

    // 단순 화면 재빌드마다 저장 작업과 위젯 전체 갱신을 새로 시작하지 않는다.
    // 실제 변경은 250ms 안에 모아서 한 번만 저장하고 동기화한다.
    _persistenceDebounce?.cancel();
    _persistenceDebounce = Timer(const Duration(milliseconds: 250), () {
      _persistenceQueue = _persistenceQueue.then((_) async {
        await _saveDataToDisk();
        // 개발자 미리보기는 앱 화면만 갱신하고 홈 위젯을 반복 갱신하지 않는다.
        if (!isDevSimulationMode && !suspendWidgetSync) {
          await HagomNativeWidgetSync.updateNativeWidget(this);
          await HagomAlarmManager.syncScheduledAlarms(this);
        }
      });
    });
  }

  // --- 💊 복약 데이터 ---
  final List<MedicationItem> _medications = [];
  // 🌟 현재 탭에서 보이는 활성 복약 목록 (삭제되지 않은 항목만 표시)
  List<MedicationItem> get medications =>
      _medications.where((m) => !m.isArchived).toList();
  // 🌟 전체 복약 목록 (소프트 삭제된 과거 항목 포함: 엑셀 다운로드 및 과거 달력 조회용)
  List<MedicationItem> get allMedications => _medications;

  // 🌟 오늘 복약 통계 (현재 복용 중인 활성 약물들만 집계!)
  int get totalDoseSlots => medications
      .where((m) => m.isDueToday)
      .where(
        (m) => m.recurrenceSummary != '필요 시' && m.recurrenceSummary != '오늘만',
      )
      .fold(0, (sum, m) => sum + m.totalSlotsCount);
  int get completedDoseSlots => medications
      .where((m) => m.isDueToday)
      .where(
        (m) => m.recurrenceSummary != '필요 시' && m.recurrenceSummary != '오늘만',
      )
      .fold(0, (sum, m) => sum + m.completedSlotsCount);

  // --- 🌱 습관 데이터 ---
  final List<HabitItem> _habits = [];
  // 🌟 현재 탭에서 보이는 활성 습관 목록
  List<HabitItem> get habits => _habits.where((h) => !h.isArchived).toList();
  // 🌟 전체 습관 목록 (과거 달력 및 엑셀 다운로드용)
  List<HabitItem> get allHabits => _habits;

  /// 주간 횟수 습관의 이번 주 완료 요일 목록(월~일 순서)
  List<String> weeklyHabitCompletionDays(HabitItem habit, [DateTime? now]) {
    final today = now ?? DateTime.now();
    habit.ensureWeeklyPeriod(today);
    final periodStart = habit.weeklyPeriodStart ?? today;
    final labels = ['월', '화', '수', '목', '금', '토', '일'];
    final days = <String>[];
    for (var i = 0; i <= today.difference(periodStart).inDays; i++) {
      final day = periodStart.add(Duration(days: i));
      final record = _pastHabitRecords[_dateKey(day)]?[habit.id];
      final isToday = day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      if ((record != null && record >= 1.0) || (isToday && habit.score >= 1.0)) {
        days.add(labels[day.weekday - 1]);
      }
    }
    return days.toSet().toList();
  }

  // 🌟 오늘 실천해야 하는 습관 통계 (활성 습관만 집계!)
  int get todayHabitsCount => habits
      .where((h) => h.isDueToday && h.countsTowardDailyCompletion)
      .length;
  double get habitTotalScore => habits
      .where((h) => h.isDueToday && h.countsTowardDailyCompletion)
      .fold(0.0, (sum, item) => sum + item.score);
  double get habitCompletionRate =>
      todayHabitsCount == 0 ? 0.0 : (habitTotalScore / todayHabitsCount);
  // --- ⚙️ 5대 알림 통합 설정 시스템 ---
  bool medsNotificationEnabled = true; // 일반 복약 알림 (처방약은 항상 켜짐!)
  bool habitNotificationEnabled = true; // 습관 알림
  bool tasksNotificationEnabled = true; // 일정/할일 알림
  bool mascotNotificationEnabled = true; // 하곰이 응원/넛지 알림
  bool completionFeedbackEnabled = true; // 완료 기록 안내 토스트 팝업 표시 여부
  String notificationFrequency =
      '기본'; // '최소' (정시 1회), '기본' (정시+30분), '적극적' (15분 간격 3회)
  void setMedsNotification(bool value) {
    medsNotificationEnabled = value;
    notifyListeners();
  }

  void setHabitNotification(bool value) {
    habitNotificationEnabled = value;
    notifyListeners();
  }

  void setTasksNotification(bool value) {
    tasksNotificationEnabled = value;
    notifyListeners();
  }

  void setMascotNotification(bool value) {
    mascotNotificationEnabled = value;
    notifyListeners();
  }

  // --- 🐻 하곰이 응원/상태 위젯 단계 (1~9단계) ---
  int mascotStageIndex = 0; // 0: 기대, 1: 기다림, ..., 8: 붕괴

  void nextMascotStage() {
    mascotStageIndex = (mascotStageIndex + 1) % 9;
    notifyListeners();
  }

  void setMascotStage(int index) {
    mascotStageIndex = index.clamp(0, 8);
    notifyListeners();
  }

  void setCompletionFeedbackEnabled(bool value) {
    completionFeedbackEnabled = value;
    _prefs?.setBool('hagom_completion_feedback', value);
    notifyListeners();
  }

  void setNotificationFrequency(String freq) {
    notificationFrequency = freq;
    notifyListeners();
  }

  // --- ☀️ 하루 시작 기준 시각 (기본 오전 8:00) & 일일 최초 접속 인사 애니메이션 ---
  int dailyResetHour = 8; // 기본 매일 8시 갱신 (0~23)
  int dailyResetMinute = 0; // 갱신 분 (0~59)
  String? _lastGreetingDayKey; // 'YYYY-MM-DD' 기준 마지막으로 일일 인사 본 날짜
  final Set<String> _accessDayKeys = <String>{};

  int get accessDayCount => _accessDayKeys.length;

  /// 앱 또는 위젯에서 활동한 날을 하루에 한 번만 누적한다.
  Future<void> recordAccessDay([String? activityDayKey]) async {
    await ensureInitialized();
    final key = activityDayKey ?? getEffectiveDayKey();
    if (!_accessDayKeys.add(key)) return;
    final sorted = _accessDayKeys.toList()..sort();
    if (_prefs != null) {
      await _prefs!.setString('hagom_access_days', jsonEncode(sorted));
    }
    notifyListeners();
  }

  void setDailyResetTime(int hour, int minute) {
    dailyResetHour = hour.clamp(0, 23);
    dailyResetMinute = minute.clamp(0, 59);
    notifyListeners();
  }

  void setDailyResetHour(int hour) {
    setDailyResetTime(hour, 0);
  }

  String get dailyResetTimeString {
    final period = dailyResetHour < 12 ? '오전' : '오후';
    final h12 = dailyResetHour == 0
        ? 12
        : (dailyResetHour > 12 ? dailyResetHour - 12 : dailyResetHour);
    final mStr = dailyResetMinute.toString().padLeft(2, '0');
    return '$period $h12:$mStr';
  }

  /// 현재 시각 기준으로 사용자의 '활동 날짜' 키 계산 (예: 8:00 기준이면 7:59는 어제의 하루)
  String getEffectiveDayKey([DateTime? target]) {
    final now = target ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final resetMinutes = dailyResetHour * 60 + dailyResetMinute;

    final adjusted = currentMinutes < resetMinutes
        ? now.subtract(const Duration(days: 1))
        : now;
    return '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 이 '활동 하루'에 접속 인사를 본 적이 있는지 확인 (첫 실행 시 true 반환)
  bool shouldShowDailyGreeting() {
    final currentKey = getEffectiveDayKey();
    if (_lastGreetingDayKey == null) {
      if (_prefs != null) {
        _lastGreetingDayKey = _prefs!.getString('hagom_last_greeting_day');
      }
    }
    return _lastGreetingDayKey != currentKey;
  }

  /// 접속 인사를 본 것으로 기록 완료
  Future<void> markDailyGreetingShown() async {
    final currentKey = getEffectiveDayKey();
    _lastGreetingDayKey = currentKey;
    if (_prefs != null) {
      await _prefs!.setString('hagom_last_greeting_day', currentKey);
    }
    notifyListeners();
  }

  // --- 🚀 앱 최초 실행 시 모드 선택 완료 여부 (온보딩 / 개발자 / 바로 시작) ---
  bool isInitialModeSelected = false;

  /// 모드 선택 완료로 저장
  Future<void> markInitialModeSelected() async {
    isInitialModeSelected = true;
    if (_prefs != null) {
      await _prefs!.setBool('hagom_initial_mode_selected', true);
    }
    notifyListeners();
  }

  /// 설정에서 '시작 모드 초기화' 시 호출 (다음 앱 실행 시 다시 선택창 뜸)
  Future<void> resetInitialModeSelection() async {
    isInitialModeSelected = false;
    if (_prefs != null) {
      await _prefs!.setBool('hagom_initial_mode_selected', false);
    }
    notifyListeners();
  }

  // --- 🚀 위젯 터치 시 특정 탭(복약:0, 습관:1, 달력:2) 및 하곰이 방 직행 1회성 이벤트 ---
  int? targetTabIndexRequested;
  bool shouldOpenCompanionRoom = false;

  DateTime? requestedCalendarDate;

  void setTargetTab(
    int index, {
    bool openRoom = false,
    DateTime? calendarDate,
  }) {
    targetTabIndexRequested = index;
    shouldOpenCompanionRoom = openRoom;
    requestedCalendarDate = calendarDate;
    notifyListeners();
  }

  int widgetMonthOffset = 0;
  DateTime? widgetSelectedDate; // 달력 위젯에서 현재 탭해보고 있는 실제 연-월-일 (null이면 오늘)
  int? get widgetSelectedDay => widgetSelectedDate?.day;

  void selectWidgetDate(DateTime date) {
    if (widgetSelectedDate != null &&
        widgetSelectedDate!.year == date.year &&
        widgetSelectedDate!.month == date.month &&
        widgetSelectedDate!.day == date.day) {
      // 이미 선택된 날짜를 한 번 더 누르면 오늘로 리셋
      widgetSelectedDate = null;
    } else {
      widgetSelectedDate = DateTime(date.year, date.month, date.day);
    }
    notifyListeners();
  }

  void changeWidgetMonthOffset(int delta) {
    widgetMonthOffset += delta;
    widgetSelectedDate = null; // 월 변경 시 선택 리셋
    notifyListeners();
  }

  void consumeTargetTab() {
    targetTabIndexRequested = null;
    shouldOpenCompanionRoom = false;
    requestedCalendarDate = null;
  }

  // 🛠️ 개발자 모드(전체 예시 데이터 복원 상태) 여부
  bool isDevSimulationMode = false; // 기본값: 실사용 모드 (예시 데이터 없음)
  bool isTutorialDemoMode = false; // 저장하지 않는 온보딩 체험 데이터 상태
  bool colorVisionModeEnabled = false; // 적록색맹 보조 색상 모드
  // 🎨 테마 관리 (기본 제공 프리셋 + 사용자가 추가한 커스텀 테마)
  String currentThemeKey = AppColors.themeDefault;
  final List<ThemePreset> customThemes = [];

  /// 색상이 바뀔 때마다 증가 → 앱 전체 위젯 트리를 강제 재빌드하는 신호
  int themeRevision = 0;

  List<ThemePreset> get allThemes => [
    ...AppColors.builtInThemes,
    ...customThemes,
  ];

  ThemePreset get currentTheme =>
      _findTheme(currentThemeKey) ?? AppColors.defaultTheme;

  ThemePreset? _findTheme(String key) {
    for (final t in allThemes) {
      if (t.key == key) return t;
    }
    return null;
  }

  void setTheme(String themeKey) {
    applyTheme(themeKey);
  }

  void setCustomTheme({
    required Color primary,
    required Color background,
    required Color lightTint,
    required Color textPrimary,
    Color? textSecondary,
    Color? warmAccent,
  }) {
    final key = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final preset = ThemePreset(
      key: key,
      name: '사용자 지정',
      description: '커스텀 테마',
      primary: primary,
      background: background,
      lightTint: lightTint,
      textPrimary: textPrimary,
      textSecondary: textSecondary ?? primary,
      warmAccent: warmAccent ?? primary,
      divider: AppColors.divider,
      isCustom: true,
    );
    customThemes.add(preset);
    applyTheme(key);
  }

  void applyTheme(String themeKey) {
    final theme = _findTheme(themeKey) ?? AppColors.defaultTheme;
    currentThemeKey = theme.key;
    AppColors.applyTheme(theme);
    themeRevision++;
    notifyListeners();
  }

  void setColorVisionMode(bool enabled) {
    colorVisionModeEnabled = enabled;
    AppColors.setColorVisionMode(enabled);
    notifyListeners();
  }

  /// 사용자 지정 테마를 목록에 추가하고 생성된 키를 반환 (적용은 applyTheme 으로 별도 수행)
  String addCustomTheme({
    required String name,
    required Color primary,
    required Color background,
    required Color lightTint,
    required Color textPrimary,
  }) {
    final key = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    customThemes.add(
      ThemePreset(
        key: key,
        name: name,
        description:
            '사용자 지정 · ${AppColors.toHex(primary)} / ${AppColors.toHex(background)}',
        primary: primary,
        background: background,
        lightTint: lightTint,
        textPrimary: textPrimary,
        textSecondary: Color.lerp(textPrimary, background, 0.35)!,
        warmAccent: AppColors.defaultTheme.warmAccent,
        divider: Color.lerp(lightTint, textPrimary, 0.08)!,
        isCustom: true,
      ),
    );
    notifyListeners();
    return key;
  }

  void removeCustomTheme(String key) {
    customThemes.removeWhere((t) => t.key == key);
    if (currentThemeKey == key) {
      applyTheme(AppColors.themeDefault);
      return;
    }
    notifyListeners();
  }

  // --- 📅 앱 사용 및 기록 시작일 (시작일 이전 날짜는 달력 바 및 초록색 미표시) ---
  DateTime? _trackingStartDate;
  DateTime get trackingStartDate {
    if (_trackingStartDate != null) return _trackingStartDate!;
    // 기본값: 오늘 날짜
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 특정 날짜가 기록 시작일 이전인지 확인
  bool isBeforeTrackingStart(DateTime date) {
    if (isDevSimulationMode) {
      return false;
    }
    // 사용자가 해당 날짜에 소급 수정한 기록이 있다면 기록 시작일 이전이라도 표시 허용
    if (hasPastRecordForDay(date)) {
      return false;
    }
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(trackingStartDate);
  }

  // --- 🐻 하곰이 통계 (누적 발걸음) ---
  // --- 🗓️ 할일 및 일정 데이터 ---
  final List<TaskItem> _tasks = [];
  // 🌟 현재 탭에서 보이는 활성 할일 목록
  List<TaskItem> get tasks => _tasks.where((t) => !t.isArchived).toList();
  // 🌟 전체 할일 목록 (과거 달력 및 엑셀 다운로드용)
  List<TaskItem> get allTasks => _tasks;

  // 가상 생성된 모의 할일 중 삭제된 ID 목록
  final Set<String> _hiddenMockTaskIds = {};
  final Set<String> _completedMockTaskIds = {};

  bool _isSimulationPreviewMonth(DateTime day) =>
      day.year == simulationPreviewYear && day.month == simulationPreviewMonth;

  // 특정 날짜의 할일 목록 조회
  List<TaskItem> getTasksForDay(DateTime day) {
    final existing = tasks.where((t) => t.isSameDay(day)).toList();
    if (existing.isNotEmpty) return existing;

    // 개발자 모드일 때만 예시 할일 제공
    if (isDevSimulationMode && _isSimulationPreviewMonth(day)) {
      final d = day.day;
      final mId = 't_mock_${day.year}_${day.month}_${d}';
      if (_hiddenMockTaskIds.contains(mId)) return [];
      if (d == 1 ||
          d == 4 ||
          d == 7 ||
          d == 8 ||
          d == 10 ||
          d == 11 ||
          d == 15 ||
          d == 18 ||
          d == 22 ||
          d == 25 ||
          d == 29) {
        return [
          TaskItem(
            id: mId,
            title: '병원 정기 상담 완료',
            date: day,
            time: '오전 10:00',
            isCompleted: !_completedMockTaskIds.contains(mId),
          ),
        ];
      } else if (d == 2 ||
          d == 5 ||
          d == 9 ||
          d == 12 ||
          d == 16 ||
          d == 19 ||
          d == 23 ||
          d == 26 ||
          d == 30) {
        return [
          TaskItem(
            id: mId,
            title: '복약 일지 점검',
            date: day,
            time: '오후 3:00',
            isCompleted: _completedMockTaskIds.contains(mId),
          ),
        ];
      }
    }
    return [];
  }

  // --- 📅 날짜별 복약/습관 과거 기록 및 소급 달성 관리 (소급 축하 연동) ---
  // key: 'YYYY-MM-DD'
  // value: { 'slots': Map<String, bool> }  (key: 'medId_slotIdx', value: isCompleted)
  final Map<String, Map<String, bool>> _pastSlotRecords = {};
  // value: { 'habitId': score } (0.0=미실천, 0.5=조금실천, 1.0=완료)
  final Map<String, Map<String, double>> _pastHabitRecords = {};
  final Map<String, Map<String, String>> _pastSlotTimes = {};
  String? _lastDailyStateDateKey;

  void _loadPastRecordsFromDisk() {
    if (_prefs == null) return;

    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    _pastSlotTimes.clear();
    _retroactiveSlots
      ..clear()
      ..addAll(_prefs!.getStringList('hagom_retroactive_slots') ?? []);

    try {
      final raw = _prefs!.getString('hagom_past_slot_records');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((date, records) {
          _pastSlotRecords[date] = (records as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value == true),
          );
        });
      }
    } catch (_) {}

    try {
      final raw = _prefs!.getString('hagom_past_habit_records');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((date, records) {
          _pastHabitRecords[date] = (records as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        });
      }
    } catch (_) {}

    try {
      final raw = _prefs!.getString('hagom_past_slot_times');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((date, records) {
          _pastSlotTimes[date] = (records as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value.toString()),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _rolloverDailyStateIfNeeded() async {
    if (_prefs == null) return;

    final todayKey = _dateKey(DateTime.now());
    final storedKey = _prefs!.getString('hagom_daily_state_date');
    final lastStateKey = storedKey ?? _lastGreetingDayKey;

    if (lastStateKey == null) {
      // 기존 버전 데이터에는 기준 날짜가 없으므로 오늘 상태를 보존하고
      // 다음 날짜 변경부터 새 일일 상태 기준을 적용한다.
      _lastDailyStateDateKey = todayKey;
      return;
    }

    if (lastStateKey != todayKey) {
      final stateDate = DateTime.tryParse(lastStateKey) ??
          DateTime.now().subtract(const Duration(days: 1));
      _archiveAndResetDailyState(stateDate);
    }
    _lastDailyStateDateKey = todayKey;
  }

  void _archiveAndResetDailyState(DateTime stateDate) {
    final dateKey = _dateKey(stateDate);

    for (final med in _medications) {
      // 필요 시 약은 슬롯 자체가 복용 이력이다. 과거 회차를 초기화하지 않는다.
      if (med.recurrenceSummary == '필요 시') continue;

      for (var slotIndex = 0; slotIndex < med.doseSlots.length; slotIndex++) {
        final slot = med.doseSlots[slotIndex];
        if (slot.isCompleted) {
          final slotKey = '${med.id}_$slotIndex';
          _pastSlotRecords.putIfAbsent(dateKey, () => {})[slotKey] = true;
          if (slot.takenTime != null && slot.takenTime!.isNotEmpty) {
            _pastSlotTimes.putIfAbsent(dateKey, () => {})[slotKey] =
                slot.takenTime!;
          }
        }
        slot.isCompleted = false;
        slot.isSkipped = false;
        slot.takenTime = null;
        slot.takenDate = null;
      }
      med.skipReason = null;
    }

    for (final habit in _habits) {
      habit.ensureWeeklyPeriod(DateTime.now());
      if (habit.currentCount > 0) {
        _pastHabitRecords.putIfAbsent(dateKey, () => {})[habit.id] =
            habit.score;
      }
      habit.resetProgress();
    }
  }

  // 특정 날짜의 슬롯이 '소급 수정(달력에서 나중에 수정한 것)'인지 여부 (key: 'YYYY-MM-DD_medId_slotIdx')
  final Set<String> _retroactiveSlots = {};

  /// 특정 날짜에 사용자가 직접 소급 수정한 복약/습관 기록이 있는지 확인
  bool hasPastRecordForDay(DateTime day) {
    final key = _dateKey(day);
    final hasMedRecord =
        _pastSlotRecords.containsKey(key) && _pastSlotRecords[key]!.isNotEmpty;
    final hasHabitRecord =
        _pastHabitRecords.containsKey(key) &&
        _pastHabitRecords[key]!.isNotEmpty;
    return hasMedRecord || hasHabitRecord;
  }

  bool isSlotRetroactive(DateTime day, String medId, int slotIdx) {
    final key = '${_dateKey(day)}_${medId}_$slotIdx';
    return _retroactiveSlots.contains(key);
  }

  void markSlotRetroactive(DateTime day, String medId, int slotIdx) {
    final key = '${_dateKey(day)}_${medId}_$slotIdx';
    _retroactiveSlots.add(key);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // 특정 날짜의 특정 약/슬롯 완료 여부 확인
  bool isSlotCompletedForDay(DateTime day, String medId, int slotIdx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      final med = _medications.firstWhere(
        (m) => m.id == medId,
        orElse: () => _medications.first,
      );
      if (slotIdx >= 0 && slotIdx < med.doseSlots.length) {
        return med.doseSlots[slotIdx].isCompleted;
      }
      return false;
    }

    // 🌟 [미래 날짜 철칙]: 아직 오지 않은 날짜는 무조건 미복용(false)!
    if (target.isAfter(today)) {
      return false;
    }

    final key = _dateKey(day);
    final slotKey = '${medId}_$slotIdx';
    if (_pastSlotRecords.containsKey(key) &&
        _pastSlotRecords[key]!.containsKey(slotKey)) {
      return _pastSlotRecords[key]![slotKey]!;
    }
    // 개발자 모드가 아니면 사용자가 소급 수정한 기록(_pastSlotRecords)만 반환하고 기본값은 미완료(false)
    if (!isDevSimulationMode) {
      return false;
    }
    if (!_isSimulationPreviewMonth(day)) return false;

    final d = day.day;
    if ((day.year == 2025 || day.year == 2026) && day.month == 12) {
      switch (d) {
        case 1:
        case 8:
        case 15:
        case 22:
        case 29:
          return true;
        case 2:
        case 9:
        case 16:
        case 23:
        case 30:
          return true;
        case 3:
        case 10:
        case 17:
        case 24:
        case 31:
          return medId.contains('1');
        case 4:
        case 11:
        case 18:
        case 25:
          return !medId.contains('1');
        case 5:
        case 12:
        case 19:
        case 26:
          return false;
        case 6:
        case 13:
        case 20:
        case 27:
          return medId.contains('1');
        case 7:
        case 14:
        case 21:
        case 28:
        default:
          return false;
      }
    }

    if (d == 1 || d == 2) return true;
    if (d == 3 || d == 5) return medId.contains('1');
    if (d == 4 || d == 6) return !medId.contains('1');
    if (d == 7) return false;
    if (d % 6 == 1) return true;
    if (d % 6 == 2) return true;
    if (d % 6 == 3) return medId.contains('1');
    if (d % 6 == 4) return !medId.contains('1');
    if (d % 6 == 5) return medId.contains('1');
    return !medId.contains('1');
  }

  /// 특정 날짜의 특정 약/슬롯 복용 시각 문자열 가져오기
  String? getSlotTakenTimeForDay(DateTime day, String medId, int slotIdx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      final med = _medications.firstWhere(
        (m) => m.id == medId,
        orElse: () => _medications.first,
      );
      if (slotIdx >= 0 && slotIdx < med.doseSlots.length) {
        return med.doseSlots[slotIdx].takenTime;
      }
      return null;
    }

    final key = _dateKey(day);
    final slotKey = '${medId}_$slotIdx';
    if (_pastSlotTimes.containsKey(key) &&
        _pastSlotTimes[key]!.containsKey(slotKey)) {
      return _pastSlotTimes[key]![slotKey];
    }
    // 예시 데이터 1~7일 기본 복용 시간대 맵핑
    if (isSlotCompletedForDay(day, medId, slotIdx)) {
      return slotIdx == 0 ? '오전 8:05' : '오후 12:35';
    }
    return null;
  }

  void setPastSlotTime(
    DateTime day,
    String medId,
    int slotIdx,
    String timeStr,
  ) {
    final key = _dateKey(day);
    final slotKey = '${medId}_$slotIdx';
    _pastSlotTimes.putIfAbsent(key, () => {})[slotKey] = timeStr;
    notifyListeners();
  }

  // 특정 날짜의 특정 약/슬롯 소급 완료/취소 토글 (사후 개별 기록 연동!)
  bool togglePastSlotCompleted(DateTime day, String medId, int slotIdx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      final med = _medications.firstWhere((m) => m.id == medId);
      final current = med.doseSlots[slotIdx].isCompleted;
      if (!current) {
        completeSlot(medId, slotIdx);
        return true;
      } else {
        cancelSpecificSlot(medId, slotIdx);
        return false;
      }
    }

    final key = _dateKey(day);
    final slotKey = '${medId}_$slotIdx';
    final current = isSlotCompletedForDay(day, medId, slotIdx);
    final nextVal = !current;

    _pastSlotRecords.putIfAbsent(key, () => {})[slotKey] = nextVal;
    _retroactiveSlots.add('${key}_$slotKey');
    gentleAttempts++;
    notifyListeners();
    return nextVal;
  }

  // 날짜별 상태 반환: 1.0(완전달성-연초록), 0.1~0.99(부분달성-오렌지바), 0.0(미복용/그레이바), null(미래)
  double? getMedRateForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return null; // 미래 날짜는 깨끗하게 비움
    if (isDevSimulationMode && !_isSimulationPreviewMonth(day)) return null;

    // 등록된 약이 하나도 없거나 오늘 복용할 약이 없으면 0.0 처리!
    final dueMeds = medications
        .where((m) => m.isDueOn(day))
        .where(
          (m) => m.recurrenceSummary != '필요 시' && m.recurrenceSummary != '오늘만',
        )
        .toList();
    if (dueMeds.isEmpty) return null;
    int total = 0;
    int completed = 0;

    for (final med in dueMeds) {
      for (int i = 0; i < med.doseSlots.length; i++) {
        total++;
        if (isSlotCompletedForDay(day, med.id, i)) {
          completed++;
        }
      }
    }

    if (total == 0) return 0.0;
    return completed / total;
  }

  // 특정 날짜에 '처방 필수 약물' 중 하나라도 놓친 것이 있는지 여부 (보건약학 임상 안전 관리)
  bool hasMissedPrescriptionForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return false; // 미래 날짜는 제외
    if (isDevSimulationMode && !_isSimulationPreviewMonth(day)) return false;

    final duePrescriptions = _medications.where(
      (m) =>
          m.isPrescription &&
          m.isDueOn(day) &&
          m.recurrenceSummary != '필요 시' &&
          m.recurrenceSummary != '오늘만',
    );
    for (final med in duePrescriptions) {
      for (int i = 0; i < med.doseSlots.length; i++) {
        if (!isSlotCompletedForDay(day, med.id, i)) {
          return true; // 오늘 복용해야 하는 처방 약물을 하나라도 놓쳤음!
        }
      }
    }
    return false;
  }

  // --- 🌱 날짜별 습관 달성률 및 개별 상태 조회/수정 ---

  // 특정 날짜의 특정 습관 점수 (0.0=대기, 0.5=조금실천, 1.0=완료)
  double getHabitScoreForDay(DateTime day, String habitId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      final habit = _habits.firstWhere(
        (h) => h.id == habitId,
        orElse: () => _habits.first,
      );
      return habit.score;
    }

    // 🌟 [미래 날짜 철칙]: 아직 오지 않은 날짜는 무조건 미실천(0.0)!
    if (target.isAfter(today)) {
      return 0.0;
    }

    final key = _dateKey(day);
    if (_pastHabitRecords.containsKey(key) &&
        _pastHabitRecords[key]!.containsKey(habitId)) {
      return _pastHabitRecords[key]![habitId]!;
    }
    // 개발자 모드가 아니면 사용자가 소급 수정한 기록(_pastHabitRecords)만 반환하고 기본값은 대기(0.0)
    if (!isDevSimulationMode) {
      return 0.0;
    }
    if (!_isSimulationPreviewMonth(day)) return 0.0;

    final d = day.day;
    if ((day.year == 2025 || day.year == 2026) && day.month == 12) {
      switch (d) {
        case 1:
        case 3:
        case 4:
        case 5:
        case 8:
        case 10:
        case 11:
        case 12:
        case 15:
        case 17:
        case 18:
        case 19:
        case 22:
        case 24:
        case 25:
        case 26:
        case 29:
        case 31:
          return 1.0;
        case 2:
        case 6:
        case 7:
        case 9:
        case 13:
        case 14:
        case 16:
        case 20:
        case 21:
        case 23:
        case 27:
        case 28:
        case 30:
        default:
          return 0.0;
      }
    }

    if (d == 1 || d == 3 || d == 4) return 1.0;
    if (d == 2 || d == 5 || d == 6 || d == 7) return 0.0;
    return (d % 2 == 0) ? 0.0 : 1.0;
  }

  // 특정 날짜의 전체 습관 평균 달성률 (0.0 ~ 1.0)
  double? getHabitRateForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return null;
    final dueHabits = habits
        .where((h) => h.isDueOn(day) && h.countsTowardDailyCompletion)
        .toList();
    if (dueHabits.isEmpty) return null;
    double sum = 0.0;
    for (final h in dueHabits) {
      sum += getHabitScoreForDay(day, h.id);
    }
    return sum / dueHabits.length;
  }

  // 과거 날짜의 습관 상태 소급 변경 (0.0 -> 0.5 -> 1.0 -> 1.0 유지)
  double advancePastHabitProgress(DateTime day, String habitId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      advanceHabitProgress(habitId);
      final habit = _habits.firstWhere((h) => h.id == habitId);
      return habit.score;
    }

    final key = _dateKey(day);
    final current = getHabitScoreForDay(day, habitId);
    double nextVal = current;

    if (current < 0.5) {
      nextVal = 0.5;
    } else if (current < 1.0) {
      nextVal = 1.0;
    }

    _pastHabitRecords.putIfAbsent(key, () => {})[habitId] = nextVal;
    if (nextVal > current) {
      gentleAttempts++;
    }
    notifyListeners();
    return nextVal;
  }

  // 과거 날짜의 습관 상태 되돌리기
  void resetPastHabitProgress(DateTime day, String habitId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAtSameMomentAs(today)) {
      resetHabitProgress(habitId);
      return;
    }

    final key = _dateKey(day);
    _pastHabitRecords.putIfAbsent(key, () => {})[habitId] = 0.0;
    notifyListeners();
  }

  int returnedCount = 7; // 다시 돌아온 횟수
  int gentleAttempts = 5; // 부드럽게 시도한 횟수

  // 사용자 맞춤 루틴 시간 기억 (아침, 점심, 저녁, 취침 전)
  // 사용자 맞춤 루틴 시간 기억 (아침, 점심, 저녁, 취침 전 + 식전/식후/식간)
  final Map<String, String> routineTimes = {
    '아침': '오전 8:00',
    '아침 식전': '오전 7:30',
    '아침 식후': '오전 8:30',
    '점심': '오후 12:30',
    '점심 식전': '오후 12:00',
    '점심 식후': '오후 1:00',
    '저녁': '오후 7:00',
    '저녁 식전': '오후 6:30',
    '저녁 식후': '오후 7:30',
    '취침 전': '오후 10:30',
    '식간': '오후 3:30',
  };
  // 사용자가 직접 추가한 커스텀 복약 시간대 슬롯 목록 (모든 약 추가/수정에서 영구 공유)
  final List<String> customTimeSlots = [];
  final Set<String> configuredRoutineTimeLabels = {};

  bool isRoutineTimeConfigured(String label) =>
      isDevSimulationMode || configuredRoutineTimeLabels.contains(label);

  void setRoutineTime(String label, String time) {
    routineTimes[label] = time;
    configuredRoutineTimeLabels.add(label);
    notifyListeners();
  }

  void addCustomTimeSlot(String slotName, {String? defaultTime}) {
    if (!customTimeSlots.contains(slotName)) {
      customTimeSlots.add(slotName);
      if (defaultTime != null) {
        routineTimes[slotName] = defaultTime;
      }
      notifyListeners();
    }
  }

  void removeCustomTimeSlot(String slotName) {
    customTimeSlots.remove(slotName);
    routineTimes.remove(slotName);
    notifyListeners();
  }

  SharedPreferences? _prefs;

  Future<void> _initDataAndStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadDataFromDisk();
    } catch (_) {}
  }

  // 로컬 DB에 변경 사항 자동 영구 저장 (앱을 껐다 켜도 100% 보존!)
  Future<void> _saveDataToDisk() async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        return;
      }
    }
    try {
      final medsJson = jsonEncode(_medications.map((m) => m.toJson()).toList());
      final habitsJson = jsonEncode(_habits.map((h) => h.toJson()).toList());
      final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());

      await _prefs!.setString('hagom_medications', medsJson);
      await _prefs!.setString('hagom_habits', habitsJson);
      await _prefs!.setString('hagom_tasks', tasksJson);
      await _prefs!.setInt('hagom_gentle_attempts', gentleAttempts);
      await _prefs!.setInt('hagom_returned_count', returnedCount);
      await _prefs!.setBool('hagom_meds_noti', medsNotificationEnabled);
      await _prefs!.setBool('hagom_habit_noti', habitNotificationEnabled);
      await _prefs!.setBool('hagom_tasks_noti', tasksNotificationEnabled);
      await _prefs!.setBool('hagom_mascot_noti', mascotNotificationEnabled);
      await _prefs!.setInt('hagom_mascot_stage_index', mascotStageIndex);
      await _prefs!.setBool(
        'hagom_completion_feedback',
        completionFeedbackEnabled,
      );
      await _prefs!.setString('hagom_noti_freq', notificationFrequency);
      await _prefs!.setInt('hagom_daily_reset_hour', dailyResetHour);
      await _prefs!.setInt('hagom_daily_reset_minute', dailyResetMinute);
      if (_lastGreetingDayKey != null) {
        await _prefs!.setString(
          'hagom_last_greeting_day',
          _lastGreetingDayKey!,
        );
      }
      final accessDays = _accessDayKeys.toList()..sort();
      await _prefs!.setString('hagom_access_days', jsonEncode(accessDays));
      await _prefs!.setBool(
        'hagom_initial_mode_selected',
        isInitialModeSelected,
      );
      await _prefs!.setBool('hagom_dev_simulation_mode', isDevSimulationMode);
      await _prefs!.setBool('hagom_color_vision_mode', colorVisionModeEnabled);
      if (_trackingStartDate != null) {
        await _prefs!.setString(
          'hagom_tracking_start_date',
          _dateKey(_trackingStartDate!),
        );
      }
      await _prefs!.setStringList('hagom_custom_time_slots', customTimeSlots);
      await _prefs!.setStringList(
        'hagom_configured_routine_time_labels',
        configuredRoutineTimeLabels.toList(),
      );
      await _prefs!.setString('hagom_routine_times', jsonEncode(routineTimes));
      await _prefs!.setString(
        'hagom_past_slot_records',
        jsonEncode(_pastSlotRecords),
      );
      await _prefs!.setString(
        'hagom_past_habit_records',
        jsonEncode(_pastHabitRecords),
      );
      await _prefs!.setString('hagom_past_slot_times', jsonEncode(_pastSlotTimes));
      await _prefs!.setStringList(
        'hagom_retroactive_slots',
        _retroactiveSlots.toList(),
      );
      _lastDailyStateDateKey ??= _dateKey(DateTime.now());
      await _prefs!.setString(
        'hagom_daily_state_date',
        _lastDailyStateDateKey!,
      );
      await _prefs!.setString('hagom_theme_key', currentThemeKey);
      await _prefs!.setString(
        'hagom_custom_themes',
        jsonEncode(customThemes.map((t) => t.toJson()).toList()),
      );
      await _prefs!.setInt('hagom_widget_month_offset', widgetMonthOffset);
      if (widgetSelectedDate != null) {
        await _prefs!.setString(
          'hagom_widget_selected_date',
          _dateKey(widgetSelectedDate!),
        );
      } else {
        await _prefs!.remove('hagom_widget_selected_date');
      }
    } catch (_) {}
  }

  // 앱 켤 때 로컬 DB에서 기존 저장 데이터 불러오기
  Future<void> _loadDataFromDisk() async {
    if (_prefs == null) return;
    try {
      final savedDevMode = _prefs!.getBool('hagom_dev_simulation_mode');
      isDevSimulationMode = savedDevMode ?? false;
      colorVisionModeEnabled =
          _prefs!.getBool('hagom_color_vision_mode') ?? false;
      AppColors.setColorVisionMode(colorVisionModeEnabled);
      final medsRaw = _prefs!.getString('hagom_medications');
      final customThemesRaw = _prefs!.getString('hagom_custom_themes');
      customThemes.clear();
      if (customThemesRaw != null) {
        final List<dynamic> decodedThemes = jsonDecode(customThemesRaw);
        customThemes.addAll(
          decodedThemes.map(
            (e) => ThemePreset.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      currentThemeKey =
          _prefs!.getString('hagom_theme_key') ?? AppColors.themeDefault;
      AppColors.applyTheme(currentTheme);
      currentThemeKey = currentTheme.key;
      themeRevision++;
      widgetMonthOffset = _prefs!.getInt('hagom_widget_month_offset') ?? 0;
      final savedSelDate = _prefs!.getString('hagom_widget_selected_date');
      if (savedSelDate != null) {
        widgetSelectedDate = DateTime.tryParse(savedSelDate);
      }
      if (medsRaw != null) {
        final List<dynamic> decoded = jsonDecode(medsRaw);
        _medications.clear();
        _medications.addAll(
          decoded.map(
            (e) => MedicationItem.fromJson(e as Map<String, dynamic>),
          ),
        );
        // 개발자 모드일 때만 예시 주 1회 약물(med_3) 추가
        if (isDevSimulationMode && !_medications.any((m) => m.id == 'med_3')) {
          _medications.add(
            MedicationItem(
              id: 'med_3',
              name: '주 1회 복용약 (예시)',
              dosage: '1정 · 매주 일요일 아침',
              recurrenceSummary: '매주 일요일',
              repeatDays: ['일'],
              durationSummary: '계속 복용',
              isPrescription: false,
              startDate: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                1,
              ),
              doseSlots: [
                DoseSlot(
                  label: '아침',
                  scheduledTime: '오전 9:00',
                  isCompleted: false,
                ),
              ],
            ),
          );
        }
        // 기존 저장된 실제 이름들도 예시 이름으로 치환
        for (var m in _medications) {
          if (m.name == 'Focusin') m.name = '처방약 (예시 A)';
          if (m.name == '비타민 D & 오메가3') m.name = '일반 영양제 (예시 B)';
          if (m.name == '비타민 D 고용량 (주 1회)') m.name = '주 1회 복용약 (예시)';
          if (isDevSimulationMode &&
              (m.id == 'med_1' || m.id == 'med_2' || m.id == 'med_3')) {
            final now = DateTime.now();
            m.startDate = DateTime(now.year, now.month, 1);
            m.createdDate = m.startDate;
          }
        }
      }
      final startRaw = _prefs!.getString('hagom_tracking_start_date');
      if (startRaw != null) {
        _trackingStartDate = DateTime.tryParse(startRaw);
      } else {
        // 최초 로드 시 오늘 날짜를 기록 시작일로 고정
        final now = DateTime.now();
        _trackingStartDate = DateTime(now.year, now.month, now.day);
        await _prefs!.setString(
          'hagom_tracking_start_date',
          _dateKey(_trackingStartDate!),
        );
      }
      final habitsRaw = _prefs!.getString('hagom_habits');
      if (habitsRaw != null) {
        final List<dynamic> decoded = jsonDecode(habitsRaw);
        _habits.clear();
        _habits.addAll(
          decoded.map((e) => HabitItem.fromJson(e as Map<String, dynamic>)),
        );
        if (isDevSimulationMode && !_habits.any((h) => h.id == 'habit_5')) {
          _habits.add(
            HabitItem(
              id: 'habit_5',
              title: '침구 정리 및 환기하기 (예시)',
              subtitle: '주 1회 · 이미 이번 주 완료됨',
              recurrenceSummary: '주 1회',
              targetPerDay: 1,
              currentCount: 0,
              weeklyCompletedCount: 1, // 이번 주 완료 상태
            ),
          );
        }
      }
      final tasksRaw = _prefs!.getString('hagom_tasks');
      if (tasksRaw != null) {
        final List<dynamic> decoded = jsonDecode(tasksRaw);
        _tasks.clear();
        _tasks.addAll(
          decoded.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)),
        );
        // 이전 월별 비교 작업에서 저장된 1~10월 샘플 일정 제거
        _tasks.removeWhere(
          (task) =>
              task.id.startsWith('t_sim_') &&
              !_isSimulationPreviewMonth(task.date),
        );
      }
      // 이전 버전에서 개발자 모드 플래그 없이 저장된 예시 데이터는
      // 실사용 모드로 간주하고 최초 1회만 제거한다.
      if (savedDevMode == null) {
        _medications.removeWhere(
          (med) => med.id == 'med_1' || med.id == 'med_2' || med.id == 'med_3',
        );
        _habits.removeWhere(
          (habit) => RegExp(r'^habit_[1-5]$').hasMatch(habit.id),
        );
        _tasks.removeWhere(
          (task) =>
              task.id.startsWith('t_nov') || task.id.startsWith('task_today_'),
        );
        await _prefs!.setBool('hagom_dev_simulation_mode', false);
      }
      gentleAttempts =
          _prefs!.getInt('hagom_gentle_attempts') ?? gentleAttempts;
      returnedCount = _prefs!.getInt('hagom_returned_count') ?? returnedCount;
      medsNotificationEnabled = _prefs!.getBool('hagom_meds_noti') ?? true;
      habitNotificationEnabled = _prefs!.getBool('hagom_habit_noti') ?? true;
      tasksNotificationEnabled = _prefs!.getBool('hagom_tasks_noti') ?? true;
      mascotNotificationEnabled = _prefs!.getBool('hagom_mascot_noti') ?? true;
      mascotStageIndex = _prefs!.getInt('hagom_mascot_stage_index') ?? 0;
      completionFeedbackEnabled =
          _prefs!.getBool('hagom_completion_feedback') ?? true;
      notificationFrequency = _prefs!.getString('hagom_noti_freq') ?? '기본';
      dailyResetHour = _prefs!.getInt('hagom_daily_reset_hour') ?? 8;
      dailyResetMinute = _prefs!.getInt('hagom_daily_reset_minute') ?? 0;
      _lastGreetingDayKey = _prefs!.getString('hagom_last_greeting_day');
      final accessDaysRaw = _prefs!.getString('hagom_access_days');
      _accessDayKeys.clear();
      if (accessDaysRaw != null) {
        final decodedAccessDays = jsonDecode(accessDaysRaw) as List<dynamic>;
        _accessDayKeys.addAll(decodedAccessDays.whereType<String>());
      }
      if (_accessDayKeys.isEmpty && _lastGreetingDayKey != null) {
        _accessDayKeys.add(_lastGreetingDayKey!);
      }
      isInitialModeSelected =
          _prefs!.getBool('hagom_initial_mode_selected') ?? false;
      final loadedCustomSlots = _prefs!.getStringList(
        'hagom_custom_time_slots',
      );
      if (loadedCustomSlots != null) {
        customTimeSlots.clear();
        customTimeSlots.addAll(loadedCustomSlots);
      }
      configuredRoutineTimeLabels
        ..clear()
        ..addAll(
          _prefs!.getStringList('hagom_configured_routine_time_labels') ?? [],
        );
      // 예전에 자동 생성된 기본 회차 라벨은 사용자 커스텀 시간대가 아니다.
      customTimeSlots.removeWhere(
        (label) =>
            label.trim() == '복용' || RegExp(r'^\d+회차$').hasMatch(label.trim()),
      );
      // 이미 약에 저장된 비표준 시간대 라벨도 커스텀 칩 목록에 자동 복원 (레이스 유실 방어)
      const standardLabels = {
        '아침',
        '아침 식전',
        '아침 식후',
        '점심',
        '점심 식전',
        '점심 식후',
        '저녁',
        '저녁 식전',
        '저녁 식후',
        '취침 전',
        '식간',
      };
      for (final med in _medications) {
        for (final slot in med.doseSlots) {
          final l = slot.label.trim();
          if (l.isNotEmpty &&
              l != '복용' &&
              !RegExp(r'^\d+회차$').hasMatch(l) &&
              !standardLabels.contains(l) &&
              !customTimeSlots.contains(l)) {
            customTimeSlots.add(l);
          }
        }
      }
      final loadedRoutineTimesRaw = _prefs!.getString('hagom_routine_times');
      if (loadedRoutineTimesRaw != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(
            loadedRoutineTimesRaw,
          );
          routineTimes.clear();
          decoded.forEach((key, value) {
            routineTimes[key] = value.toString();
          });
        } catch (_) {}
      }
      _loadPastRecordsFromDisk();
      await _rolloverDailyStateIfNeeded();
      notifyListeners();
    } catch (_) {}
  }

  void _initDefaultData() {
    _medications.addAll([
      MedicationItem(
        id: 'med_1',
        name: '처방약 (예시 A)',
        dosage: '10mg · 식후 30분',
        recurrenceSummary: '매일',
        durationSummary: '계속 복용',
        isPrescription: true,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        doseSlots: [
          DoseSlot(
            label: '아침',
            scheduledTime: '오전 8:00',
            isCompleted: true,
            takenTime: '오전 8:05',
          ),
          DoseSlot(label: '점심', scheduledTime: '오후 12:30', isCompleted: false),
        ],
      ),
      MedicationItem(
        id: 'med_2',
        name: '일반 영양제 (예시 B)',
        dosage: '1캡슐 · 저녁 식후',
        recurrenceSummary: '매일',
        durationSummary: '계속 복용',
        isPrescription: false,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        doseSlots: [
          DoseSlot(label: '저녁', scheduledTime: '오후 7:00', isCompleted: false),
        ],
      ),
      // 🌟 일주일에 한 번만 복용하는 약 예시
      MedicationItem(
        id: 'med_3',
        name: '주 1회 복용약 (예시)',
        dosage: '1정 · 매주 일요일 아침',
        recurrenceSummary: '매주 일요일',
        repeatDays: ['일'],
        durationSummary: '계속 복용',
        isPrescription: false,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        doseSlots: [
          DoseSlot(label: '아침', scheduledTime: '오전 9:00', isCompleted: false),
        ],
      ),
    ]);

    _habits.addAll([
      HabitItem(
        id: 'habit_1',
        title: '물 마시기',
        subtitle: '하루 4잔 시원하게',
        targetPerDay: 4,
        currentCount: 3, // 3/4잔
      ),
      HabitItem(
        id: 'habit_2',
        title: '오늘 계획 가볍게 보기',
        subtitle: '유연하게 · 1분이라도 충분해요',
        targetPerDay: 1,
        currentCount: 2, // 완료
      ),
      HabitItem(
        id: 'habit_3',
        title: '가볍게 몸 움직이기',
        subtitle: '스트레칭 · 5~10분',
        targetPerDay: 1,
        currentCount: 1, // 조금 실천
      ),
      HabitItem(
        id: 'habit_4',
        title: '자기 전 스마트폰 내려놓기',
        subtitle: '취침 전 · 편안한 밤을 위해',
        targetPerDay: 1,
        currentCount: 0, // 대기
      ),
      HabitItem(
        id: 'habit_5',
        title: '침구 정리 및 환기하기 (예시)',
        subtitle: '주 1회 · 이미 이번 주 완료됨',
        recurrenceSummary: '주 1회',
        targetPerDay: 1,
        currentCount: 0,
        weeklyCompletedCount: 1,
      ),
    ]);
    // 기본 예시 일정 (PRD 5.3절 명세: 보고서 작성, 병원 진료 등)
    // 🌟 [할일 검증용]: 11월 1일(1개), 2일(2개), 3일(3개), 4일(4개), 5일(5개), 6일(6개)
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;

    _tasks.addAll([
      // 11/01 (1개)
      TaskItem(
        id: 't_nov1_1',
        title: '산책하며 햇볕 쬐기',
        date: DateTime(y, m, 1),
        time: '오후 2:00',
        isCompleted: true,
      ),

      // 11/02 (2개)
      TaskItem(
        id: 't_nov2_1',
        title: '약국에서 비타민 구매',
        date: DateTime(y, m, 2),
        time: '오전 10:30',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov2_2',
        title: '스트레칭 10분 하기',
        date: DateTime(y, m, 2),
        time: '오후 7:00',
        isCompleted: false,
      ),

      // 11/03 (3개)
      TaskItem(
        id: 't_nov3_1',
        title: '병원 정기 상담 및 처방전',
        date: DateTime(y, m, 3),
        time: '오전 11:00',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov3_2',
        title: '복약 상담 일지 정리',
        date: DateTime(y, m, 3),
        time: '오후 3:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov3_3',
        title: '따뜻한 차 마시며 쉬기',
        date: DateTime(y, m, 3),
        time: '오후 9:00',
        isCompleted: false,
      ),

      // 11/04 (4개: 2x2 대칭 분할 테스트)
      TaskItem(
        id: 't_nov4_1',
        title: '유기화학 과제 12장 예제 풀기',
        date: DateTime(y, m, 4),
        time: '오후 1:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov4_2',
        title: '도서관 책 반납하기',
        date: DateTime(y, m, 4),
        time: '오후 3:30',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov4_3',
        title: '약학 실습 예습 리포트',
        date: DateTime(y, m, 4),
        time: '오후 5:00',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov4_4',
        title: '가벼운 저녁 러닝',
        date: DateTime(y, m, 4),
        time: '오후 8:00',
        isCompleted: false,
      ),

      // 11/05 (5개: 좌3 + 우2 분할 테스트)
      TaskItem(
        id: 't_nov5_1',
        title: '정신건강의학과 진료 방문',
        date: DateTime(y, m, 5),
        time: '오전 10:00',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov5_2',
        title: '영양제 재고 확인하기',
        date: DateTime(y, m, 5),
        time: '오후 12:30',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov5_3',
        title: '동기들과 스터디 모임',
        date: DateTime(y, m, 5),
        time: '오후 3:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov5_4',
        title: '식물 물 주기',
        date: DateTime(y, m, 5),
        time: '오후 6:00',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov5_5',
        title: '하루 마무리 일기 쓰기',
        date: DateTime(y, m, 5),
        time: '오후 10:00',
        isCompleted: false,
      ),

      // 11/06 (6개: 좌3 + 우3 꽉 찬 분할 테스트)
      TaskItem(
        id: 't_nov6_1',
        title: '약물 치료학 수업 필기 정리',
        date: DateTime(y, m, 6),
        time: '오전 9:30',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov6_2',
        title: '혈압 및 맥박 체크하기',
        date: DateTime(y, m, 6),
        time: '오후 1:30',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov6_3',
        title: '동네 한 바퀴 산책',
        date: DateTime(y, m, 6),
        time: '오후 4:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov6_4',
        title: '수면 위생 체크리스트 확인',
        date: DateTime(y, m, 6),
        time: '오후 7:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 't_nov6_5',
        title: '내일 복약 파우치 미리 챙기기',
        date: DateTime(y, m, 6),
        time: '오후 9:30',
        isCompleted: true,
      ),
      TaskItem(
        id: 't_nov6_6',
        title: '잠들기 전 스마트폰 멀리 두기',
        date: DateTime(y, m, 6),
        time: '오후 11:00',
        isCompleted: false,
      ),

      // 오늘 날짜 기본 예시
      TaskItem(
        id: 'task_today_1',
        title: '약학 실습 보고서 작성',
        date: DateTime(y, m, now.day),
        time: '오후 6:00',
        isCompleted: false,
      ),
      TaskItem(
        id: 'task_today_2',
        title: '병원 정기 상담 및 처방전 받기',
        date: DateTime(y, m, now.day),
        time: '오후 2:30',
        isCompleted: false,
      ),
    ]);
  }

  // --- 💊 복약 액션 메서드 ---

  // 스마트 복용 완료:
  // 1. 아직 완료되지 않은 회차를 완료 처리
  // 2. 🌟 약학적 혈중 농도(반감기) 유지: 만약 'N시간마다' 복용하는 약이라면,
  //    방금 '지금 복용'한 실제 시각을 기준으로 다음 회차의 예정 시각을 실시간 재계산하여 알림 갱신!
  void completeNextSlot(String medId, {String? customTakenTime}) {
    final med = _medications.firstWhere((m) => m.id == medId);
    final isAsNeeded = med.recurrenceSummary == '필요 시';
    DoseSlot? targetSlot = med.nextPendingSlot;
    if (isAsNeeded && targetSlot == null) {
      final today = DateTime.now();
      final todayCount = med.doseSlots.where((slot) {
        final date = slot.takenDate;
        return slot.isCompleted &&
            date != null &&
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      }).length;
      targetSlot = DoseSlot(label: '${todayCount + 1}회차', scheduledTime: null);
      med.doseSlots.add(targetSlot);
    }
    if (targetSlot != null) {
      final wasCompleted = targetSlot.isCompleted;
      targetSlot.isCompleted = true;
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? '오후' : '오전';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      targetSlot.takenTime = customTakenTime ?? '$period $displayHour:$minute';
      targetSlot.takenDate = DateTime(now.year, now.month, now.day);
      if (!wasCompleted) _decrementPillCount(med);

      // N시간 간격 약물인 경우 다음 회차 시간 동적 재계산
      _recalculateHourlyNextSlot(med, now);

      gentleAttempts++;
      notifyListeners();
    }
  }

  // 특정 슬롯 직접 완료
  void completeSlot(String medId, int slotIndex) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      final slot = med.doseSlots[slotIndex];
      if (!slot.isCompleted) {
        slot.isCompleted = true;
        final now = DateTime.now();
        final hour = now.hour;
        final minute = now.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? '오후' : '오전';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        slot.takenTime = '$period $displayHour:$minute';
        slot.takenDate = DateTime(now.year, now.month, now.day);
        _decrementPillCount(med);

        _recalculateHourlyNextSlot(med, now);

        gentleAttempts++;
        notifyListeners();
      }
    }
  }

  // N시간 간격 약물의 다음 회차 예정 시각 재계산 로직
  void _recalculateHourlyNextSlot(MedicationItem med, DateTime takenDateTime) {
    if (med.recurrenceSummary.contains('시간') ||
        med.recurrenceSummary.contains('분') ||
        med.doseSlots.any((s) => s.label.contains('회차'))) {
      final hMatch = RegExp(r'(\d+)시간').firstMatch(med.recurrenceSummary);
      final mMatch = RegExp(r'(\d+)분').firstMatch(med.recurrenceSummary);
      final intHours = hMatch != null ? int.parse(hMatch.group(1)!) : 0;
      final intMinutes = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
      final totalMinutes = (intHours * 60) + intMinutes;
      final addMinutes = totalMinutes > 0 ? totalMinutes : 240; // 기본 4시간

      final nextTime = takenDateTime.add(Duration(minutes: addMinutes));
      final nHour = nextTime.hour;
      final nMin = nextTime.minute.toString().padLeft(2, '0');
      final nPeriod = nHour >= 12 ? '오후' : '오전';
      final nDisplayH = nHour > 12 ? nHour - 12 : (nHour == 0 ? 12 : nHour);
      final nextTimeStr = '$nPeriod $nDisplayH:$nMin';

      // 🌟 다음 회차가 아직 없으면 다음 회차(2회차, 3회차...)를 동적으로 바로 생성!
      final nextSlot = med.nextPendingSlot;
      if (nextSlot != null) {
        nextSlot.scheduledTime = nextTimeStr;
      } else {
        // 이미 있는 슬롯이 모두 완료되었으므로, 다음 회차를 새로 추가!
        final nextIndex = med.doseSlots.length + 1;
        med.doseSlots.add(
          DoseSlot(label: '$nextIndex회차', scheduledTime: nextTimeStr),
        );
      }
    }
  }

  // 특정 회차 실제 복용 시간 수정
  void updateSlotTakenTime(String medId, int slotIndex, String newTakenTime) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      final wasCompleted = med.doseSlots[slotIndex].isCompleted;
      med.doseSlots[slotIndex].takenTime = newTakenTime;
      med.doseSlots[slotIndex].isCompleted = true;
      final now = DateTime.now();
      med.doseSlots[slotIndex].takenDate = DateTime(
        now.year,
        now.month,
        now.day,
      );
      if (!wasCompleted) _decrementPillCount(med);
      notifyListeners();
    }
  }

  // 특정 회차만 핀셋 복약 취소 (뒤쪽 회차 건드리지 않고 해당 슬롯만 쏙 취소)
  void cancelSpecificSlot(String medId, int slotIndex) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      final wasCompleted = med.doseSlots[slotIndex].isCompleted;
      med.doseSlots[slotIndex].isCompleted = false;
      med.doseSlots[slotIndex].takenTime = null;
      med.doseSlots[slotIndex].takenDate = null;
      if (wasCompleted) _restorePillCount(med);
      notifyListeners();
    }
  }

  // 복약 되돌리기 (가장 최근 완료된 회차 취소)
  void revertMedication(String id) {
    final med = _medications.firstWhere((m) => m.id == id);
    for (int i = med.doseSlots.length - 1; i >= 0; i--) {
      if (med.doseSlots[i].isCompleted) {
        med.doseSlots[i].isCompleted = false;
        med.doseSlots[i].takenTime = null;
        med.doseSlots[i].takenDate = null;
        _restorePillCount(med);
        break;
      }
    }
    suspendWidgetSync = false;
    notifyListeners();
    HagomNativeWidgetSync.updateNativeWidget(this);
  }

  // cancelLastCompletedSlot 별칭
  void cancelLastCompletedSlot(String id) => revertMedication(id);

  void _decrementPillCount(MedicationItem med) {
    if (!med.usePillCount || med.remainingPillCount == null) return;
    med.remainingPillCount = (med.remainingPillCount! - 1).clamp(0, 999999);
  }

  void _restorePillCount(MedicationItem med) {
    if (!med.usePillCount || med.remainingPillCount == null) return;
    med.remainingPillCount = (med.remainingPillCount! + 1).clamp(0, 999999);
  }

  void setMedicationPillCount({
    required String medId,
    required bool enabled,
    required int initialCount,
    bool resetRemaining = true,
  }) {
    final med = _medications.firstWhere((m) => m.id == medId);
    med.usePillCount = enabled;
    if (!enabled) {
      med.initialPillCount = null;
      med.remainingPillCount = null;
    } else {
      final count = initialCount.clamp(0, 999999);
      med.initialPillCount = count;
      if (resetRemaining || med.remainingPillCount == null) {
        med.remainingPillCount = count;
      }
    }
    notifyListeners();
  }

  void setRemainingPillCount(String medId, int count) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (!med.usePillCount) return;
    med.remainingPillCount = count.clamp(0, 999999);
    notifyListeners();
  }
  // 🌿 특정 회차만 건너뛰기 처리 (다음 대기 회차 슬롯 건너뜀)
  void skipNextSlot(String id, {String? reason}) {
    final med = _medications.firstWhere((m) => m.id == id);
    final target = med.nextPendingSlot;
    if (target != null) {
      target.isSkipped = true;
      final trimmedReason = reason?.trim();
      med.skipReason = trimmedReason == null || trimmedReason.isEmpty
          ? null
          : trimmedReason;
      notifyListeners();
    }
  }

  // 특정 회차 지정 건너뛰기
  void skipSpecificSlot(String id, int slotIndex) {
    final med = _medications.firstWhere((m) => m.id == id);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      med.doseSlots[slotIndex].isSkipped = true;
      notifyListeners();
    }
  }

  // 특정 회차 건너뜀 복구 (대기 상태로 롤백)
  void restoreSkippedSlot(String id, int slotIndex) {
    final med = _medications.firstWhere((m) => m.id == id);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      med.doseSlots[slotIndex].isSkipped = false;
      if (!med.doseSlots.any((slot) => slot.isSkipped)) {
        med.skipReason = null;
      }
      notifyListeners();
    }
  }

  // 복약 카드 아코디언 토글
  void toggleMedExpanded(String id) {
    final med = _medications.firstWhere((m) => m.id == id);
    med.isExpanded = !med.isExpanded;
    notifyListeners();
  }

  // 새 약 추가
  void addMedication({
    required String name,
    required String dosage,
    required List<DoseSlot> doseSlots,
    String recurrenceSummary = '매일',
    String durationSummary = '계속 복용',
    bool isPrescription = false,
    List<String>? repeatDays,
    String? memo,
    DateTime? startDate,
    DateTime? endDate,
    bool usePillCount = false,
    int? initialPillCount,
  }) {
    _medications.add(
      MedicationItem(
        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        dosage: dosage,
        doseSlots: doseSlots,
        recurrenceSummary: recurrenceSummary,
        durationSummary: durationSummary,
        isPrescription: isPrescription,
        repeatDays: repeatDays ?? [],
        memo: memo,
        usePillCount: usePillCount,
        initialPillCount: usePillCount ? initialPillCount : null,
        remainingPillCount: usePillCount ? initialPillCount : null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    notifyListeners();
  }

  // 약 정보 전체 수정
  void updateMedication({
    required String id,
    required String name,
    required String dosage,
    required List<DoseSlot> doseSlots,
    required String recurrenceSummary,
    required String durationSummary,
    required bool isPrescription,
    List<String>? repeatDays,
    String? memo,
    DateTime? startDate,
    DateTime? endDate,
    bool? usePillCount,
    int? initialPillCount,
  }) {
    final med = _medications.firstWhere((m) => m.id == id);
    med.name = name;
    med.dosage = dosage;
    med.doseSlots = doseSlots;
    med.recurrenceSummary = recurrenceSummary;
    med.startDate = startDate ?? med.startDate;
    med.createdDate = med.startDate;
    med.endDate = endDate;
    med.durationSummary = durationSummary;
    med.isPrescription = isPrescription;
    if (repeatDays != null) med.repeatDays = repeatDays;
    if (memo != null) med.memo = memo;
    if (usePillCount != null) {
      setMedicationPillCount(
        medId: id,
        enabled: usePillCount,
        initialCount: initialPillCount ?? med.initialPillCount ?? 0,
        resetRemaining: initialPillCount != med.initialPillCount,
      );
    }
    notifyListeners();
  }

  // 🌟 약 삭제 (소프트 삭제: 현재 탭 화면에서만 숨기고, 과거 달력 및 엑셀 데이터에는 영구 보존!)
  void deleteMedication(String id) {
    final idx = _medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _medications[idx].isArchived = true;
      notifyListeners();
    }
  }

  // 🌟 약 완전 영구 삭제 (설정 관리자용)
  void permanentlyDeleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    // 관련 과거 슬롯 기록도 함께 정돈
    _pastSlotRecords.forEach((_, slots) {
      slots.removeWhere((k, _) => k.startsWith('${id}_'));
    });
    notifyListeners();
  }

  /// 앱 복약 탭에 표시된 약 카드의 순서만 변경한다.
  /// 위젯은 별도로 복용 시간순으로 정렬해서 표시한다.
  void reorderMedications(List<String> visibleIds, int oldIndex, int newIndex) {
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0) return;
    final ids = List<String>.from(visibleIds);
    if (oldIndex >= ids.length || newIndex >= ids.length) return;
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final selected = visibleIds
        .map((id) => _medications.where((med) => med.id == id).firstOrNull)
        .whereType<MedicationItem>()
        .toList();
    final slots = <int>[];
    for (var i = 0; i < _medications.length; i++) {
      if (visibleIds.contains(_medications[i].id)) slots.add(i);
    }
    if (selected.length != slots.length) return;
    _medications.removeWhere((med) => visibleIds.contains(med.id));
    for (var i = 0; i < ids.length; i++) {
      final item = selected.firstWhere((med) => med.id == ids[i]);
      _medications.insert(slots[i].clamp(0, _medications.length), item);
    }
    notifyListeners();
  }

  // --- 🌱 습관 액션 메서드 ---

  bool advanceHabitProgress(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.ensureWeeklyPeriod(DateTime.now());
    final wasComplete = habit.score >= 1.0;
    final advanced = habit.advanceProgress();
    if (advanced) {
      if (habit.recurrenceSummary.contains('주') && !wasComplete && habit.score >= 1.0) {
        habit.weeklyCompletedCount++;
      }
      gentleAttempts++;
      notifyListeners();
    }
    return advanced;
  }

  void resetHabitProgress(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    final wasWeeklyCompletion =
        habit.recurrenceSummary.contains('주') &&
        (habit.recurrenceSummary.contains('회') ||
            habit.recurrenceSummary.contains('횟수')) &&
        habit.score >= 1.0;
    if (wasWeeklyCompletion && habit.weeklyCompletedCount > 0) {
      habit.weeklyCompletedCount--;
    }
    habit.resetProgress();
    suspendWidgetSync = false;
    notifyListeners();
    HagomNativeWidgetSync.updateNativeWidget(this);
  }

  void toggleHabitExpanded(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.isExpanded = !habit.isExpanded;
    notifyListeners();
  }

  void addHabit({
    required String title,
    required String subtitle,
    String recurrenceSummary = '매일',
    List<String> repeatDays = const [],
    List<String> scheduledTimes = const [],
    int targetPerDay = 1,
    int weeklyResetWeekday = 1,
    DateTime? startDate,
  }) {
    _habits.add(
      HabitItem(
        id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: subtitle,
        recurrenceSummary: recurrenceSummary,
        repeatDays: repeatDays,
        scheduledTimes: scheduledTimes,
        targetPerDay: targetPerDay,
        weeklyResetWeekday: weeklyResetWeekday,
        startDate: startDate,
      ),
    );
    notifyListeners();
  }

  void updateHabit({
    required String id,
    required String title,
    required String subtitle,
    required String recurrenceSummary,
    required List<String> repeatDays,
    required List<String> scheduledTimes,
    required int targetPerDay,
    int weeklyResetWeekday = 1,
    DateTime? startDate,
  }) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.title = title;
    habit.subtitle = subtitle;
    habit.recurrenceSummary = recurrenceSummary;
    habit.repeatDays = repeatDays;
    habit.scheduledTimes = scheduledTimes;
    habit.targetPerDay = targetPerDay;
    habit.weeklyResetWeekday = weeklyResetWeekday;
    if (startDate != null) habit.startDate = startDate;
    notifyListeners();
  }

  // 🌟 습관 삭제 (소프트 삭제: 현재 탭 화면에서만 숨기고, 과거 달력 및 엑셀 데이터에는 영구 보존!)
  void deleteHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].isArchived = true;
      notifyListeners();
    }
  }

  // 🌟 습관 완전 영구 삭제 (설정 관리자용)
  void permanentlyDeleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _pastHabitRecords.forEach((_, habits) {
      habits.remove(id);
    });
    notifyListeners();
  }

  /// 습관 순서 위아래 이동 (위젯 상단 대표 항목 우선순위와 직결)
  void moveHabit(String id, int delta) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    final nextIdx = (idx + delta).clamp(0, _habits.length - 1);
    if (nextIdx == idx) return;
    final item = _habits.removeAt(idx);
    _habits.insert(nextIdx, item);
    notifyListeners();
  }

  /// 화면에 표시된 습관 목록 안에서 길게 눌러 드래그한 순서를 반영한다.
  void reorderHabits(List<String> visibleIds, int oldIndex, int newIndex) {
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0) return;
    final ids = List<String>.from(visibleIds);
    if (oldIndex >= ids.length || newIndex >= ids.length) return;
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final selected = visibleIds
        .map((id) => _habits.where((habit) => habit.id == id).firstOrNull)
        .whereType<HabitItem>()
        .toList();
    final slots = <int>[];
    for (var i = 0; i < _habits.length; i++) {
      if (visibleIds.contains(_habits[i].id)) slots.add(i);
    }
    if (selected.length != slots.length) return;
    _habits.removeWhere((habit) => visibleIds.contains(habit.id));
    for (var i = 0; i < ids.length; i++) {
      final item = selected.firstWhere((habit) => habit.id == ids[i]);
      _habits.insert(slots[i].clamp(0, _habits.length), item);
    }
    notifyListeners();
  }
  // --- 🗓️ 할일 CRUD 액션 메서드 ---

  void addTask({
    required String title,
    required DateTime date,
    String? memo,
    String? time,
    List<String>? reminders,
    bool isRepeated = false,
    String repeatCycle = '매주',
    List<String>? repeatDays,
  }) {
    _tasks.insert(
      0,
      TaskItem(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        memo: memo ?? '',
        date: date,
        time: time,
        reminders: reminders ?? ['30분 전'],
        isRepeated: isRepeated,
        repeatCycle: repeatCycle,
        repeatDays: repeatDays ?? [],
      ),
    );
    notifyListeners();
  }

  void toggleTaskCompleted(String id) {
    if (id.startsWith('t_mock_')) {
      if (_completedMockTaskIds.contains(id)) {
        _completedMockTaskIds.remove(id);
      } else {
        _completedMockTaskIds.add(id);
      }
      notifyListeners();
      return;
    }
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  void updateTaskMemo(String id, String memo) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    _tasks[index].memo = memo;
    notifyListeners();
  }

  void toggleTaskExpanded(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isExpanded = !task.isExpanded;
    notifyListeners();
  }

  /// 해당 날짜 할일 목록 안에서 순서 위아래 이동
  void moveTask(String id, int delta, DateTime day) {
    final dayTasks = getTasksForDay(day);
    final localIdx = dayTasks.indexWhere((t) => t.id == id);
    if (localIdx == -1) return;
    final targetLocalIdx = (localIdx + delta).clamp(0, dayTasks.length - 1);
    if (targetLocalIdx == localIdx) return;

    final movingTask = dayTasks[localIdx];
    final anchorTask = dayTasks[targetLocalIdx];
    final fromGlobal = _tasks.indexWhere((t) => t.id == movingTask.id);
    final toGlobal = _tasks.indexWhere((t) => t.id == anchorTask.id);
    if (fromGlobal == -1 || toGlobal == -1) return;

    final item = _tasks.removeAt(fromGlobal);
    _tasks.insert(toGlobal, item);
    notifyListeners();
  }

  /// 선택한 날짜의 할일 목록 안에서 길게 눌러 드래그한 순서를 반영한다.
  void reorderTasksForDay(DateTime day, int oldIndex, int newIndex) {
    final dayTasks = getTasksForDay(day);
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0) return;
    if (oldIndex >= dayTasks.length || newIndex >= dayTasks.length) return;
    final ids = dayTasks.map((task) => task.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final slots = <int>[];
    for (var i = 0; i < _tasks.length; i++) {
      if (dayTasks.any((task) => task.id == _tasks[i].id)) slots.add(i);
    }
    final selected = dayTasks
        .map((task) => _tasks.firstWhere((item) => item.id == task.id))
        .toList();
    _tasks.removeWhere((task) => dayTasks.any((item) => item.id == task.id));
    for (var i = 0; i < ids.length; i++) {
      final item = selected.firstWhere((task) => task.id == ids[i]);
      _tasks.insert(slots[i].clamp(0, _tasks.length), item);
    }
    notifyListeners();
  }

  void updateTask({
    required String id,
    required String title,
    String? time,
    String? memo,
    List<String>? reminders,
    bool isRepeated = false,
    String repeatCycle = '매주',
    List<String>? repeatDays,
  }) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.title = title;
    if (memo != null) task.memo = memo;
    task.time = time;
    if (reminders != null) task.reminders = reminders;
    task.isRepeated = isRepeated;
    task.repeatCycle = repeatCycle;
    if (repeatDays != null) task.repeatDays = repeatDays;
    notifyListeners();
  }

  // 🌟 할일 삭제 (소프트 삭제: 현재 탭 화면에서만 숨기고, 과거 달력 및 엑셀 데이터에는 영구 보존!)
  void deleteTask(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx].isArchived = true;
      notifyListeners();
    } else if (id.startsWith('t_mock_')) {
      _hiddenMockTaskIds.add(id);
      notifyListeners();
    }
  }

  // 🌟 할일 완전 영구 삭제 (설정 관리자용)
  void permanentlyDeleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // 🌟 [설정 탭 전용] 특정 기간 동안의 기록 부분 삭제
  void deleteRecordsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool deleteMeds = true,
    bool deleteHabits = true,
    bool deleteTasks = true,
  }) {
    DateTime cur = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!cur.isAfter(end)) {
      final key = _dateKey(cur);
      if (deleteMeds) {
        _pastSlotRecords.remove(key);
        _pastSlotTimes.remove(key);
      }
      if (deleteHabits) {
        _pastHabitRecords.remove(key);
      }
      if (deleteTasks) {
        final targetDate = cur;
        _tasks.removeWhere((t) => t.isSameDay(targetDate));
      }
      cur = cur.add(const Duration(days: 1));
    }
    notifyListeners();
  }

  // 🌟 모든 데이터 초기화: 실사용 모드에서는 예시까지 완전히 백지화!
  Future<void> resetAllData() async {
    _medications.clear();
    _habits.clear();
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    _pastSlotTimes.clear();
    _retroactiveSlots.clear();
    customTimeSlots.clear(); // 커스텀 시간대도 깨끗하게 초기화!
    gentleAttempts = 0;
    returnedCount = 0;
    isInitialModeSelected = false;
    isDevSimulationMode = false;
    isTutorialDemoMode = false;
    final now = DateTime.now();
    _trackingStartDate = DateTime(now.year, now.month, now.day);

    if (isDevSimulationMode) {
      _initDefaultData();
    }

    if (_prefs != null) {
      await _prefs!.clear();
    }
    await _saveDataToDisk();
    notifyListeners();
  }

  // 🌟 [온보딩 튜토리얼 종료 후 클린 슬레이트 전환]: 모든 예시 약/습관/할일 완전 삭제 백지화
  Future<void> finishTutorialCleanSlate() async {
    _medications.clear();
    _habits.clear(); // 습관 예시도 완전 삭제하여 백지 상태로 제공
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    _pastSlotTimes.clear();
    _retroactiveSlots.clear();
    customTimeSlots.clear();
    isTutorialDemoMode = false;
    isDevSimulationMode = false;
    final now = DateTime.now();
    _trackingStartDate = DateTime(now.year, now.month, now.day);

    await _saveDataToDisk();
    notifyListeners();
  }

  // 🌟 [개발자/전체 모드 복원]
  // - 튜토리얼을 마친 후라도, 언제든 '개발자 모드'를 누르면 우리가 만든 모든 풍성한 예시 데이터가 100% 즉시 복구!
  Future<void> restoreDevFullSimulationData() async {
    _medications.clear();
    _habits.clear();
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    _initDefaultData();
    isTutorialDemoMode = false;
    isDevSimulationMode = true; // 개발자 모드 복원: 전체 예시 노출 모드

    // 개발자 모드 진입 시에만 현재 예시 데이터를 홈 위젯에 한 번 반영한다.
    // 이후 미리보기 화면의 단순 재빌드에서는 위젯 전체를 반복 갱신하지 않는다.
    await flushForWidget();
    notifyListeners();
  }

  // 🌟 [온보딩 튜토리얼용 체험 데이터 세팅]
  // - 튜토리얼 시작 시에는 버튼을 눌러볼 수 있도록 예시 약과 습관(3/4회)을 완벽히 세팅!
  Future<void> setupTutorialDemoData() async {
    _medications.clear();
    _habits.clear();
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();

    _initDefaultData();
    isTutorialDemoMode = true;
    isDevSimulationMode = true;

    notifyListeners();
  }

  // 🌟 [통합 건강 데이터 단일 엑셀(XLSX) 다중 시트 생성기]:
  // 하나의 엑셀 파일 안에 4대 카테고리가 각기 다른 탭(Sheet)으로 깔끔하게 분리되어 저장됩니다.
  List<int> generateExcelWorkbook({
    required DateTime startDate,
    required DateTime endDate,
    bool includePrescription = true,
    bool includeOtc = true,
    bool includeHabits = true,
    bool includeTasks = true,
  }) {
    final excel = Excel.createExcel();
    final sDate = DateTime(startDate.year, startDate.month, startDate.day);
    final eDate = DateTime(endDate.year, endDate.month, endDate.day);

    final List<DateTime> dateRange = [];
    DateTime cur = sDate;
    while (!cur.isAfter(eDate)) {
      dateRange.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    // 1. 💊 1. 처방약 관리 데이터 시트
    if (includePrescription) {
      final Sheet sheet = excel['1. 처방약 관리'];
      sheet.appendRow([TextCellValue('1. 처방약 관리 데이터')]);
      sheet.appendRow([
        TextCellValue('조회 기간: ${_dateKey(sDate)} ~ ${_dateKey(eDate)}'),
      ]);
      sheet.appendRow([
        TextCellValue('추출 일시: ${DateTime.now().toString().substring(0, 19)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('기록 일자'),
        TextCellValue('약물 ID'),
        TextCellValue('약품명'),
        TextCellValue('복용법'),
        TextCellValue('기타 메모'),
        TextCellValue('복용 주기'),
        TextCellValue('복용 기간'),
        TextCellValue('회차(시간대)'),
        TextCellValue('예정 시각'),
        TextCellValue('복용 여부'),
        TextCellValue('실제 복용 시각'),
        TextCellValue('기록 방식'),
      ]);

      final rxMeds = _medications.where((m) => m.isPrescription).toList();
      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final med in rxMeds) {
          for (int slotIdx = 0; slotIdx < med.doseSlots.length; slotIdx++) {
            final slot = med.doseSlots[slotIdx];
            final isDone = isSlotCompletedForDay(day, med.id, slotIdx);
            final takenTime =
                getSlotTakenTimeForDay(day, med.id, slotIdx) ??
                (isDone ? (slot.scheduledTime ?? '완료') : '-');
            final statusStr = isDone
                ? '복용 완료'
                : (slot.isSkipped ? '건너뜀' : '미복용/대기');
            final recordMethod = !isDone
                ? '-'
                : (isSlotRetroactive(day, med.id, slotIdx)
                      ? '달력 사후 수정'
                      : '당일 실시간 체크');

            sheet.appendRow([
              TextCellValue(dStr),
              TextCellValue(med.id),
              TextCellValue(med.name),
              TextCellValue(med.dosage),
              TextCellValue(med.memo ?? '-'),
              TextCellValue(med.recurrenceSummary),
              TextCellValue(med.durationSummary),
              TextCellValue(slot.label),
              TextCellValue(slot.scheduledTime ?? '-'),
              TextCellValue(statusStr),
              TextCellValue(takenTime),
              TextCellValue(recordMethod),
            ]);
          }
        }
      }
    }

    // 2. 🌿 2. 일반의약품 및 영양제 데이터 시트
    if (includeOtc) {
      final Sheet sheet = excel['2. 일반약 및 영양제'];
      sheet.appendRow([TextCellValue('2. 일반의약품 및 영양제 데이터')]);
      sheet.appendRow([
        TextCellValue('조회 기간: ${_dateKey(sDate)} ~ ${_dateKey(eDate)}'),
      ]);
      sheet.appendRow([
        TextCellValue('추출 일시: ${DateTime.now().toString().substring(0, 19)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('기록 일자'),
        TextCellValue('약물 ID'),
        TextCellValue('약품명'),
        TextCellValue('복용법'),
        TextCellValue('기타 메모'),
        TextCellValue('복용 주기'),
        TextCellValue('복용 기간'),
        TextCellValue('회차(시간대)'),
        TextCellValue('예정 시각'),
        TextCellValue('복용 여부'),
        TextCellValue('실제 복용 시각'),
        TextCellValue('기록 방식'),
      ]);

      final otcMeds = _medications.where((m) => !m.isPrescription).toList();
      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final med in otcMeds) {
          for (int slotIdx = 0; slotIdx < med.doseSlots.length; slotIdx++) {
            final slot = med.doseSlots[slotIdx];
            final isDone = isSlotCompletedForDay(day, med.id, slotIdx);
            final takenTime =
                getSlotTakenTimeForDay(day, med.id, slotIdx) ??
                (isDone ? (slot.scheduledTime ?? '완료') : '-');
            final statusStr = isDone
                ? '복용 완료'
                : (slot.isSkipped ? '건너뜀' : '미복용/대기');
            final recordMethod = !isDone
                ? '-'
                : (isSlotRetroactive(day, med.id, slotIdx)
                      ? '달력 사후 수정'
                      : '당일 실시간 체크');

            sheet.appendRow([
              TextCellValue(dStr),
              TextCellValue(med.id),
              TextCellValue(med.name),
              TextCellValue(med.dosage),
              TextCellValue(med.memo ?? '-'),
              TextCellValue(med.recurrenceSummary),
              TextCellValue(med.durationSummary),
              TextCellValue(slot.label),
              TextCellValue(slot.scheduledTime ?? '-'),
              TextCellValue(statusStr),
              TextCellValue(takenTime),
              TextCellValue(recordMethod),
            ]);
          }
        }
      }
    }

    // 3. 🌱 3. 작은 습관 관리 데이터 시트
    if (includeHabits) {
      final Sheet sheet = excel['3. 작은 습관'];
      sheet.appendRow([TextCellValue('3. 작은 습관 관리 데이터')]);
      sheet.appendRow([
        TextCellValue('조회 기간: ${_dateKey(sDate)} ~ ${_dateKey(eDate)}'),
      ]);
      sheet.appendRow([
        TextCellValue('추출 일시: ${DateTime.now().toString().substring(0, 19)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('기록 일자'),
        TextCellValue('습관 ID'),
        TextCellValue('습관 제목'),
        TextCellValue('상세 설명'),
        TextCellValue('실천 주기'),
        TextCellValue('1일 목표 횟수'),
        TextCellValue('해당일 실천 점수'),
        TextCellValue('달성률(%)'),
        TextCellValue('평가 상태'),
      ]);

      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final habit in _habits) {
          final score = getHabitScoreForDay(day, habit.id);
          final percent = (score * 100).toInt();
          final evaluation = score >= 1.0
              ? '목표 달성'
              : (score > 0 ? '일부 실천' : '실천 대기');
          sheet.appendRow([
            TextCellValue(dStr),
            TextCellValue(habit.id),
            TextCellValue(habit.title),
            TextCellValue(habit.subtitle),
            TextCellValue(habit.recurrenceSummary),
            TextCellValue('${habit.targetPerDay}회'),
            TextCellValue(score.toString()),
            TextCellValue('$percent%'),
            TextCellValue(evaluation),
          ]);
        }
      }
    }

    // 4. 🗓️ 4. 할일 및 일정 관리 데이터 시트
    if (includeTasks) {
      final Sheet sheet = excel['4. 할일 및 일정'];
      sheet.appendRow([TextCellValue('4. 할일 및 일정 관리 데이터')]);
      sheet.appendRow([
        TextCellValue('조회 기간: ${_dateKey(sDate)} ~ ${_dateKey(eDate)}'),
      ]);
      sheet.appendRow([
        TextCellValue('추출 일시: ${DateTime.now().toString().substring(0, 19)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('대상 일자'),
        TextCellValue('일정 ID'),
        TextCellValue('일정명'),
        TextCellValue('예정 시각'),
        TextCellValue('완료 여부'),
        TextCellValue('반복 설정'),
        TextCellValue('알림 설정'),
      ]);

      for (final day in dateRange) {
        final dayTasks = getTasksForDay(day);
        final dStr = _dateKey(day);
        for (final task in dayTasks) {
          final statusStr = task.isCompleted ? '완료' : '진행 대기';
          sheet.appendRow([
            TextCellValue(dStr),
            TextCellValue(task.id),
            TextCellValue(task.title),
            TextCellValue(task.time ?? '-'),
            TextCellValue(statusStr),
            TextCellValue(task.repeatSummary),
            TextCellValue(task.reminderSummary),
          ]);
        }
      }
    }

    // 기본 생성되는 빈 Sheet1 제거 (원하는 시트가 하나라도 생성된 경우)
    if (excel.sheets.keys.any((k) => k != 'Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.encode() ?? <int>[];
  }

  // 🌟 [통합 건강 데이터 다중 섹션 추출기 (CSV 호환)]:
  Map<String, String> generateHealthDataReportsBySection({
    required DateTime startDate,
    required DateTime endDate,
    bool includePrescription = true,
    bool includeOtc = true,
    bool includeHabits = true,
    bool includeTasks = true,
  }) {
    final Map<String, String> result = {};
    final sDate = DateTime(startDate.year, startDate.month, startDate.day);
    final eDate = DateTime(endDate.year, endDate.month, endDate.day);

    // 날짜 목록 생성
    final List<DateTime> dateRange = [];
    DateTime cur = sDate;
    while (!cur.isAfter(eDate)) {
      dateRange.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    // 1. 💊 1. 처방약 관리 데이터
    if (includePrescription) {
      final buf = StringBuffer();
      buf.write('\uFEFF');
      buf.writeln('1. 처방약 관리 데이터');
      buf.writeln('조회 기간,${_dateKey(sDate)} ~ ${_dateKey(eDate)}');
      buf.writeln('추출 일시,${DateTime.now().toString().substring(0, 19)}');
      buf.writeln('');
      buf.writeln(
        '기록 일자,약물 ID,약품명,복용법,기타 메모,복용 주기,복용 기간,회차(시간대),예정 시각,복용 여부,실제 복용 시각,기록 방식',
      );

      final rxMeds = _medications.where((m) => m.isPrescription).toList();
      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final med in rxMeds) {
          for (int slotIdx = 0; slotIdx < med.doseSlots.length; slotIdx++) {
            final slot = med.doseSlots[slotIdx];
            final isDone = isSlotCompletedForDay(day, med.id, slotIdx);
            final takenTime =
                getSlotTakenTimeForDay(day, med.id, slotIdx) ??
                (isDone ? (slot.scheduledTime ?? '완료') : '-');
            final statusStr = isDone
                ? '복용 완료'
                : (slot.isSkipped ? '건너뜀' : '미복용/대기');
            final recordMethod = !isDone
                ? '-'
                : (isSlotRetroactive(day, med.id, slotIdx)
                      ? '달력 사후 수정'
                      : '당일 실시간 체크');
            buf.writeln(
              '"$dStr","${med.id}","${med.name}","${med.dosage}","${med.memo ?? '-'}","${med.recurrenceSummary}","${med.durationSummary}","${slot.label}","${slot.scheduledTime ?? '-'}","$statusStr","$takenTime","$recordMethod"',
            );
          }
        }
      }
      result['1_처방약_관리_데이터'] = buf.toString();
    }

    // 2. 🌿 2. 일반의약품 및 영양제 데이터
    if (includeOtc) {
      final buf = StringBuffer();
      buf.write('\uFEFF');
      buf.writeln('2. 일반의약품 및 영양제 데이터');
      buf.writeln('조회 기간,${_dateKey(sDate)} ~ ${_dateKey(eDate)}');
      buf.writeln('추출 일시,${DateTime.now().toString().substring(0, 19)}');
      buf.writeln('');
      buf.writeln(
        '기록 일자,약물 ID,약품명,복용법,기타 메모,복용 주기,복용 기간,회차(시간대),예정 시각,복용 여부,실제 복용 시각,기록 방식',
      );

      final otcMeds = _medications.where((m) => !m.isPrescription).toList();
      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final med in otcMeds) {
          for (int slotIdx = 0; slotIdx < med.doseSlots.length; slotIdx++) {
            final slot = med.doseSlots[slotIdx];
            final isDone = isSlotCompletedForDay(day, med.id, slotIdx);
            final takenTime =
                getSlotTakenTimeForDay(day, med.id, slotIdx) ??
                (isDone ? (slot.scheduledTime ?? '완료') : '-');
            final statusStr = isDone
                ? '복용 완료'
                : (slot.isSkipped ? '건너뜀' : '미복용/대기');
            final recordMethod = !isDone
                ? '-'
                : (isSlotRetroactive(day, med.id, slotIdx)
                      ? '달력 사후 수정'
                      : '당일 실시간 체크');
            buf.writeln(
              '"$dStr","${med.id}","${med.name}","${med.dosage}","${med.memo ?? '-'}","${med.recurrenceSummary}","${med.durationSummary}","${slot.label}","${slot.scheduledTime ?? '-'}","$statusStr","$takenTime","$recordMethod"',
            );
          }
        }
      }
      result['2_일반의약품_영양제_데이터'] = buf.toString();
    }

    // 3. 🌱 3. 작은 습관 관리 데이터
    if (includeHabits) {
      final buf = StringBuffer();
      buf.write('\uFEFF');
      buf.writeln('3. 작은 습관 관리 데이터');
      buf.writeln('조회 기간,${_dateKey(sDate)} ~ ${_dateKey(eDate)}');
      buf.writeln('추출 일시,${DateTime.now().toString().substring(0, 19)}');
      buf.writeln('');
      buf.writeln(
        '기록 일자,습관 ID,습관 제목,상세 설명,실천 주기,1일 목표 횟수,해당일 실천 점수,달성률(%),평가 상태',
      );

      for (final day in dateRange) {
        final dStr = _dateKey(day);
        for (final habit in _habits) {
          final score = getHabitScoreForDay(day, habit.id);
          final percent = (score * 100).toInt();
          final evaluation = score >= 1.0
              ? '목표 달성'
              : (score > 0 ? '일부 실천' : '실천 대기');
          buf.writeln(
            '"$dStr","${habit.id}","${habit.title}","${habit.subtitle}","${habit.recurrenceSummary}","${habit.targetPerDay}회","$score","$percent%","$evaluation"',
          );
        }
      }
      result['3_작은_습관_관리_데이터'] = buf.toString();
    }

    // 4. 🗓️ 4. 할일 및 일정 관리 데이터
    if (includeTasks) {
      final buf = StringBuffer();
      buf.write('\uFEFF');
      buf.writeln('4. 할일 및 일정 관리 데이터');
      buf.writeln('조회 기간,${_dateKey(sDate)} ~ ${_dateKey(eDate)}');
      buf.writeln('추출 일시,${DateTime.now().toString().substring(0, 19)}');
      buf.writeln('');
      buf.writeln('대상 일자,일정 ID,일정명,예정 시각,완료 여부,반복 설정,알림 설정');

      for (final day in dateRange) {
        final dayTasks = getTasksForDay(day);
        final dStr = _dateKey(day);
        for (final task in dayTasks) {
          final statusStr = task.isCompleted ? '완료' : '진행 대기';
          buf.writeln(
            '"$dStr","${task.id}","${task.title}","${task.time ?? '-'}","$statusStr","${task.repeatSummary}","${task.reminderSummary}"',
          );
        }
      }
      result['4_할일_및_일정_데이터'] = buf.toString();
    }

    return result;
  }

  // 🌟 기존 레거시 함수 호환 (단일 문자열로 합침)
  String generateComprehensiveHealthDataReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includePrescription = true,
    bool includeOtc = true,
    bool includeHabits = true,
    bool includeTasks = true,
  }) {
    final sDate = startDate ?? trackingStartDate;
    final eDate = endDate ?? DateTime.now();
    final map = generateHealthDataReportsBySection(
      startDate: sDate,
      endDate: eDate,
      includePrescription: includePrescription,
      includeOtc: includeOtc,
      includeHabits: includeHabits,
      includeTasks: includeTasks,
    );
    return map.values.join('\n\n');
  }

  String generateMedicalCsvReport() {
    return generateComprehensiveHealthDataReport();
  }
}
