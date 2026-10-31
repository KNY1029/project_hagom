/// 하곰이 앱에서 사용하는 이미지 에셋 경로 모음
/// 
/// AGENTS.md 지침 준수:
/// - 한 장의 하곰이 이미지를 여러 화면에서 임시로 재사용하더라도,
///   용도별로 의미 있는 이름을 나누어 나중에 전용 이미지가 추가되었을 때
///   이 파일의 경로만 바꾸면 전 화면에 쉽게 교체될 수 있도록 구성합니다.
class AppAssets {
  // 기본 하곰이 원본 이미지
  static const String _defaultHagom = 'assets/images/hagomi.png';

  /// 1. 앱 시작 스플래시 화면 마스코트
  static const String splashMascot = _defaultHagom;

  /// 2. 상단 헤더 동반자 미니 아바타
  static const String headerCompanionAvatar = _defaultHagom;

  /// 3. 복약 탭 빈 상태(Empty State) 마스코트
  static const String medsEmptyState = _defaultHagom;

  /// 4. 습관 탭 빈 상태(Empty State) 마스코트
  static const String habitsEmptyState = _defaultHagom;

  /// 5. 달력 탭 빈 상태(Empty State) 마스코트
  static const String calendarEmptyState = _defaultHagom;

  /// 6. 동반자 인터랙션 룸 마스코트
  static const String companionRoomMascot = _defaultHagom;

  /// 7. 설정 화면 마스코트
  static const String settingsMascot = _defaultHagom;
}
