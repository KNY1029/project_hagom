import 'dart:math';

/// 🐻 하곰이의 비처벌적 따뜻한 상호작용 대사 보관소
/// 
/// 원칙:
/// - 연속 기록(Streak) 실패 언급 금지
/// - "정보야", "물 마셔라" 등 무언가를 요구하거나 지시하는 압박성 문구 배제
/// - 오직 무조건적인 긍정, 존재 자체에 대한 위로, 천천히 가도 된다는 응원만 수록!
class HagomDialogue {
  static final Random _rng = Random();

  /// 1. 💊 복약 완료 시 하단에 뜨는 축하 토스트 멘트 (랜덤 풀)
  static final List<Map<String, String>> medCompletionToasts = [
    {
      'title': '복용 완료! 대단해요',
      'message': '제시간에 몸을 챙긴 스스로를 꼭 칭찬해 주세요.',
    },
    {
      'title': '오늘도 소중한 한 걸음',
      'message': '스스로를 돌보는 마음이 정말 멋져요.',
    },
    {
      'title': '약 챙기기 성공',
      'message': '차근차근 너만의 속도로 잘 해내고 있어요.',
    },
    {
      'title': '참 잘했어요',
      'message': '충분히 쉬면서 편안한 시간 보내세요.',
    },
    {
      'title': '오늘의 나를 지켰어요',
      'message': '작은 실천이 모여 큰 힘이 될 거예요.',
    },
    {
      'title': '기특해요, 정말로',
      'message': '하곰이가 언제나 곁에서 든든하게 응원해요.',
    },
    {
      'title': '멋진 하루의 마무리',
      'message': '오늘도 나를 위해 애쓴 스스로가 참 기특해요.',
    },
  ];

  /// 2. 상단 헤더 하곰이 미니 아바타 탭 시 말풍선 멘트 (순수 텍스트, 압박 제로!)
  static final List<String> headerBubbleQuotes = [
    '한 가지만 해도 충분해',
    '오늘도 들러줘서 고마워',
    '천천히 너만의 속도로 가자',
    '네가 있는 그대로 참 좋아',
    '마음이 지칠 땐 쉬어가도 괜찮아',
    '오늘 스스로를 한번 안아줘',
    '하곰이는 언제나 네 편이야',
    '아무것도 안 해도 넌 소중해',
    '오늘도 여기까지 온 네가 참 대견해',
    '완벽하지 않아도 다 괜찮아',
    '너의 오늘 하루를 진심으로 응원해',
    '조금 늦어도 괜찮아, 네 속도가 맞아',
    '스스로에게 다정한 하루가 되길 바라',
    '지친 하루 끝엔 푹 쉬는 게 최고야',
    '너는 생각보다 훨씬 더 잘해내고 있어',
    '오늘도 나를 돌보러 와준 네가 멋져',
  ];

  /// 3. 🏠 하곰이의 방 안에서 하곰이 터치 시 대사 (순수 텍스트, 진정성 있는 온기)
  static final List<String> roomQuotes = [
    '안녕! 오늘도 찾아와줘서 정말 고마워.\n약이나 습관을 다 못해도 괜찮아. 앱을 켠 것만으로도 큰 첫걸음이야.',
    '지금은 한 가지만 해도 충분해. 작은 시작이 모여 큰 변화가 돼.',
    '마음이 지칠 땐 잠시 쉬어가도 괜찮아. 하곰이가 항상 여기서 응원하고 있을게.',
    '오늘 너의 하루는 어떤 색이었어? 무사히 하루를 보낸 스스로를 꼭 칭찬해 줘.',
    '스스로에게 너무 엄격하지 않아도 돼. 지금 이대로도 이미 충분히 잘하고 있어.',
    '숨 한번 깊게 들이쉬고 내쉬어보자. 오늘도 무사히 여기까지 온 네가 자랑스러워.',
    '남들과 비교하지 말고, 너만의 박자로 한 걸음씩 걸어가면 돼.',
    '오늘 하루 동안 수고한 내 마음을 토닥토닥 안아주자. 넌 항상 소중해.',
    '잘 해내야 한다는 부담은 내려놓아도 돼. 그냥 오늘을 살아낸 것만으로도 100점이야.',
  ];
  static int _toastSeqIndex = 0;
  static int _headerSeqIndex = 0;
  static int _roomSeqIndex = 0;

  /// 순차적 복약 완료 토스트 반환 (테스트용)
  static Map<String, String> getRandomMedToast(String medName) {
    final item = medCompletionToasts[_toastSeqIndex % medCompletionToasts.length];
    _toastSeqIndex++;
    return {
      'title': item['title']!,
      'message': '$medName ${item['message']!}',
    };
  }

  /// 순차적 헤더 말풍선 반환 (테스트용)
  static String getRandomHeaderQuote() {
    final q = headerBubbleQuotes[_headerSeqIndex % headerBubbleQuotes.length];
    _headerSeqIndex++;
    return q;
  }

  /// 순차적 룸 대사 반환 (테스트용)
  static String getRandomRoomQuote(String? previousQuote) {
    final q = roomQuotes[_roomSeqIndex % roomQuotes.length];
    _roomSeqIndex++;
    return q;
  }
}
