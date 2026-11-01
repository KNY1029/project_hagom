/// 습관 항목 데이터 모델
class HabitItem {
  final String id;
  String title;              // 습관 이름 (예: 물 한 컵 마시기, 영양제 챙기기)
  String subtitle;           // 가이드 멘트 (예: 언제든 · 1컵, 5~10분)
  String recurrenceSummary;  // 반복 주기 요약 (예: '매일', '매주 월,수,금', '주 3회')
  List<String> repeatDays;   // 지정 요일 목록 (['월', '화', ...] 등)
  List<String> scheduledTimes; // 복수 알림 예정 시각 목록 (['오전 8:00', '오후 2:00'] 등)
  int targetPerDay;          // 하루 목표 횟수 (기본 1회, 물 마시기 등은 4회)
  int currentCount;          // 오늘 실천한 횟수
  bool isExpanded;           // 카드 아코디언 옵션 펼침 여부

  HabitItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.recurrenceSummary = '매일',
    this.repeatDays = const [],
    this.scheduledTimes = const [],
    this.targetPerDay = 1,
    this.currentCount = 0,
    this.isExpanded = false,
  });

  // 점수 환산 (0.0 ~ 1.0)
  double get score {
    if (targetPerDay <= 1) {
      if (currentCount == 0) return 0.0;
      if (currentCount == 1) return 0.5; // 조금 실천
      return 1.0; // 완료
    } else {
      return (currentCount / targetPerDay).clamp(0.0, 1.0);
    }
  }

  // 상태 라벨 텍스트
  String get statusLabel {
    if (targetPerDay > 1) {
      if (currentCount >= targetPerDay) return '완료';
      if (currentCount > 0) return '$currentCount/${targetPerDay}회';
      return '대기';
    } else {
      if (currentCount >= 2) return '완료';
      if (currentCount == 1) return '조금 실천';
      return '대기';
    }
  }

  // 탭 시 진행 (대기 ➔ 조금 실천 ➔ 완료 도달 시 잠금!)
  // 완료된 상태에서 무심코 다시 눌렀을 때 허무하게 대기로 풀리지 않도록 보호
  bool advanceProgress() {
    if (targetPerDay > 1) {
      if (currentCount < targetPerDay) {
        currentCount++;
        return true; // 진행됨
      }
      return false; // 이미 완료됨
    } else {
      if (currentCount < 2) {
        currentCount++;
        return true; // 진행됨
      }
      return false; // 이미 완료됨
    }
  }

  // 상태 초기화 (되돌리기 / 리셋)
  void resetProgress() {
    currentCount = 0;
  }
}
