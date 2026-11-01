/// 개별 복용 회차 (예: 아침, 점심, 저녁 각각의 복용 상태 및 시간)
class DoseSlot {
  final String label;          // 회차 라벨 (예: '아침', '점심', '저녁', '1회차')
  String? scheduledTime;       // 예정 시각 (동적 갱신 가능)
  bool isCompleted;            // 복용 완료 여부
  bool isSkipped;              // 🌿 이번 회차 건너뜀 여부
  String? takenTime;           // 실제 복용한 시각 (예: '오전 8:05')

  DoseSlot({
    required this.label,
    this.scheduledTime,
    this.isCompleted = false,
    this.isSkipped = false,
    this.takenTime,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'scheduledTime': scheduledTime,
    'isCompleted': isCompleted,
    'isSkipped': isSkipped,
    'takenTime': takenTime,
  };

  factory DoseSlot.fromJson(Map<String, dynamic> json) => DoseSlot(
    label: json['label'] as String,
    scheduledTime: json['scheduledTime'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    isSkipped: json['isSkipped'] as bool? ?? false,
    takenTime: json['takenTime'] as String?,
  );
}

/// 복약 상태 정의:
enum MedStatus {
  pending,
  completed,
  skipped,
}

class MedicationItem {
  String id;
  String name;                 // 약 이름 (예: Focusin, 주 1회 비타민 D 고용량, 메토트렉세이트)
  String dosage;               // 용량 및 복용법 (예: 10mg · 식후 30분, 1정)
  String recurrenceSummary;    // 주기 요약 (예: 매일, 매주 일요일, 2일 간격)
  String durationSummary;      // 복용 기간 (예: 계속 복용, 7일간)
  bool isPrescription;         // 의사 처방 필수 약물 여부 (강조 표시)
  List<String> repeatDays;     // 특정 요일 복용 목록 (['일'] 등)
  
  List<DoseSlot> doseSlots;    // 아침, 점심, 저녁 등 회차별 상태 목록!
  String? skipReason;          // 건너뛴 사유
  bool isExpanded;             // 아코디언 메뉴 펼침 여부

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    this.recurrenceSummary = '매일',
    this.durationSummary = '계속 복용',
    this.isPrescription = false,
    List<String>? repeatDays,
    required this.doseSlots,
    this.skipReason,
    this.isExpanded = false,
  }) : repeatDays = repeatDays ?? [];

  /// 🌟 오늘(Today) 복용해야 하는 약인지 판별하는 스마트 게터
  bool isDueOn(DateTime date) {
    if (recurrenceSummary == '매일' || recurrenceSummary == '오늘만' || recurrenceSummary.contains('시간')) {
      return true;
    }
    if (recurrenceSummary == '필요 시') {
      return true; // 필요 시는 항상 복용 가능하게 둠
    }
    if (repeatDays.isNotEmpty) {
      final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];
      final dayName = weekDayLabels[date.weekday - 1];
      return repeatDays.contains(dayName);
    }
    // "매주 일요일" 등 요일 이름이 summary에 포함된 경우
    final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = weekDayLabels[date.weekday - 1];
    if (recurrenceSummary.contains(dayName)) {
      return true;
    }
    return false;
  }

  // 오늘 먹어야 하는 날인지 바로 확인
  bool get isDueToday => isDueOn(DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'recurrenceSummary': recurrenceSummary,
    'durationSummary': durationSummary,
    'isPrescription': isPrescription,
    'repeatDays': repeatDays,
    'doseSlots': doseSlots.map((s) => s.toJson()).toList(),
    'skipReason': skipReason,
  };

  factory MedicationItem.fromJson(Map<String, dynamic> json) => MedicationItem(
    id: json['id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    recurrenceSummary: json['recurrenceSummary'] as String? ?? '매일',
    durationSummary: json['durationSummary'] as String? ?? '계속 복용',
    isPrescription: json['isPrescription'] as bool? ?? false,
    repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    doseSlots: (json['doseSlots'] as List<dynamic>?)
            ?.map((e) => DoseSlot.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    skipReason: json['skipReason'] as String?,
  );

  // 오늘 먹어야 할 모든 회차가 완료되거나 건너뛰어 정리되었는지 확인
  bool get isAllCompleted =>
      doseSlots.isNotEmpty && doseSlots.every((s) => s.isCompleted || s.isSkipped);

  // 전체 슬롯 개수
  int get totalSlotsCount => doseSlots.length;

  // 현재 완료된 회차 개수
  int get completedSlotsCount => doseSlots.where((s) => s.isCompleted).length;

  // 아직 완료되지 않고 남아있는 '가장 가까운 다음 복용 슬롯'
  DoseSlot? get nextPendingSlot {
    try {
      return doseSlots.firstWhere((s) => !s.isCompleted && !s.isSkipped);
    } catch (_) {
      return null;
    }
  }
}
