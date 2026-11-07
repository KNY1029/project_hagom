import 'dart:async';
import 'dart:ui';
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
  Timer? _modeCycleTimer;
  int _currentMode = 0; // 0: 캡슐 글래스 배지, 1: 방사형 빛무리(헤일로), 2: 다크 소프트 섀도우

  @override
  void initState() {
    super.initState();
    // 🌟 과하지 않고 은은하게 1.5초 동안만 가볍게 터지도록 설정!
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));
    _confettiController.play();

    // 🌟 1.8초마다 3가지 스타일이 순서대로 자동 전환되어 비교해볼 수 있게 함! (터치하면 다음 스타일로 즉시 변경 가능)
    _modeCycleTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _currentMode = (_currentMode + 1) % 3;
        });
      }
    });

    // 충분히 볼 수 있도록 총 8.5초 후 자동 종료
    _autoCloseTimer = Timer(const Duration(milliseconds: 8500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _modeCycleTimer?.cancel();
    _autoCloseTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTapNextOrClose() {
    // 탭하면 다음 스타일로 전환, 3개 다 돌았거나 길게 닫고 싶으면 setState
    setState(() {
      _currentMode = (_currentMode + 1) % 3;
    });
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
      onTap: _onTapNextOrClose,
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

            // 🐻 2. 전면에서 춤추는 투명 하곰이 & 비교 테스트 축하 텍스트
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
                const SizedBox(height: 12),

                // 🌟 현재 보고 있는 스타일 라벨 (비교용)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentMode == 0
                        ? '1안: 몽글몽글 캡슐 글래스 배지'
                        : _currentMode == 1
                            ? '2안: 은은한 방사형 빛무리(헤일로)'
                            : '3안: 다크 소프트 섀도우(배경 없음)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 🌟 선택된 3가지 스타일 렌더링
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildTextContent(_currentMode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(int mode) {
    switch (mode) {
      case 0:
        // 🫧 1안: 프로스티드 알약 글래스 배지 (블러 + 반투명 밀크톤 + 둥근 캡슐)
        return ClipRRect(
          key: const ValueKey(0),
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61A8).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 1:
        // 🌫️ 2안: 은은한 방사형 빛무리(헤일로) (경계선 없이 부드럽게 퍼지는 후광)
        return Container(
          key: const ValueKey(1),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(30),
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.96),
                Colors.white.withValues(alpha: 0.80),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.65, 1.0],
              radius: 0.85,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case 2:
      default:
        // 🖤 3안: 배경 도형 없이 텍스트 다크 소프트 섀도우 강화
        return Column(
          key: const ValueKey(2),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white, // 흰색 글씨 + 진한 퍼플 섀도우로 선명 대비
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: const Color(0xFF3E2723).withValues(alpha: 0.75),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  Shadow(
                    color: const Color(0xFF7B61A8).withValues(alpha: 0.8),
                    blurRadius: 16,
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
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFF9C4), // 따뜻한 크림빛
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
