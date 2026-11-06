# 테마 기능 백업 (Theme Feature Backup)

## 📌 개요
이 폴더는 다중 테마 선택 및 탭별 미니 테마(복약·습관·달력 고유 포인트 색상 및 커스텀 HEX 팔레트) 기능을 기본 테마로 단일화하기 전에 보관해 둔 백업 코드입니다.
나중에 다시 동적 테마 스위칭 기능이나 커스텀 색상 지정 기능을 도입할 때 참고할 수 있도록 관련 파일들을 온전하게 보존하고 있습니다.

## 📁 보관된 주요 파일
1. `lib/constants/app_colors.dart`
   - 동적 활성 테마 필드(`activePrimary`, `activeBackground`, `activeLightTint` 등)
   - 테마 프리셋 식별자(`deep_violet`, `widget_habit_brown`, `widget_task_ocher`, `custom`)
   - 탭별 미니 테마 포인트 컬러 제어 로직
2. `lib/state/app_state_manager.dart`
   - `setTheme()`, `setCustomTheme()`, `setTabMiniThemeColors()` 등 상태 변경 메서드
   - `SharedPreferences`를 통한 테마 및 탭별 색상 영구 저장 및 복원 로직
3. `lib/screens/settings_screen.dart`
   - 테마 및 색상 설정 모달(`_showDeveloperThemeModal`)
   - 프리셋 라디오 타일 및 미니 테마 색상 선택 다이얼로그(`_showColorPickDialog`)
4. `lib/screens/main_navigation_shell.dart`
   - 탭 전환 시 탭별 고유 미니 테마 포인트 컬러로 앱바 타이틀 및 활성 아이콘 색상 반응 로직
5. `lib/services/hagom_native_widget_sync.dart`
   - 앱 내 테마 색상을 안드로이드 네이티브 위젯 저장소(`theme_meds_color`, `theme_habits_color`, `theme_tasks_color`)로 실시간 전달하는 동기화 로직
6. `android/app/src/main/kotlin/...`
   - 네이티브 홈 위젯 프로바이더에서 동적 테마 색상을 수신하여 배지 및 버튼에 칠하는 로직
