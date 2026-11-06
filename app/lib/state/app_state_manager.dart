import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../services/hagom_native_widget_sync.dart';
import '../models/task_item.dart';
import '../constants/app_colors.dart';

/// 앱 전체의 복약 및 습관 데이터를 로컬 DB에 영구 보존하고 실시간 알림을 보내는 상태 관리자
class AppStateManager extends ChangeNotifier {
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
    _initCompleter!.complete();
  }

  /// 백그라운드 위젯 콜백에서 변경된 내용을 디스크와 위젯에 즉시 확정 저장
  Future<void> flushForWidget() async {
    await _saveDataToDisk();
    await HagomNativeWidgetSync.updateNativeWidget(this);
  }

  /// 앱이 포그라운드로 돌아올 때 위젯에서 변경한 최신 상태를 디스크에서 다시 읽어옴
  Future<void> reloadFromDisk() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.reload();
    await _loadDataFromDisk();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveDataToDisk(); // 상태 변경 시마다 로컬 DB에 자동 영구 저장!
    HagomNativeWidgetSync.updateNativeWidget(this);
  }

  // --- 💊 복약 데이터 ---
  final List<MedicationItem> _medications = [];
  List<MedicationItem> get medications => _medications;

  // 🌟 오늘 복약 통계 (오늘 복용해야 하는 약들의 슬롯만 집계!)
  int get totalDoseSlots => _medications.where((m) => m.isDueToday).fold(0, (sum, m) => sum + m.totalSlotsCount);
  int get completedDoseSlots => _medications.where((m) => m.isDueToday).fold(0, (sum, m) => sum + m.completedSlotsCount);

  // --- 🌱 습관 데이터 ---
  final List<HabitItem> _habits = [];
  List<HabitItem> get habits => _habits;

  // 🌟 오늘 실천해야 하는 습관 통계 (오늘 실천 대상인 습관만 집계!)
  int get todayHabitsCount => _habits.where((h) => h.isDueToday).length;
  double get habitTotalScore => _habits.where((h) => h.isDueToday).fold(0.0, (sum, item) => sum + item.score);
  double get habitCompletionRate => todayHabitsCount == 0 ? 0.0 : (habitTotalScore / todayHabitsCount);

  // --- ⚙️ 5대 알림 통합 설정 시스템 ---
  bool medsNotificationEnabled = true;     // 일반 복약 알림 (처방약은 항상 켜짐!)
  bool habitNotificationEnabled = true;    // 습관 알림
  bool tasksNotificationEnabled = true;    // 일정/할일 알림
  bool mascotNotificationEnabled = true;   // 하곰이 응원/넛지 알림
  String notificationFrequency = '기본';    // '최소' (정시 1회), '기본' (정시+30분), '적극적' (15분 간격 3회)

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

  void setNotificationFrequency(String freq) {
    notificationFrequency = freq;
    notifyListeners();
  }
  // --- ☀️ 하루 시작 기준 시각 (기본 오전 8:00) & 일일 최초 접속 인사 애니메이션 ---
  int dailyResetHour = 8; // 기본 매일 8시 갱신 (0~23)
  int dailyResetMinute = 0; // 갱신 분 (0~59)
  String? _lastGreetingDayKey; // 'YYYY-MM-DD' 기준 마지막으로 일일 인사 본 날짜

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
    final h12 = dailyResetHour == 0 ? 12 : (dailyResetHour > 12 ? dailyResetHour - 12 : dailyResetHour);
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

  void setTargetTab(int index, {bool openRoom = false, DateTime? calendarDate}) {
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
  bool isDevSimulationMode = true; // 기본값은 개발자 예시 모드 (발표 및 시연용)
  // 🎨 테마 관리 (기본 제공 프리셋 + 사용자가 추가한 커스텀 테마)
  String currentThemeKey = AppColors.themeDefault;
  final List<ThemePreset> customThemes = [];

  /// 색상이 바뀔 때마다 증가 → 앱 전체 위젯 트리를 강제 재빌드하는 신호
  int themeRevision = 0;

  List<ThemePreset> get allThemes => [...AppColors.builtInThemes, ...customThemes];

  ThemePreset get currentTheme => _findTheme(currentThemeKey) ?? AppColors.defaultTheme;

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



  /// 사용자 지정 테마를 목록에 추가하고 생성된 키를 반환 (적용은 applyTheme 으로 별도 수행)
  String addCustomTheme({
    required String name,
    required Color primary,
    required Color background,
    required Color lightTint,
    required Color textPrimary,
  }) {
    final key = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    customThemes.add(ThemePreset(
      key: key,
      name: name,
      description: '사용자 지정 · ${AppColors.toHex(primary)} / ${AppColors.toHex(background)}',
      primary: primary,
      background: background,
      lightTint: lightTint,
      textPrimary: textPrimary,
      textSecondary: Color.lerp(textPrimary, background, 0.35)!,
      warmAccent: AppColors.defaultTheme.warmAccent,
      divider: Color.lerp(lightTint, textPrimary, 0.08)!,
      isCustom: true,
    ));
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
    // 개발자 모드에서는 1~7일 모든 임상 예시 데이터가 달력에 온전히 보여야 하므로 절대 가리지 않음!
    if (isDevSimulationMode) {
      return false;
    }
    // 개발자 모드 시뮬레이션 중일 때는 달력에 1~7일 예시가 보여야 하므로 제외
    if (_pastSlotRecords.isNotEmpty || _pastHabitRecords.isNotEmpty) {
      return false;
    }
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(trackingStartDate);
  }
  // --- 🐻 하곰이 통계 (누적 발걸음) ---
  // --- 🗓️ 할일 및 일정 데이터 ---
  final List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => _tasks;

  // 특정 날짜의 할일 목록 조회
  List<TaskItem> getTasksForDay(DateTime day) {
    return _tasks.where((t) => t.isSameDay(day)).toList();
  }

  // --- 📅 날짜별 복약/습관 과거 기록 및 소급 달성 관리 (소급 축하 연동) ---
  // key: 'YYYY-MM-DD'
  // value: { 'slots': Map<String, bool> }  (key: 'medId_slotIdx', value: isCompleted)
  final Map<String, Map<String, bool>> _pastSlotRecords = {};
  // value: { 'habitId': score } (0.0=미실천, 0.5=조금실천, 1.0=완료)
  final Map<String, Map<String, double>> _pastHabitRecords = {};
  final Map<String, Map<String, String>> _pastSlotTimes = {};

  // 특정 날짜의 슬롯이 '소급 수정(달력에서 나중에 수정한 것)'인지 여부 (key: 'YYYY-MM-DD_medId_slotIdx')
  final Set<String> _retroactiveSlots = {};

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
      final med = _medications.firstWhere((m) => m.id == medId, orElse: () => _medications.first);
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
    if (_pastSlotRecords.containsKey(key) && _pastSlotRecords[key]!.containsKey(slotKey)) {
      return _pastSlotRecords[key]![slotKey]!;
    }
    // 🌟 사용자 요청 정확한 날짜별 임상 케이스 맵핑:
    // 1일: 전부 다 한 날 (복약 100%, 습관 100%)
    // 2일: 습관만 안 한 날 (복약 100%, 습관 0%)
    // 3일: 일반약만 누락 (처방약 Focusin 100%, 일반약 0%, 습관 100%)
    // 4일: 처방약 누락 (처방약 Focusin 0%, 일반약 100%, 습관 100%)
    // 5일: 습관이랑 일반약 누락 (처방약 Focusin 100%, 일반약 0%, 습관 0%)
    // 6일: 처방약이랑 습관 누락 (처방약 Focusin 0%, 일반약 100%, 습관 0%)
    // 7일: 약(처방+일반)이랑 습관 전부 다 누락 (0%)
    final d = day.day;
    if (d == 1 || d == 2) {
      return true; // 복약 전부 완료
    }
    if (d == 3 || d == 5) {
      return medId.contains('1'); // 일반약 누락 -> med_1(처방약)만 복용
    }
    if (d == 4 || d == 6) {
      return !medId.contains('1'); // 처방약 누락 -> med_1(처방약) 미복용, med_2(일반약)는 복용
    }
    if (d == 7) {
      return false; // 복약 전부 미복용
    }
    // 8일 이후 패턴 반복 (테스트용)
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
      final med = _medications.firstWhere((m) => m.id == medId, orElse: () => _medications.first);
      if (slotIdx >= 0 && slotIdx < med.doseSlots.length) {
        return med.doseSlots[slotIdx].takenTime;
      }
      return null;
    }

    final key = _dateKey(day);
    final slotKey = '${medId}_$slotIdx';
    if (_pastSlotTimes.containsKey(key) && _pastSlotTimes[key]!.containsKey(slotKey)) {
      return _pastSlotTimes[key]![slotKey];
    }
    // 예시 데이터 1~7일 기본 복용 시간대 맵핑
    if (isSlotCompletedForDay(day, medId, slotIdx)) {
      return slotIdx == 0 ? '오전 8:05' : '오후 12:35';
    }
    return null;
  }

  void setPastSlotTime(DateTime day, String medId, int slotIdx, String timeStr) {
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

  // 날짜별 상태 반환: 1.0(완전달성-연초록), 0.1~0.99(부분달성-오렌지바), 0.0(미복용/비처벌적그레이바), null(미래)
  double? getMedRateForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return null; // 미래 날짜는 깨끗하게 비움

    // 등록된 약이 하나도 없거나 오늘 복용할 약이 없으면 0.0 처리!
    final dueMeds = _medications.where((m) => m.isDueOn(day)).toList();
    if (dueMeds.isEmpty) return 0.0;

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

    final duePrescriptions = _medications.where((m) => m.isPrescription && m.isDueOn(day));
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
      final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => _habits.first);
      return habit.score;
    }

    // 🌟 [미래 날짜 철칙]: 아직 오지 않은 날짜는 무조건 미실천(0.0)!
    if (target.isAfter(today)) {
      return 0.0;
    }

    final key = _dateKey(day);
    if (_pastHabitRecords.containsKey(key) && _pastHabitRecords[key]!.containsKey(habitId)) {
      return _pastHabitRecords[key]![habitId]!;
    }
    // 🌟 사용자 요청 정확한 날짜별 임상 케이스에 맞춘 습관 시뮬레이션:
    // 1일: 습관 100% (전부 다 함)
    // 2일: 습관 0% (습관만 안 함)
    // 3일: 습관 100% (일반약만 누락)
    // 4일: 습관 100% (처방약만 누락)
    // 5일: 습관 0% (습관 + 일반약 누락)
    // 6일: 습관 0% (습관 + 처방약 누락)
    // 7일: 습관 0% (전부 다 누락)
    final d = day.day;
    if (d == 1 || d == 3 || d == 4) {
      return 1.0; // 습관 완료
    }
    if (d == 2 || d == 5 || d == 6 || d == 7) {
      return 0.0; // 습관 미완료
    }
    // 8일 이후 패턴 반복
    return (d % 2 == 0) ? 0.0 : 1.0;
  }

  // 특정 날짜의 전체 습관 평균 달성률 (0.0 ~ 1.0)
  double? getHabitRateForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return null;
    final dueHabits = _habits.where((h) => h.isDueOn(day)).toList();
    if (dueHabits.isEmpty) return 1.0;

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
  int returnedCount = 7;     // 다시 돌아온 횟수
  int gentleAttempts = 5;    // 부드럽게 시도한 횟수

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
    _initDefaultData();
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
      await _prefs!.setString('hagom_noti_freq', notificationFrequency);
      await _prefs!.setInt('hagom_daily_reset_hour', dailyResetHour);
      await _prefs!.setInt('hagom_daily_reset_minute', dailyResetMinute);
      if (_lastGreetingDayKey != null) {
        await _prefs!.setString('hagom_last_greeting_day', _lastGreetingDayKey!);
      }
      await _prefs!.setBool('hagom_initial_mode_selected', isInitialModeSelected);
      if (_trackingStartDate != null) {
        await _prefs!.setString('hagom_tracking_start_date', _dateKey(_trackingStartDate!));
      }
      await _prefs!.setStringList('hagom_custom_time_slots', customTimeSlots);
      await _prefs!.setString('hagom_routine_times', jsonEncode(routineTimes));
      await _prefs!.setString('hagom_theme_key', currentThemeKey);
      await _prefs!.setString('hagom_custom_themes', jsonEncode(customThemes.map((t) => t.toJson()).toList()));
      await _prefs!.setInt('hagom_widget_month_offset', widgetMonthOffset);
      if (widgetSelectedDate != null) {
        await _prefs!.setString('hagom_widget_selected_date', _dateKey(widgetSelectedDate!));
      } else {
        await _prefs!.remove('hagom_widget_selected_date');
      }
    } catch (_) {}
  }

  // 앱 켤 때 로컬 DB에서 기존 저장 데이터 불러오기
  Future<void> _loadDataFromDisk() async {
    if (_prefs == null) return;
    try {
      final medsRaw = _prefs!.getString('hagom_medications');
      final customThemesRaw = _prefs!.getString('hagom_custom_themes');
      customThemes.clear();
      if (customThemesRaw != null) {
        final List<dynamic> decodedThemes = jsonDecode(customThemesRaw);
        customThemes.addAll(decodedThemes.map((e) => ThemePreset.fromJson(e as Map<String, dynamic>)));
      }
      currentThemeKey = _prefs!.getString('hagom_theme_key') ?? AppColors.themeDefault;
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
        _medications.addAll(decoded.map((e) => MedicationItem.fromJson(e as Map<String, dynamic>)));
        // 만약 주 1회 약물 예시(med_3)가 아직 없다면 추가!
        if (!_medications.any((m) => m.id == 'med_3')) {
          _medications.add(
            MedicationItem(
              id: 'med_3',
              name: '주 1회 복용약 (예시)',
              dosage: '1정 · 매주 일요일 아침',
              recurrenceSummary: '매주 일요일',
              repeatDays: ['일'],
              durationSummary: '계속 복용',
              isPrescription: false,
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
        }
      }
      final startRaw = _prefs!.getString('hagom_tracking_start_date');
      if (startRaw != null) {
        _trackingStartDate = DateTime.tryParse(startRaw);
      } else {
        // 최초 로드 시 오늘 날짜를 기록 시작일로 고정
        final now = DateTime.now();
        _trackingStartDate = DateTime(now.year, now.month, now.day);
        await _prefs!.setString('hagom_tracking_start_date', _dateKey(_trackingStartDate!));
      }
      final habitsRaw = _prefs!.getString('hagom_habits');
      if (habitsRaw != null) {
        final List<dynamic> decoded = jsonDecode(habitsRaw);
        _habits.clear();
        _habits.addAll(decoded.map((e) => HabitItem.fromJson(e as Map<String, dynamic>)));
        if (!_habits.any((h) => h.id == 'habit_5')) {
          _habits.add(
            HabitItem(
              id: 'habit_5',
              title: '침구 정리 및 환기하기 (예시)',
              subtitle: '주 1회 · 이미 이번 주 완료됨',
              recurrenceSummary: '주 1회',
              targetPerDay: 1,
              currentCount: 0,
              weeklyCompletedCount: 1, // 🌟 이번 주에 이미 1회 완료하여 오늘은 쉴 수 있는 상태!
            ),
          );
        }
      }
      final tasksRaw = _prefs!.getString('hagom_tasks');
      if (tasksRaw != null) {
        final List<dynamic> decoded = jsonDecode(tasksRaw);
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)));
      }
      gentleAttempts = _prefs!.getInt('hagom_gentle_attempts') ?? gentleAttempts;
      returnedCount = _prefs!.getInt('hagom_returned_count') ?? returnedCount;
      medsNotificationEnabled = _prefs!.getBool('hagom_meds_noti') ?? true;
      habitNotificationEnabled = _prefs!.getBool('hagom_habit_noti') ?? true;
      tasksNotificationEnabled = _prefs!.getBool('hagom_tasks_noti') ?? true;
      mascotNotificationEnabled = _prefs!.getBool('hagom_mascot_noti') ?? true;
      notificationFrequency = _prefs!.getString('hagom_noti_freq') ?? '기본';
      dailyResetHour = _prefs!.getInt('hagom_daily_reset_hour') ?? 8;
      dailyResetMinute = _prefs!.getInt('hagom_daily_reset_minute') ?? 0;
      _lastGreetingDayKey = _prefs!.getString('hagom_last_greeting_day');
      isInitialModeSelected = _prefs!.getBool('hagom_initial_mode_selected') ?? false;
      final loadedCustomSlots = _prefs!.getStringList('hagom_custom_time_slots');
      if (loadedCustomSlots != null) {
        customTimeSlots.clear();
        customTimeSlots.addAll(loadedCustomSlots);
      }
      // 이미 약에 저장된 비표준 시간대 라벨도 커스텀 칩 목록에 자동 복원 (레이스 유실 방어)
      const standardLabels = {
        '아침', '아침 식전', '아침 식후',
        '점심', '점심 식전', '점심 식후',
        '저녁', '저녁 식전', '저녁 식후',
        '취침 전', '식간',
      };
      for (final med in _medications) {
        for (final slot in med.doseSlots) {
          final l = slot.label.trim();
          if (l.isNotEmpty && !standardLabels.contains(l) && !customTimeSlots.contains(l)) {
            customTimeSlots.add(l);
          }
        }
      }
      final loadedRoutineTimesRaw = _prefs!.getString('hagom_routine_times');
      if (loadedRoutineTimesRaw != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(loadedRoutineTimesRaw);
          routineTimes.clear();
          decoded.forEach((key, value) {
            routineTimes[key] = value.toString();
          });
        } catch (_) {}
      }
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
        doseSlots: [
          DoseSlot(
            label: '아침',
            scheduledTime: '오전 8:00',
            isCompleted: true,
            takenTime: '오전 8:05',
          ),
          DoseSlot(
            label: '점심',
            scheduledTime: '오후 12:30',
            isCompleted: false,
          ),
        ],
      ),
      MedicationItem(
        id: 'med_2',
        name: '일반 영양제 (예시 B)',
        dosage: '1캡슐 · 저녁 식후',
        recurrenceSummary: '매일',
        durationSummary: '계속 복용',
        isPrescription: false,
        doseSlots: [
          DoseSlot(
            label: '저녁',
            scheduledTime: '오후 7:00',
            isCompleted: false,
          ),
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
        doseSlots: [
          DoseSlot(
            label: '아침',
            scheduledTime: '오전 9:00',
            isCompleted: false,
          ),
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
    final now = DateTime.now();
    _tasks.addAll([
      TaskItem(
        id: 'task_1',
        title: '약학 실습 보고서 작성',
        date: DateTime(now.year, now.month, now.day),
        time: '오후 6:00',
        reminder: '30분 전',
        isCompleted: false,
      ),
      TaskItem(
        id: 'task_2',
        title: '병원 정기 상담 및 처방전 받기',
        date: DateTime(now.year, now.month, now.day + 2),
        time: '오후 2:30',
        reminder: '1시간 전',
        isCompleted: false,
      ),
      TaskItem(
        id: 'task_3',
        title: '지난주 복약 상담 일지 정리',
        date: DateTime(now.year, now.month, now.day - 3),
        time: '오전 11:00',
        reminder: '정시',
        isCompleted: true,
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
    final targetSlot = med.nextPendingSlot;
    if (targetSlot != null) {
      targetSlot.isCompleted = true;
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? '오후' : '오전';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      targetSlot.takenTime = customTakenTime ?? '$period $displayHour:$minute';

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

        _recalculateHourlyNextSlot(med, now);

        gentleAttempts++;
        notifyListeners();
      }
    }
  }

  // N시간 간격 약물의 다음 회차 예정 시각 재계산 로직
  void _recalculateHourlyNextSlot(MedicationItem med, DateTime takenDateTime) {
    if (med.recurrenceSummary.contains('시간') || med.recurrenceSummary.contains('분') || med.doseSlots.any((s) => s.label.contains('회차'))) {
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
        med.doseSlots.add(DoseSlot(label: '${nextIndex}회차', scheduledTime: nextTimeStr));
      }
    }
  }

  // 특정 회차 실제 복용 시간 수정
  void updateSlotTakenTime(String medId, int slotIndex, String newTakenTime) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      med.doseSlots[slotIndex].takenTime = newTakenTime;
      med.doseSlots[slotIndex].isCompleted = true;
      notifyListeners();
    }
  }
  // 특정 회차만 핀셋 복약 취소 (뒤쪽 회차 건드리지 않고 해당 슬롯만 쏙 취소)
  void cancelSpecificSlot(String medId, int slotIndex) {
    final med = _medications.firstWhere((m) => m.id == medId);
    if (slotIndex >= 0 && slotIndex < med.doseSlots.length) {
      med.doseSlots[slotIndex].isCompleted = false;
      med.doseSlots[slotIndex].takenTime = null;
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
        break;
      }
    }
    notifyListeners();
  }

  // cancelLastCompletedSlot 별칭
  void cancelLastCompletedSlot(String id) => revertMedication(id);
  // 🌿 특정 회차만 건너뛰기 처리 (다음 대기 회차 슬롯 건너뜀)
  void skipNextSlot(String id) {
    final med = _medications.firstWhere((m) => m.id == id);
    final target = med.nextPendingSlot;
    if (target != null) {
      target.isSkipped = true;
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
  }) {
    final med = _medications.firstWhere((m) => m.id == id);
    med.name = name;
    med.dosage = dosage;
    med.doseSlots = doseSlots;
    med.recurrenceSummary = recurrenceSummary;
    med.durationSummary = durationSummary;
    med.isPrescription = isPrescription;
    if (repeatDays != null) med.repeatDays = repeatDays;
    if (memo != null) med.memo = memo;
    notifyListeners();
  }

  // 약 삭제
  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // --- 🌱 습관 액션 메서드 ---

  bool advanceHabitProgress(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    final advanced = habit.advanceProgress();
    if (advanced) {
      gentleAttempts++;
      notifyListeners();
    }
    return advanced;
  }

  void resetHabitProgress(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.resetProgress();
    notifyListeners();
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
  }) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.title = title;
    habit.subtitle = subtitle;
    habit.recurrenceSummary = recurrenceSummary;
    habit.repeatDays = repeatDays;
    habit.scheduledTimes = scheduledTimes;
    habit.targetPerDay = targetPerDay;
    notifyListeners();
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
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
  // --- 🗓️ 할일 CRUD 액션 메서드 ---

  void addTask({
    required String title,
    required DateTime date,
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
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = !task.isCompleted;
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

  void updateTask({
    required String id,
    required String title,
    String? time,
    List<String>? reminders,
    bool isRepeated = false,
    String repeatCycle = '매주',
    List<String>? repeatDays,
  }) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.title = title;
    task.time = time;
    if (reminders != null) task.reminders = reminders;
    task.isRepeated = isRepeated;
    task.repeatCycle = repeatCycle;
    if (repeatDays != null) task.repeatDays = repeatDays;
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // 🌟 모든 데이터 초기화 (스토어 심사 및 테스트용)
  Future<void> resetAllData() async {
    _medications.clear();
    _habits.clear();
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    gentleAttempts = 0;
    returnedCount = 0;
    _initDefaultData();
    if (_prefs != null) {
      await _prefs!.clear();
    }
    notifyListeners();
  }

  // 🌟 [온보딩 튜토리얼 종료 후 클린 슬레이트 전환]
  // - 복약 및 할일: 예시 데이터 완전 삭제 (사용자가 직접 등록하도록 백지화!)
  // - 습관 3종(계획 점검, 물 마시기, 스트레칭): 모두 '대기(0회)' 상태로 초기화되어 실사용 대기!
  Future<void> finishTutorialCleanSlate() async {
    _medications.clear();
    _tasks.clear();
    _pastSlotRecords.clear();
    _pastHabitRecords.clear();
    isDevSimulationMode = false; // 클린 슬레이트: 실사용 모드 (기록 시작일 이전 숨김 적용)

    _habits.clear();
    _habits.addAll([
      HabitItem(
        id: 'habit_plan',
        title: '오늘 계획 가볍게 보기',
        subtitle: '유연하게 · 1분이라도 충분해요',
        targetPerDay: 1,
        currentCount: 0, // 대기
      ),
      HabitItem(
        id: 'habit_water',
        title: '물 마시기',
        subtitle: '하루 4잔 시원하게',
        targetPerDay: 4,
        currentCount: 0, // 대기
      ),
      HabitItem(
        id: 'habit_stretch',
        title: '스트레칭 및 가볍게 걷기',
        subtitle: '몸 깨우기 · 5~10분',
        targetPerDay: 1,
        currentCount: 0, // 대기
      ),
    ]);
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
    isDevSimulationMode = true; // 개발자 모드 복원: 전체 예시 노출 모드

    await _saveDataToDisk();
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

    notifyListeners();
  }
  // 🌟 [보건약학 임상 연구 & 교수님 자문용] 4대 영역 종합 건강 데이터 CSV 생성기
  String generateComprehensiveHealthDataReport({
    bool includePrescription = true,
    bool includeOtc = true,
    bool includeHabits = true,
    bool includeTasks = true,
  }) {
    final buffer = StringBuffer();
    // 엑셀에서 한글 깨짐 방지 UTF-8 BOM
    buffer.write('\uFEFF');
    buffer.writeln('하곰이(Hagom) 비처벌적 환자 케어 솔루션 - 통합 건강 기록 데이터');
    buffer.writeln('추출 일시,${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('기록 시작일,${_trackingStartDate != null ? _dateKey(_trackingStartDate!) : "기록 전"}');
    buffer.writeln('다정한 시도 횟수,$gentleAttempts,돌아온 횟수,$returnedCount');
    buffer.writeln('');

    final nowStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    // 1. 💊 처방약 데이터 (별도 분리)
    if (includePrescription) {
      buffer.writeln('--- [1. 처방약 관리 데이터] ---');
      buffer.writeln('기록 일자,약물 ID,약품명,복용법,기타 메모,복용 주기,복용 기간,회차(시간대),예정 시각,복용 여부,실제 복용 시각,기록 방식(실시간/사후수정)');
      final rxMeds = _medications.where((m) => m.isPrescription);
      for (final med in rxMeds) {
        for (final slot in med.doseSlots) {
          final statusStr = slot.isCompleted ? '복용 완료' : (slot.isSkipped ? '건너뜀' : '미복용/대기');
          final recordMethod = !slot.isCompleted
              ? '-'
              : (isSlotRetroactive(DateTime.now(), med.id, med.doseSlots.indexOf(slot)) ? '달력 사후 수정' : '당일 실시간 체크');
          buffer.writeln(
            '"$nowStr","${med.id}","${med.name}","${med.dosage}","${med.memo ?? '-'}","${med.recurrenceSummary}","${med.durationSummary}","${slot.label}","${slot.scheduledTime ?? '-'}","$statusStr","${slot.takenTime ?? '-'}","$recordMethod"',
          );
        }
      }
      buffer.writeln('');
    }

    // 2. 🌿 일반의약품 및 영양제 데이터 (별도 분리)
    if (includeOtc) {
      buffer.writeln('--- [2. 일반의약품 및 영양제 데이터] ---');
      buffer.writeln('기록 일자,약물 ID,약품명,복용법,기타 메모,복용 주기,복용 기간,회차(시간대),예정 시각,복용 여부,실제 복용 시각,기록 방식(실시간/사후수정)');
      final otcMeds = _medications.where((m) => !m.isPrescription);
      for (final med in otcMeds) {
        for (final slot in med.doseSlots) {
          final statusStr = slot.isCompleted ? '복용 완료' : (slot.isSkipped ? '건너뜀' : '미복용/대기');
          final recordMethod = !slot.isCompleted
              ? '-'
              : (isSlotRetroactive(DateTime.now(), med.id, med.doseSlots.indexOf(slot)) ? '달력 사후 수정' : '당일 실시간 체크');
          buffer.writeln(
            '"$nowStr","${med.id}","${med.name}","${med.dosage}","${med.memo ?? '-'}","${med.recurrenceSummary}","${med.durationSummary}","${slot.label}","${slot.scheduledTime ?? '-'}","$statusStr","${slot.takenTime ?? '-'}","$recordMethod"',
          );
        }
      }
      buffer.writeln('');
    }

    // 3. 🌱 작은 습관 데이터
    if (includeHabits) {
      buffer.writeln('--- [3. 작은 습관 관리 데이터] ---');
      buffer.writeln('기록 일자,습관 ID,습관 제목,상세 설명,실천 주기,1일 목표 횟수,오늘 실천 횟수,주간 완료 횟수,달성률(%),비처벌적 평가 상태');

      for (final habit in _habits) {
        final percent = (habit.score * 100).toInt();
        final evaluation = habit.score >= 1.0 ? '목표 달성' : (habit.score > 0 ? '다정한 일부 실천' : '실천 대기');
        buffer.writeln(
          '"$nowStr","${habit.id}","${habit.title}","${habit.subtitle}","${habit.recurrenceSummary}","${habit.targetPerDay}회","${habit.currentCount}회","${habit.weeklyCompletedCount}회","$percent%","$evaluation"',
        );
      }
      buffer.writeln('');
    }

    // 4. 🗓️ 할일 및 진료 일정 데이터
    if (includeTasks) {
      buffer.writeln('--- [4. 할일 및 일정 관리 데이터] ---');
      buffer.writeln('대상 일자,일정 ID,일정명,예정 시각,완료 여부,반복 설정,알림 설정');

      for (final task in _tasks) {
        final dateStr = '${task.date.year}-${task.date.month.toString().padLeft(2, '0')}-${task.date.day.toString().padLeft(2, '0')}';
        final statusStr = task.isCompleted ? '완료' : '진행 대기';
        buffer.writeln(
          '"$dateStr","${task.id}","${task.title}","${task.time ?? '-'}","$statusStr","${task.repeatSummary}","${task.reminderSummary}"',
        );
      }
      buffer.writeln('');
    }
    return buffer.toString();
  }

  // 🌟 기존 레거시 함수 호환
  String generateMedicalCsvReport() {
    return generateComprehensiveHealthDataReport();
  }
}