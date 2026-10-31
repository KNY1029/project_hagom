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
}

/// 복약 상태 정의:
/// - pending: 아직 복용할 회차가 남음
/// - completed: 오늘 먹어야 할 모든 회차를 전부 복용 완료
/// - skipped: 건너뜀
enum MedStatus {
  pending,
  completed,
  skipped,
}

class MedicationItem {
  String id;
  String name;                 // 약 이름 (예: Focusin, 항생제, 비타민 D)
  String dosage;               // 용량 및 복용법 (예: 10mg · 식후 30분, 1정)
  String recurrenceSummary;    // 주기 요약 (예: 매일, 오늘만, 2일 간격)
  String durationSummary;      // 복용 기간 (예: 계속 복용, 7일간)
  bool isPrescription;         // 의사 처방 필수 약물 여부 (강조 표시)
  
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
    required this.doseSlots,
    this.skipReason,
    this.isExpanded = false,
  });

  // 오늘 먹어야 할 모든 회차가 완료되거나 건너뛰어 정리되었는지 확인
  bool get isAllCompleted =>
      doseSlots.isNotEmpty && doseSlots.every((s) => s.isCompleted || s.isSkipped);

  // 전체 슬롯 개수
  int get totalSlotsCount => doseSlots.length;

  // 현재 완료된 회차 개수
  int get completedSlotsCount => doseSlots.where((s) => s.isCompleted).length;

  // 다음 복용 대기 회차 슬롯 (완료되지도 않고 건너뛰지도 않은 첫 슬롯)
  DoseSlot? get nextPendingSlot {
    for (final s in doseSlots) {
      if (!s.isCompleted && !s.isSkipped) return s;
    }
    return null;
  }
}
