import 'dart:async';
import 'package:flutter/material.dart';
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
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '축하 오버레이 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) {
        Timer? autoCloseTimer;
        autoCloseTimer = Timer(duration, () {
          if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop();
          }
        });

        return GestureDetector(
          onTap: () {
            autoCloseTimer?.cancel();
            if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
              Navigator.of(dialogCtx).pop();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Material(
            color: Colors.transparent,
            child: Center(
              // 🌟 창/박스(Container) 테두리 완전 제거! 하곰이가 화면 위에 직접 떠서 춤춤
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🐻 투명 애니메이션 하곰이 (화면 위에 직접 크게 노출)
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 축하 문구 (배경 박스 없이 텍스트만 자연스럽게 떠있음)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
