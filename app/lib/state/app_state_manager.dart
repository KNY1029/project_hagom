import 'package:flutter/material.dart';
import '../models/medication_item.dart';
import '../models/habit_item.dart';
import '../models/task_item.dart';

/// 앱 전체의 복약 및 습관 데이터를 관리하고 UI에 실시간 알림을 보내는 상태 관리자
class AppStateManager extends ChangeNotifier {
  // 싱글톤 패턴
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    _initDefaultData();
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

    // 기본 시뮬레이션: 4의 배수일은 미복용, 3의 배수일은 아침만 복용, 나머지는 완료
    if (day.day % 4 == 0) return false;
    if (day.day % 3 == 0) return slotIdx == 0;
    return true;
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

    // 기본 시뮬레이션: 짝수일은 1.0 완료, 홀수일은 0.5 조금 실천
    if (day.day % 3 == 0) return 0.5;
    if (day.day % 2 == 0) return 1.0;
    return 0.0;
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

  void _initDefaultData() {
    _medications.addAll([
      MedicationItem(
        id: 'med_1',
        name: 'Focusin',
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
        name: '비타민 D & 오메가3',
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
      final addMinutes = totalMinutes > 0 ? totalMinutes : 480;

      final nextSlot = med.nextPendingSlot;
      if (nextSlot != null) {
        final nextTime = takenDateTime.add(Duration(minutes: addMinutes));
        final nHour = nextTime.hour;
        final nMin = nextTime.minute.toString().padLeft(2, '0');
        final nPeriod = nHour >= 12 ? '오후' : '오전';
        final nDisplayH = nHour > 12 ? nHour - 12 : (nHour == 0 ? 12 : nHour);
        nextSlot.scheduledTime = '$nPeriod $nDisplayH:$nMin';
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
  }) {
    final med = _medications.firstWhere((m) => m.id == id);
    med.name = name;
    med.dosage = dosage;
    med.doseSlots = doseSlots;
    med.recurrenceSummary = recurrenceSummary;
    med.durationSummary = durationSummary;
    med.isPrescription = isPrescription;
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
    String reminder = '30분 전',
    bool isRepeated = false,
    String? repeatCycle,
  }) {
    _tasks.insert(
      0,
      TaskItem(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        date: date,
        time: time,
        reminder: reminder,
        isRepeated: isRepeated,
        repeatCycle: repeatCycle,
      ),
    );
    notifyListeners();
  }

  void toggleTaskCompleted(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
