import 'package:flutter/material.dart';

/// 테마 한 벌(앱 전체 팔레트) 정의.
/// 기본 제공 프리셋과 사용자가 직접 추가한 커스텀 테마가 같은 모델을 공유합니다.
class ThemePreset {
  final String key;
  final String name;
  final String description;
  final Color primary;
  final Color background;
  final Color lightTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color warmAccent;
  final Color divider;
  final bool isCustom;

  const ThemePreset({
    required this.key,
    required this.name,
    required this.description,
    required this.primary,
    required this.background,
    required this.lightTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.warmAccent,
    required this.divider,
    this.isCustom = false,
  });

  List<Color> get previewColors => [primary, warmAccent, lightTint];

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'primary': primary.toARGB32(),
        'background': background.toARGB32(),
        'lightTint': lightTint.toARGB32(),
        'textPrimary': textPrimary.toARGB32(),
        'textSecondary': textSecondary.toARGB32(),
        'warmAccent': warmAccent.toARGB32(),
        'divider': divider.toARGB32(),
      };

  factory ThemePreset.fromJson(Map<String, dynamic> json) => ThemePreset(
        key: json['key'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        primary: Color(json['primary'] as int),
        background: Color(json['background'] as int),
        lightTint: Color(json['lightTint'] as int),
        textPrimary: Color(json['textPrimary'] as int),
        textSecondary: Color(json['textSecondary'] as int),
        warmAccent: Color(json['warmAccent'] as int),
        divider: Color(json['divider'] as int),
        isCustom: true,
      );
}

/// 하곰이 앱의 핵심 테마 시스템
///
/// 팔레트 색상(primaryPurple, background, textPrimary 등)은 런타임에 교체되는 값이므로
/// 테마를 적용하면 앱 전체 화면과 홈 위젯이 같은 색으로 다시 그려집니다.
/// 탭별 미니 테마(복약/습관/달력 제목·탭 아이콘·위젯 포인트)는 기본 테마와 별개로 지정합니다.
class AppColors {
  // -------------------------------------------------------------
  // 1. 테마에 따라 바뀌는 팔레트 (applyTheme 으로 교체)
  // -------------------------------------------------------------
  static Color primaryPurple = defaultTheme.primary; // 메인 포인트 컬러
  static Color warmBrown = defaultTheme.warmAccent; // 보조 웜 포인트
  static Color lightLavender = defaultTheme.lightTint; // 연한 틴트 배경
  static Color background = defaultTheme.background; // 앱 배경
  static Color textPrimary = defaultTheme.textPrimary; // 주요 글자색
  static Color textSecondary = defaultTheme.textSecondary; // 부가 설명 글자색
  static Color divider = defaultTheme.divider; // 옅은 구분선

