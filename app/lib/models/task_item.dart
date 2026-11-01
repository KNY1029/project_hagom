/// 🗓️ [할일 및 일정 아이템 모델: 다중 알림 및 유연한 반복 지원]
class TaskItem {
  String id;
  String title;              // 할일 제목 (예: 약학 실습 보고서 작성, 병원 진료)
  DateTime date;             // 대상 날짜 (년-월-일)
  String? time;              // 예정 시간 (예: 오후 6:00)
  bool isCompleted;          // 완료 여부
  List<String> reminders;    // 복수 알림 설정 목록 (예: ['3시간 전', '1시간 전', '하루 전'])
  bool isRepeated;           // 반복 여부
  String repeatCycle;        // 반복 주기 ('매일', '매주 특정 요일', '매달 이 날')
  List<String> repeatDays;   // '매주 특정 요일'일 때 선택된 요일 목록 (['월', '수', '금'])
  bool isExpanded;           // 아코디언 옵션 펼침 여부

  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.isCompleted = false,
    List<String>? reminders,
    String? reminder,
    this.isRepeated = false,
    this.repeatCycle = '매주',
    List<String>? repeatDays,
    this.isExpanded = false,
  })  : reminders = reminders ?? (reminder != null ? [reminder] : ['30분 전']),
        repeatDays = repeatDays ?? [];

  // 단일 알림 호환용 헬퍼 getter
  String get reminderSummary {
    if (reminders.isEmpty) return '알림 없음';
    return reminders.join(', ');
  }

  // 반복 요약 헬퍼 getter
  String get repeatSummary {
    if (!isRepeated) return '반복 없음';
    if (repeatCycle == '매주 특정 요일') {
      return repeatDays.isEmpty ? '매주' : '매주 (${repeatDays.join(',')})';
    }
    return repeatCycle;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'time': time,
    'isCompleted': isCompleted,
    'reminders': reminders,
    'isRepeated': isRepeated,
    'repeatCycle': repeatCycle,
    'repeatDays': repeatDays,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    List<String> rems = [];
    if (json['reminders'] != null) {
      rems = (json['reminders'] as List<dynamic>).map((e) => e.toString()).toList();
    } else if (json['reminder'] != null) {
      rems = [json['reminder'] as String];
    } else {
      rems = ['30분 전'];
    }

    List<String> days = [];
    if (json['repeatDays'] != null) {
      days = (json['repeatDays'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      reminders: rems,
      isRepeated: json['isRepeated'] as bool? ?? false,
      repeatCycle: json['repeatCycle'] as String? ?? '매주',
      repeatDays: days,
    );
  }

  // 날짜 비교 헬퍼 (시간 제외 연-월-일만 비교)
  bool isSameDay(DateTime other) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }
}
