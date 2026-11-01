/// 습관 항목 데이터 모델
class HabitItem {
  final String id;
  String title;              // 습관 이름 (예: 물 마시기, 가볍게 몸 움직이기)
  String subtitle;           // 가이드 멘트 (예: 언제든 · 1컵, 5~10분)
  String recurrenceSummary;  // 반복 주기 요약 (예: '매일', '매주 일요일', '주 1회', '주간 횟수')
  List<String> repeatDays;   // 지정 요일 목록 (['월', '화', ...] 등)
  List<String> scheduledTimes; // 복수 알림 예정 시각 목록 (['오전 8:00', '오후 2:00'] 등)
  int targetPerDay;          // 하루 목표 횟수 (기본 1회, 물 마시기 등은 4회)
  int currentCount;          // 오늘 실천한 횟수
  int weeklyCompletedCount;  // 🌟 이번 주에 이미 완료한 누적 횟수 (예: 주 1회 목표 중 1회 완료)
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
    this.weeklyCompletedCount = 0,
    this.isExpanded = false,
  });

  /// 🌟 오늘(Today) 실천해야 하는 습관인지 판별하는 스마트 로직
  bool isDueOn(DateTime date) {
    if (recurrenceSummary == '매일' || recurrenceSummary == '오늘만') {
      return true;
    }
    // 주 N회 (예: 주 1회)인 경우:
    if (recurrenceSummary.contains('주') && (recurrenceSummary.contains('회') || recurrenceSummary.contains('횟수'))) {
      final match = RegExp(r'주\s*(\d+)회').firstMatch(recurrenceSummary);
      final targetPerWeek = match != null ? int.parse(match.group(1)!) : 1;
      // 🌟 이미 이번 주 목표를 다 채웠다면 오늘은 실천 대상에서 제외!
      if (weeklyCompletedCount >= targetPerWeek) {
        return false;
      }
      return true;
    }
    // 요일 지정형 (예: 매주 일요일 등)
    if (repeatDays.isNotEmpty) {
      final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];
      final dayName = weekDayLabels[date.weekday - 1];
      return repeatDays.contains(dayName);
    }
    final weekDayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = weekDayLabels[date.weekday - 1];
    if (recurrenceSummary.contains(dayName)) {
      return true;
    }
    return true;
  }

  // 오늘 실천해야 하는지 바로 확인
  bool get isDueToday => isDueOn(DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'recurrenceSummary': recurrenceSummary,
    'repeatDays': repeatDays,
    'scheduledTimes': scheduledTimes,
    'targetPerDay': targetPerDay,
    'currentCount': currentCount,
    'weeklyCompletedCount': weeklyCompletedCount,
  };

  factory HabitItem.fromJson(Map<String, dynamic> json) => HabitItem(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    recurrenceSummary: json['recurrenceSummary'] as String? ?? '매일',
    repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    scheduledTimes: (json['scheduledTimes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    targetPerDay: json['targetPerDay'] as int? ?? 1,
    currentCount: json['currentCount'] as int? ?? 0,
    weeklyCompletedCount: json['weeklyCompletedCount'] as int? ?? 0,
  );

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