  // 테마와 무관한 고정 컬러
  static const Color defaultTaskOcher = Color(0xFFB58A32); // 더스티 옐로우 오커 (할일 기본)
  static const Color cardSurface = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF);

  // -------------------------------------------------------------
  // 2. 탭별 미니 테마 포인트 컬러 (복약 / 습관 / 달력)
  // -------------------------------------------------------------
  static const Color defaultTabMedsColor = Color(0xFF7B61A8);
  static const Color defaultTabHabitsColor = Color(0xFF8B5E3C);
  static const Color defaultTabCalendarColor = defaultTaskOcher;

  static bool useTabMiniThemes = true;
  static Color tabMedsColor = defaultTabMedsColor;
  static Color tabHabitsColor = defaultTabHabitsColor;
  static Color tabCalendarColor = defaultTabCalendarColor;

  // -------------------------------------------------------------
  // 3. 상태 및 피드백 컬러 (테마와 무관)
  // -------------------------------------------------------------
  static const Color completedBg = Color(0xFFEAF8F1);
  static const Color completedText = Color(0xFF1B6B46);
  static const Color completedBorder = Color(0xFFA3DBC0);
  static const Color partialBg = Color(0xFFF7F3EE);
  static const Color partialText = Color(0xFF8B5E3C);
  static const Color partialBorder = Color(0xFFE5DDD0);
  static const Color successGreen = Color(0xFF065F46);
  static const Color successBg = Color(0xFFE6F8F0);
  static const Color partialOrange = Color(0xFF8B5E3C);
  static const Color neutralDark = Color(0xFF4B5563);
  static const Color missedRed = Color(0xFFEF4444);

  // -------------------------------------------------------------
  // 4. 기본 제공 테마 프리셋
  // -------------------------------------------------------------
  static const String themeDefault = 'default';

  static const ThemePreset defaultTheme = ThemePreset(
    key: themeDefault,
    name: '기본 테마',
    description: '오리지널 라벤더 퍼플 (#7B61A8) & 웜 브라운',
    primary: Color(0xFF7B61A8),
    background: Color(0xFFFAF8F5),
    lightTint: Color(0xFFF3EFF8),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    warmAccent: Color(0xFF8B5E3C),
    divider: Color(0xFFE5E7EB),
  );

  static const List<ThemePreset> builtInThemes = [
    defaultTheme,
    ThemePreset(
      key: 'deep_violet',
      name: '딥 바이올렛',
      description: '#EAE2FB 연보라 배경과 #541D7A 또렷한 딥 퍼플 글씨',
      primary: Color(0xFF541D7A),
      background: Color(0xFFF7F3FD),
      lightTint: Color(0xFFEAE2FB),
      textPrimary: Color(0xFF541D7A),
      textSecondary: Color(0xFF755196),
      warmAccent: Color(0xFF8B5E3C),
      divider: Color(0xFFE6DCF5),
    ),
    ThemePreset(
      key: 'widget_habit_brown',
      name: '웜 브라운',
      description: '습관 위젯의 따뜻한 웜 브라운 톤을 앱 전체 포인트로 적용',
      primary: Color(0xFF8B5E3C),
      background: Color(0xFFFAF8F5),
      lightTint: Color(0xFFF7F3EE),
      textPrimary: Color(0xFF2C1E14),
      textSecondary: Color(0xFF735845),
      warmAccent: Color(0xFF6B4226),
      divider: Color(0xFFE5DDD0),
    ),
    ThemePreset(
      key: 'widget_task_ocher',
      name: '더스티 오커',
      description: '할일 위젯의 차분한 황토 골드 톤을 앱 전체 포인트로 적용',
      primary: Color(0xFFB58A32),
      background: Color(0xFFFCF9F2),
      lightTint: Color(0xFFFBF6E9),
      textPrimary: Color(0xFF2B210C),
      textSecondary: Color(0xFF6E5C35),
      warmAccent: Color(0xFF8B5E3C),
      divider: Color(0xFFE8DFCE),
    ),
  ];

  /// 팔레트 전체를 주어진 테마로 교체
  static void applyTheme(ThemePreset theme) {
    primaryPurple = theme.primary;
    warmBrown = theme.warmAccent;
    lightLavender = theme.lightTint;
    background = theme.background;
    textPrimary = theme.textPrimary;
    textSecondary = theme.textSecondary;
    divider = theme.divider;
  }

  /// 탭별 미니 테마 포인트 컬러 직접 주입
  static void setTabMiniColors({
    Color? meds,
    Color? habits,
    Color? calendar,
    bool? enabled,
  }) {
    if (meds != null) tabMedsColor = meds;
    if (habits != null) tabHabitsColor = habits;
    if (calendar != null) tabCalendarColor = calendar;
    if (enabled != null) useTabMiniThemes = enabled;
  }

  /// 미니 테마를 기본 포인트 색상으로 되돌림
  static void resetTabMiniColors() {
    useTabMiniThemes = true;
    tabMedsColor = defaultTabMedsColor;
    tabHabitsColor = defaultTabHabitsColor;
    tabCalendarColor = defaultTabCalendarColor;
  }

  /// #RRGGBB 문자열
  static String toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
