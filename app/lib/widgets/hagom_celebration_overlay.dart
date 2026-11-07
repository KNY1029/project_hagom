import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../constants/app_colors.dart';

/// 🐻 [하곰이 올클리어 축하 플로팅 오버레이]
/// - 화면 전체를 가리지 않고 뒤쪽 탭 내용이 은은하게 비치는 반투명 배경
/// - 애니메이션 길이(약 2.9초) 동안 하곰이가 끝까지 춤추며 응원
/// - 끝나면 자동으로 부드럽게 닫히며, 화면 어디든 탭해도 즉시 닫기 가능
class HagomCelebrationOverlay {
  static void show(
    BuildContext context, {
    required String assetPath,
    required String title,
    required String subtitle,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    // 🌟 플러터 이미지 캐시에서 해당 WebP를 비워주어, 다시 열었을 때 항상 1프레임부터 완벽하게 다시 재생되도록 보장!
    AssetImage(assetPath).evict();
    final uniquePlayKey = UniqueKey();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '축하 오버레이 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return _CelebrationOverlayContent(
          assetPath: assetPath,
          uniquePlayKey: uniquePlayKey,
          title: title,
          subtitle: subtitle,
          duration: duration,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: curved,
            child: child,
          ),
        );
      },
    );
  }
}

class _CelebrationOverlayContent extends StatefulWidget {
  final String assetPath;
  final Key uniquePlayKey;
  final String title;
  final String subtitle;
  final Duration duration;

  const _CelebrationOverlayContent({
    required this.assetPath,
    required this.uniquePlayKey,
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  @override
  State<_CelebrationOverlayContent> createState() => _CelebrationOverlayContentState();
}

class _CelebrationOverlayContentState extends State<_CelebrationOverlayContent> {
  late ConfettiController _confettiController;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // 🌟 과하지 않고 은은하게 1.5초 동안만 가볍게 터지도록 설정!
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));
    _confettiController.play();

    _autoCloseTimer = Timer(widget.duration, () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _closeImmediately() {
    _autoCloseTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeImmediately,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🎈 1. 하곰이 뒤편 중심에서 가볍게 팡 터지는 은은한 파스텔 꽃가루 파티클
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.03, // 빈도를 낮춰 조용하게 팡!
                numberOfParticles: 16,    // 딱 16조각만 소량 생성
                gravity: 0.12,            // 천천히 나풀나풀 떨어지는 중력
                maxBlastForce: 14,        // 너무 멀리 퍼지지 않는 아담한 반경
                minBlastForce: 6,
                colors: const [
                  Color(0xFF7B61A8), // 라벤더 퍼플
                  Color(0xFFB39DDB), // 연보라
                  Color(0xFFE8F5E9), // 파스텔 민트
                  Color(0xFFFFF9C4), // 크림 옐로우
                  Color(0xFFFFECB3), // 소프트 피치
                ],
              ),
            ),

            // 🐻 2. 전면에서 춤추는 투명 하곰이 & 축하 텍스트
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Image.asset(
                    widget.assetPath,
                    key: widget.uniquePlayKey,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
