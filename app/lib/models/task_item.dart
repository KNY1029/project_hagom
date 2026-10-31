/// 🗓️ [할일 및 일정 아이템 모델]
/// 
/// PRD 5.3절 달력 & 할일 탭 규격:
/// - 할일이 있는 날짜 셀 우측 상단 모서리에 라벤더 닷(`• #7B61A8`) 표시
/// - 완료 체크박스 토글 지원
/// - 마감 시각 및 알림 옵션
class TaskItem {
  String id;
  String title;              // 할일 제목 (예: 약학 실습 보고서 작성, 병원 진료)
  DateTime date;             // 대상 날짜 (년-월-일)
  String? time;              // 예정 시간 (예: 오후 6:00)
  bool isCompleted;          // 완료 여부
  String reminder;           // 알림 설정 (없음, 정시, 30분 전, 1시간 전)
  bool isRepeated;           // 반복 여부
  String? repeatCycle;       // 반복 주기 (매일, 매주, 격주, 매월)

  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.isCompleted = false,
    this.reminder = '30분 전',
    this.isRepeated = false,
    this.repeatCycle,
  });

  // 날짜 비교 헬퍼 (시간 제외 연-월-일만 비교)
  bool isSameDay(DateTime other) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }
}
