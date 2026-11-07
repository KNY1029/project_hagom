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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🐻 투명 애니메이션 하곰이 (전체 프레임 재생)
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🎉 축하 타이틀
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 따뜻한 격려 서브타이틀
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
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
