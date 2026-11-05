import 'package:flutter/material.dart';

/// 하곰이 앱의 핵심 테마 시스템
///
/// 컴파일 타임 `const` 호환성을 100% 보장하는 기본 팔레트와,
/// 개발자 모드에서 실시간으로 스위칭되는 동적 활성 테마(Active Theme) 및
/// 탭별 미니 테마(복약/습관/달력 각각의 포인트 컬러)를 완벽하게 제공합니다.
class AppColors {
  // -------------------------------------------------------------
  // 1. 기본 불변 정적 상수 (컴파일 타임 const 위젯 100% 지원)
  // -------------------------------------------------------------
  static const Color primaryPurple = Color(0xFF7B61A8); // 메인 라벤더 퍼플
  static const Color warmBrown = Color(0xFF8B5E3C);     // 웜 브라운 (습관 기본)
  static const Color defaultTaskOcher = Color(0xFFB58A32);     // 더스티 옐로우 오커 (할일 기본)
  static const Color lightLavender = Color(0xFFF3EFF8); // 연한 라벤더 배경색
  static const Color background = Color(0xFFFAF8F5);    // 웜 베이지 브라운 배경
  static const Color cardSurface = Colors.white;        // 카드 기본 흰색
  static const Color divider = Color(0xFFE5E7EB);        // 옅은 구분선
  static const Color textPrimary = Color(0xFF1F2937);   // 주요 글자색
  static const Color textSecondary = Color(0xFF6B7280); // 부가 설명 글자색
  static const Color textMuted = Color(0xFF9CA3AF);     // 비활성 보조 글자색

  // -------------------------------------------------------------
  // 2. 동적 활성 테마 필드 (실시간 테마 변경 시 전역 반영)
  // -------------------------------------------------------------
  static Color activePrimary = primaryPurple;
  static Color activeBackground = background;
  static Color activeLightTint = lightLavender;
  static Color activeTextPrimary = textPrimary;
  static Color activeTextSecondary = textSecondary;
  static Color activeWarmAccent = warmBrown;
  static Color activeDivider = divider;

  // -------------------------------------------------------------
  // 3. 탭별 미니 테마 포인트 컬러 (복약 / 습관 / 달력)
  // -------------------------------------------------------------
  static bool useTabMiniThemes = true; // 탭별 미니 테마 활성화 여부
  static Color tabMedsColor = primaryPurple; // 복약 탭 포인트 (#7B61A8)
  static Color tabHabitsColor = warmBrown;    // 습관 탭 포인트 (#8B5E3C)
  static Color tabCalendarColor = defaultTaskOcher;  // 달력 탭 포인트 (#B58A32)

  // -------------------------------------------------------------
  // 4. 상태 및 피드백 컬러
  // -------------------------------------------------------------
  static const Color completedBg = Color(0xFFEAF8F1);    // 소프트 민트초록 틴트
  static const Color completedText = Color(0xFF1B6B46);  // 선명한 딥 그린 텍스트
  static const Color completedBorder = Color(0xFFA3DBC0); // 민트초록 테두리
  static const Color partialBg = Color(0xFFF7F3EE);      // 소프트 웜 크림 베이지
  static const Color partialText = Color(0xFF8B5E3C);    // 부분 실천 웜브라운 텍스트
  static const Color partialBorder = Color(0xFFE5DDD0);  // 부분 실천 테두리
  static const Color successGreen = Color(0xFF065F46);   // 달력 100% 달성 텍스트
  static const Color successBg = Color(0xFFE6F8F0);      // 달력 100% 달성 연초록 틴트
  static const Color partialOrange = Color(0xFF8B5E3C);  // 부분 달성 뱃지
  static const Color neutralDark = Color(0xFF4B5563);    // 차분한 삭제/취소 색상
  static const Color missedRed = Color(0xFFEF4444);      // 약 미복용 경고 레드

  // -------------------------------------------------------------
  // 5. 테마 프리셋 식별자
  // -------------------------------------------------------------
  static const String themeDefault = 'default';
  static const String themeDeepViolet = 'deep_violet';
  static const String themeWidgetHabitBrown = 'widget_habit_brown';
  static const String themeWidgetTaskOcher = 'widget_task_ocher';
  static const String themeCustom = 'custom';

  static String currentThemeKey = themeDefault;

  /// 프리셋 적용 함수
  static void applyPreset(String key) {
    currentThemeKey = key;
    switch (key) {
      case themeDeepViolet:
        // #eae2fb 메인에 #541d7a 진한 글씨 테마
        activePrimary = const Color(0xFF541D7A);
        activeBackground = const Color(0xFFF7F3FD);
        activeLightTint = const Color(0xFFEAE2FB);
        activeTextPrimary = const Color(0xFF541D7A); // 진한 글씨에 #541d7a 적용
        activeTextSecondary = const Color(0xFF755196);
        activeWarmAccent = const Color(0xFF8B5E3C);
        activeDivider = const Color(0xFFE6DCF5);
        tabMedsColor = const Color(0xFF541D7A);
        break;

      case themeWidgetHabitBrown:
        // 습관 위젯 웜 브라운 포인트 미니 테마
        activePrimary = const Color(0xFF8B5E3C);
        activeBackground = const Color(0xFFFAF8F5);
        activeLightTint = const Color(0xFFF7F3EE);
        activeTextPrimary = const Color(0xFF2C1E14);
        activeTextSecondary = const Color(0xFF735845);
        activeWarmAccent = const Color(0xFF6B4226);
        activeDivider = const Color(0xFFE5DDD0);
        break;

      case themeWidgetTaskOcher:
        // 할일 위젯 더스티 옐로우 오커 포인트 미니 테마
        activePrimary = const Color(0xFFB58A32);
        activeBackground = const Color(0xFFFCF9F2);
        activeLightTint = const Color(0xFFFBF6E9);
        activeTextPrimary = const Color(0xFF2B210C);
        activeTextSecondary = const Color(0xFF6E5C35);
        activeWarmAccent = const Color(0xFF8B5E3C);
        activeDivider = const Color(0xFFE8DFCE);
        break;

      case themeDefault:
      default:
        // 기본 라벤더 퍼플 & 웜 브라운 테마
        activePrimary = primaryPurple;
        activeBackground = background;
        activeLightTint = lightLavender;
        activeTextPrimary = textPrimary;
        activeTextSecondary = textSecondary;
        activeWarmAccent = warmBrown;
        activeDivider = divider;
        tabMedsColor = primaryPurple;
        tabHabitsColor = warmBrown;
        tabCalendarColor = defaultTaskOcher;
        break;
    }
  }

  /// 사용자 정의 커스텀 테마 색상 직접 주입
  static void applyCustomColors({
    required Color primary,
    required Color background,
    required Color lightTint,
    required Color textPrimary,
    required Color warmAccent,
  }) {
    currentThemeKey = themeCustom;
    activePrimary = primary;
    activeBackground = background;
    activeLightTint = lightTint;
    activeTextPrimary = textPrimary;
    activeWarmAccent = warmAccent;
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
}
