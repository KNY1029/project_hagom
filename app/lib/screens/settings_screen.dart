import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// 앱 전반의 설정 화면 (0단계 골격)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 상단 프로필/마스코트 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    AppAssets.settingsMascot,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '하곰이 케어 메이트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '버전 0.1.0 (골격 단계)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 설정 메뉴 리스트
          _buildSettingsGroup(
            title: '알림 및 안전',
            items: [
              _buildSettingsTile(
                icon: Icons.notifications_active_outlined,
                title: '복약 알림',
                trailingText: '항상 켜짐 🔒',
                subtitle: '약학적 안전을 위해 복약 알림은 끌 수 없습니다.',
              ),
              _buildSettingsTile(
                icon: Icons.bedtime_outlined,
                title: '방해 금지 시간 설정',
                trailingText: '23:00 ~ 07:00',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            title: '데이터 및 내보내기',
            items: [
              _buildSettingsTile(
                icon: Icons.file_download_outlined,
                title: '복약 기록 다운로드 (의료진 제출용)',
                subtitle: 'Excel / CSV / 이미지 형태로 저장',
              ),
              _buildSettingsTile(
                icon: Icons.backup_outlined,
                title: '기록 백업 및 복원',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          : null,
      trailing: trailingText != null
          ? Text(
              trailingText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
    );
  }
}
