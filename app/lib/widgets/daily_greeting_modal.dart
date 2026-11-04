import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';

/// 🐻 [매일 최초 접속 축하 & 인사 모달]
/// 
/// - 하루 갱신 기준 시각(기본 오전 8:00, 환경설정에서 변경 가능) 이후
///   그날 앱을 처음 실행했을 때 자동으로 화면 중앙에 떠서
///   하곰이 환영 GIF 애니메이션과 함께 따뜻한 출석 지지 멘트를 건넵니다.
class DailyGreetingModal extends StatelessWidget {
  const DailyGreetingModal({super.key});

  static Future<void> show(BuildContext context) async {
    final state = AppStateManager();
    // 접속 완료 기록 저장
    await state.markDailyGreetingShown();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const DailyGreetingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateManager();
    final resetHourStr = '${state.dailyResetHour.toString().padLeft(2, '0')}:00';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🐻 1. 하곰이 귀여운 환영 애니메이션 (GIF 에셋)
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  AppAssets.dailyGreetingGif,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 🌟 2. 접속 축하 타이틀
            const Text(
              '오늘도 와주셔서 고마워요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // 💬 3. 비처벌적 지지 멘트 & 자가 모니터링 효능
            const Text(
              '앱을 켜고 나를 마주한 것만으로도\n오늘 치료를 위한 큰 한 걸음을 내딛은 거예요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // ⏰ 4. 하루 갱신 안내 칩
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightLavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '매일 $resetHourStr 기준 새 하루가 시작돼요',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🚀 5. 닫기 / 오늘 시작하기 버튼
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '오늘 하루도 편안하게 시작하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
