import 'package:flutter_test/flutter_test.dart';
import 'package:hagom_app/main.dart';
import 'package:hagom_app/screens/splash_screen.dart';
import 'package:hagom_app/screens/main_navigation_shell.dart';

void main() {
  testWidgets('0단계 스플래시 화면 렌더링 및 메인 네비게이션 진입 테스트', (WidgetTester tester) async {
    // 1. 앱 빌드
    await tester.pumpWidget(const HagomApp());

    // 2. 스플래시 화면 정상 노출 확인
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('하곰이와 함께하는'), findsOneWidget);
    expect(find.text('복약 & 습관 케어'), findsOneWidget);

    // 3. 1.5초 타이머 및 화면 전환 완료 대기
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 4. 메인 네비게이션 셸 진입 및 3대 탭(복약, 작은 습관, 달력) 노출 확인
    expect(find.byType(MainNavigationShell), findsOneWidget);
    expect(find.text('복약 관리'), findsOneWidget);
    expect(find.text('복약'), findsOneWidget);
    expect(find.text('작은 습관'), findsOneWidget);
    expect(find.text('달력'), findsOneWidget);
  });
}
