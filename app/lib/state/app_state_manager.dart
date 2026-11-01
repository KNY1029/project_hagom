import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../models/task_item.dart';

/// 앱 전체의 복약 및 습관 데이터를 로컬 DB에 영구 보존하고 실시간 알림을 보내는 상태 관리자
class AppStateManager extends ChangeNotifier {
  // 싱글톤 패턴
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    _initDataAndStorage();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveDataToDisk(); // 상태 변경 시마다 로컬 DB에 자동 영구 저장!
  }

  // --- 💊 복약 데이터 ---
  final List<MedicationItem> _medications = [];
  List<MedicationItem> get medications => _medications;

  // 오늘 복약 통계 (전체 슬롯 중 완료된 슬롯 수 기준)
  int get totalDoseSlots => _medications.fold(0, (sum, m) => sum + m.totalSlotsCount);
  int get completedDoseSlots => _medications.fold(0, (sum, m) => sum + m.completedSlotsCount);

  // --- 🌱 습관 데이터 ---
  final List<HabitItem> _habits = [];
  List<HabitItem> get habits => _habits;

  // 습관 달성률 계산 (비처벌적: 조금 한 것도 0.5점으로 인정)
  double get habitTotalScore => _habits.fold(0.0, (sum, item) => sum + item.score);
  double get habitCompletionRate => _habits.isEmpty ? 0.0 : (habitTotalScore / _habits.length);

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

    if (totalDoseSlots == 0) return 1.0;

    int total = 0;
    int completed = 0;

    for (final med in _medications) {
      for (int i = 0; i < med.doseSlots.length; i++) {
        total++;
        if (isSlotCompletedForDay(day, med.id, i)) {
          completed++;
        }
      }
    }

    if (total == 0) return 1.0;
    return completed / total;
  }

  // 특정 날짜에 '처방 필수 약물' 중 하나라도 놓친 것이 있는지 여부 (보건약학 임상 안전 관리)
  bool hasMissedPrescriptionForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isAfter(today)) return false; // 미래 날짜는 제외

    for (final med in _medications) {
      if (med.isPrescription) {
        for (int i = 0; i < med.doseSlots.length; i++) {
          if (!isSlotCompletedForDay(day, med.id, i)) {
            return true; // 처방 약물을 하나라도 놓쳤음!
          }
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
    if (_habits.isEmpty) return 1.0;

    double sum = 0.0;
    for (final h in _habits) {
      sum += getHabitScoreForDay(day, h.id);
    }
    return sum / _habits.length;
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
  final Map<String, String> routineTimes = {
    '아침': '오전 8:00',
    '점심': '오후 12:30',
    '저녁': '오후 7:00',
    '취침 전': '오후 10:30',
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
    } catch (_) {}
  }

  // 앱 켤 때 로컬 DB에서 기존 저장 데이터 불러오기
  Future<void> _loadDataFromDisk() async {
    if (_prefs == null) return;
    try {
      final medsRaw = _prefs!.getString('hagom_medications');
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
        subtitle: '유연하게 · 1분이라도 충분해',
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
  }) {
    final med = _medications.firstWhere((m) => m.id == id);
    med.name = name;
    med.dosage = dosage;
    med.doseSlots = doseSlots;
    med.recurrenceSummary = recurrenceSummary;
    med.durationSummary = durationSummary;
    med.isPrescription = isPrescription;
    if (repeatDays != null) med.repeatDays = repeatDays;
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

  // 🌟 의사 진료 상담용 복약 CSV 문자열 생성 (TDM 특화)
  String generateMedicalCsvReport() {
    final buffer = StringBuffer();
    // 엑셀에서 한글이 깨지지 않도록 UTF-8 BOM 삽입
    buffer.write('\uFEFF');
    buffer.writeln('하곰이 헬스케어 - 의료진 진료 상담용 복약 기록');
    buffer.writeln('출력 일시,${DateTime.now().toString().substring(0, 16)}');
    buffer.writeln('');
    buffer.writeln('약품명,처방 여부,용법 및 용량,복용 주기,회차 라벨,예정 시각,복용 완료 여부,실제 복용 시각');

    for (final med in _medications) {
      for (final slot in med.doseSlots) {
        final prescriptionStr = med.isPrescription ? '의사 처방 필수약' : '일반/영양제';
        final statusStr = slot.isCompleted ? '복용 완료' : (slot.isSkipped ? '건너뜀' : '미복용/대기');
        buffer.writeln(
          '"${med.name}","$prescriptionStr","${med.dosage}","${med.recurrenceSummary}","${slot.label}","${slot.scheduledTime ?? '-'}","$statusStr","${slot.takenTime ?? '-'}"',
        );
      }
    }
    return buffer.toString();
  }
}