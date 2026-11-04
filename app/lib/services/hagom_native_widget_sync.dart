import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../state/app_state_manager.dart';

/// 📱 안드로이드 홈 화면 런처 위젯(2×1)에 앱의 최신 복약/습관 데이터를 동기화하는 서비스
class HagomNativeWidgetSync {
  static const String appWidgetProvider = 'HagomWidgetProvider';

  /// 앱 상태 변경 시 호출되어 안드로이드 홈 위젯의 텍스트와 상태를 즉시 갱신
  static Future<void> updateNativeWidget(AppStateManager state) async {
    // 웹 플랫폼에서는 네이티브 위젯 플러그인이 동작하지 않으므로 무시
    if (kIsWeb) return;

    try {
      String tag = '다음 복약';
      String progress = '${state.completedDoseSlots}/${state.totalDoseSlots} 완료';
      String title = '오늘 복약 완료';
      String subtitle = '오늘 예정된 모든 복약을 마쳤어요';
      String extra = '자가 모니터링 성공';
      String btnTitle = '완료';
      String btnSubtitle = '달성';

      // 다음 대기 중인 약 슬롯 탐색
      bool foundPending = false;
      for (final med in state.medications) {
        if (!med.isDueToday) continue;
        for (final slot in med.doseSlots) {
          if (!slot.isCompleted && !slot.isSkipped) {
            title = '${med.name} ${med.dosage}';
            subtitle = '${slot.scheduledTime ?? "예정"} · 식후 복용';
            extra = med.isPrescription ? '처방약 (시간 엄수)' : '일반약';
            btnTitle = '복용';
            btnSubtitle = '1-Tap';
            foundPending = true;
            break;
          }
        }
        if (foundPending) break;
      }

      // 등록된 약이 하나도 없는 경우
      if (!foundPending && state.medications.isEmpty) {
        title = '등록된 약 없음';
        subtitle = '앱에서 새로운 약을 추가해 보세요';
        extra = '자유 실천';
        progress = '0/0';
        btnTitle = '추가';
        btnSubtitle = '앱 열기';
      }

      // SharedPreferences / HomeWidget에 저장
      await HomeWidget.saveWidgetData<String>('widget_tag', tag);
      await HomeWidget.saveWidgetData<String>('widget_progress', progress);
      await HomeWidget.saveWidgetData<String>('widget_title', title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', subtitle);
      await HomeWidget.saveWidgetData<String>('widget_extra', extra);
      await HomeWidget.saveWidgetData<String>('widget_btn_title', btnTitle);
      await HomeWidget.saveWidgetData<String>('widget_btn_subtitle', btnSubtitle);

      // 안드로이드 홈 화면 위젯 갱신 요청
      await HomeWidget.updateWidget(
        name: appWidgetProvider,
        androidName: appWidgetProvider,
      );
    } catch (e) {
      debugPrint('Native widget update error: $e');
    }
  }
}
