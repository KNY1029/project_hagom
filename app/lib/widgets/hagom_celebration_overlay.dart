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
  int _currentMode = 0;
  static const int _totalModes = 11;

  @override
  void initState() {
    super.initState();
    // 🌟 과하지 않고 은은하게 1.5초 동안만 가볍게 터지도록 설정!
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));
    _confettiController.play();

    // 🌟 2.2초마다 순서대로 자동 전환 (화면 탭하면 즉시 다음 모드로 전환)
    _modeCycleTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _currentMode = (_currentMode + 1) % _totalModes;
        });
      }
    });

    // 11개 시안을 충분히 볼 수 있도록 총 26초 후 자동 종료
    _autoCloseTimer = Timer(const Duration(milliseconds: 26000), () {
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
    setState(() {
      _currentMode = (_currentMode + 1) % _totalModes;
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
                    _getModeLabel(_currentMode),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 🌟 선택된 스타일 렌더링
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

  String _getModeLabel(int mode) {
    switch (mode) {
      case 0:
        return '0안: 글자 뒤 배경 처리 안 한 원본';
      // 1안 계열 (캡슐 글래스 배지)
      case 1:
        return '1-A안: 화이트 밀크 글래스 배지';
      case 2:
        return '1-B안: 라벤더 틴트 글래스 배지 (테마 퍼플)';
      case 3:
        return '1-C안: 웜 크림 글래스 배지 (테마 웜브라운)';
      // 2안 계열 (방사형 빛무리 헤일로)
      case 4:
        return '2-A안: 소프트 화이트 글로우 헤일로';
      case 5:
        return '2-B안: 은은한 라벤더 퍼플 헤일로';
      case 6:
        return '2-C안: 따뜻한 웜 크림 헤일로';
      // 3안 계열 (테마 컬러 섀도우)
      case 7:
        return '3-A안: 테마 퍼플 글씨 + 화이트 글로우';
      case 8:
        return '3-B안: 테마 딥브라운 텍스트 + 테마 퍼플 섀도우';
      case 9:
        return '3-C안: 화이트 글씨 + 테마 퍼플/브라운 윤곽';
      // 5안 (글자 없음)
      case 10:
      default:
        return '5안: 글자 없음 (하곰이 댄스 + 꽃가루만)';
    }
  }

  Widget _buildTextContent(int mode) {
    switch (mode) {
      case 0:
        // ⚪ 0안: 글자 뒤 배경 처리 안 한 원본 (순수 텍스트 기본 상태)
        return Column(
          key: const ValueKey(0),
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
            const SizedBox(height: 4),
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
        );

      // ==========================================
      // 1안 시리즈: 몽글몽글 알약 캡슐 글래스 배지
      // ==========================================
      case 1:
        // 🫧 1-A안: 맑은 화이트 밀크톤 글래스 배지
        return _buildCapsuleBadge(
          keyInt: 1,
          bgColor: Colors.white.withValues(alpha: 0.88),
          borderColor: Colors.white.withValues(alpha: 0.95),
          shadowColor: const Color(0xFF7B61A8).withValues(alpha: 0.12),
          titleColor: AppColors.textPrimary,
          subtitleColor: AppColors.textSecondary,
        );

      case 2:
        // 💜 1-B안: 라벤더 틴트 글래스 배지 (테마 퍼플 프레임)
        return _buildCapsuleBadge(
          keyInt: 2,
          bgColor: AppColors.lightLavender.withValues(alpha: 0.85),
          borderColor: AppColors.primaryPurple.withValues(alpha: 0.35),
          shadowColor: AppColors.primaryPurple.withValues(alpha: 0.20),
          titleColor: AppColors.primaryPurple,
          subtitleColor: AppColors.textSecondary,
        );

      case 3:
        // 🤎 1-C안: 따뜻한 웜 크림 글래스 배지 (테마 웜 포인트)
        return _buildCapsuleBadge(
          keyInt: 3,
          bgColor: const Color(0xFFFFF9E6).withValues(alpha: 0.90),
          borderColor: AppColors.warmBrown.withValues(alpha: 0.3),
          shadowColor: AppColors.warmBrown.withValues(alpha: 0.15),
          titleColor: AppColors.textPrimary,
          subtitleColor: AppColors.warmBrown,
        );

      // ==========================================
      // 2안 시리즈: 은은한 방사형 빛무리(헤일로)
      // ==========================================
      case 4:
        // 🌫️ 2-A안: 소프트 화이트 글로우 헤일로
        return _buildHaloGlow(
          keyInt: 4,
          glowCenter: Colors.white.withValues(alpha: 0.96),
          glowMid: Colors.white.withValues(alpha: 0.80),
          titleColor: AppColors.textPrimary,
          subtitleColor: AppColors.textSecondary,
        );

      case 5:
        // 💜 2-B안: 은은한 라벤더 퍼플 헤일로 (테마 연보라 빛무리)
        return _buildHaloGlow(
          keyInt: 5,
          glowCenter: AppColors.lightLavender.withValues(alpha: 0.95),
          glowMid: AppColors.lightLavender.withValues(alpha: 0.65),
          titleColor: AppColors.primaryPurple,
          subtitleColor: AppColors.textPrimary,
        );

      case 6:
        // 🤎 2-C안: 따뜻한 웜 크림빛 헤일로
        return _buildHaloGlow(
          keyInt: 6,
          glowCenter: const Color(0xFFFFF8E1).withValues(alpha: 0.96),
          glowMid: const Color(0xFFFFF8E1).withValues(alpha: 0.65),
          titleColor: AppColors.textPrimary,
          subtitleColor: AppColors.warmBrown,
        );

      // ==========================================
      // 3안 시리즈: 테마 컬러 섀도우 (도형 없음)
      // ==========================================
      case 7:
        // 💜 3-A안: 테마 시그니처 퍼플 + 화이트 앰비언트 글로우
        return Column(
          key: const ValueKey(7),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 14),
                  Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 6),
                  Shadow(color: AppColors.lightLavender.withValues(alpha: 0.8), blurRadius: 20),
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
                color: AppColors.warmBrown,
                shadows: const [
                  Shadow(color: Colors.white, blurRadius: 10),
                  Shadow(color: Colors.white, blurRadius: 4),
                ],
              ),
            ),
          ],
        );

      case 8:
        // 🤎 3-B안: 테마 textPrimary(따뜻한 딥브라운) + 테마 퍼플 섀도우
        return Column(
          key: const ValueKey(8),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(color: Colors.white.withValues(alpha: 0.95), blurRadius: 12),
                  Shadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
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
                  Shadow(color: Colors.white, blurRadius: 8),
                ],
              ),
            ),
          ],
        );

      case 9:
        // 🔮 3-C안: 선명한 화이트 글씨 + 테마 퍼플 및 딥브라운 윤곽 섀도우
        return Column(
          key: const ValueKey(9),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(color: AppColors.primaryPurple, blurRadius: 12),
                  Shadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                color: AppColors.lightLavender,
                shadows: [
                  Shadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        );

      // ==========================================
      // 5안: 글자 없음 (하곰이 댄스 + 꽃가루만)
      // ==========================================
      case 10:
      default:
        return const SizedBox(
          key: ValueKey(10),
          height: 30,
        );
    }
  }

  /// 1안 캡슐 글래스 빌더 헬퍼
  Widget _buildCapsuleBadge({
    required int keyInt,
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return ClipRRect(
      key: ValueKey(keyInt),
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
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
                  color: titleColor,
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
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2안 방사형 빛무리(헤일로) 빌더 헬퍼
  Widget _buildHaloGlow({
    required int keyInt,
    required Color glowCenter,
    required Color glowMid,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      key: ValueKey(keyInt),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(30),
        gradient: RadialGradient(
          colors: [
            glowCenter,
            glowMid,
            glowCenter.withValues(alpha: 0.0),
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
              color: titleColor,
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
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
