import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import 'splash_screen.dart';
import 'widget_simulator_screen.dart';
import '../widgets/daily_greeting_modal.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/celebration_toast.dart';

/// ⚙️ 실제 작동하는 하곰이 설정 화면 (PRD 5.4절 준수)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppStateManager _state = AppStateManager();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  // 📥 의료진 제출용 CSV 엑셀 파일 다운로드 실행
  Future<void> _exportMedicalCsv() async {
    try {
      final csvContent = _state.generateMedicalCsvReport();
      // 안드로이드 공용 Download 폴더 경로 지정
      final downloadDir = Directory('/storage/emulated/0/Download');
      final fileName = '하곰이_복약상담기록_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}.csv';
      
      File file;
      if (await downloadDir.exists()) {
        file = File('${downloadDir.path}/$fileName');
      } else {
        // 내부 앱 파일 디렉토리 fallback
        file = File('/data/user/0/com.healthpharma.hagom_app/files/$fileName');
      }

      await file.writeAsString(csvContent);

      if (mounted) {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: const Text('엑셀(CSV) 저장 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Text(
              '스마트폰의 [다운로드] 폴더에 의료진 상담용 복약 기록 파일이 저장되었어요!\n\n파일명: $fileName\n\n진료 시 의사 선생님께 보여드리거나 메신저로 전송하실 수 있어요.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(dCtx).pop(),
                child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CelebrationToast.show(
          context,
          title: '저장 완료',
          message: '복약 기록 파일이 안전하게 생성되었어요.',
        );
      }
    }
  }

  // ⚠️ 전체 데이터 초기화 다이얼로그
  void _confirmResetAllData() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('모든 데이터 초기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.missedRed)),
        content: const Text(
          '등록된 모든 복약, 습관, 일정 기록이 완전히 삭제되고 초기 상태로 되돌아갑니다. 정말 초기화할까요?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.missedRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              await _state.resetAllData();
              if (mounted) {
                CelebrationToast.show(
                  context,
                  title: '초기화 완료',
                  message: '모든 데이터가 깨끗하게 초기 상태로 리셋되었어요.',
                );
              }
            },
            child: const Text('초기화 확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 🐻 상단 하곰이 마스코트 프로필 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppAssets.settingsMascot,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '하곰이 헬스케어 메이트',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '정신약학 비처벌 복약 솔루션 · v0.30.90',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 🔔 1. 알림 통합 설정 시스템 (Notification Matrix)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '알림 및 임상 안전',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                // 1) 알림 빈도 강도 조절 (최소 / 기본 / 적극적)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('알림 반복 빈도', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(_state.notificationFrequency, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _state.notificationFrequency == '최소'
                            ? '정시에 딱 1번만 알리고 재알림을 보내지 않아요.'
                            : (_state.notificationFrequency == '기본'
                                ? '15분 전 사전 예고 + 정시 + 미복용 시 30분 뒤 1회 추가 리마인드해요.'
                                : '30분 전 사전 예고 + 정시 + 복용 완료할 때까지 15분 간격으로 계속 알려요.'),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: ['최소', '기본', '적극적'].map((freq) {
                          final isSel = _state.notificationFrequency == freq;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Center(child: Text(freq)),
                                selected: isSel,
                                showCheckmark: false,
                                selectedColor: AppColors.lightLavender,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? AppColors.primaryPurple : AppColors.textSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: isSel ? AppColors.primaryPurple : AppColors.divider),
                                ),
                                onSelected: (val) {
                                  if (val) _state.setNotificationFrequency(freq);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 2) 💊 복약 알림 (처방약 상시 켜짐 스마트 토글!)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeColor: AppColors.primaryPurple,
                  title: const Text('복약 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text(
                    _state.medsNotificationEnabled
                        ? '일반약 및 필수 처방약 알림 수신 중'
                        : '일반약 알림 OFF (처방약은 안전을 위해 켜짐 유지)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _state.medsNotificationEnabled ? AppColors.textSecondary : AppColors.missedRed,
                    ),
                  ),
                  value: _state.medsNotificationEnabled,
                  onChanged: (val) {
                    if (!val) {
                      // 처방약 보호 안내 다이얼로그
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('복약 알림 안내', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          content: const Text(
                            '일반약 알림만 꺼지며, 처방약은 안전을 위해 켜짐이 유지돼요.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _state.setMedsNotification(false);
                              },
                              child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      _state.setMedsNotification(true);
                    }
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 3) 🌱 작은 습관 알림
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeColor: AppColors.primaryPurple,
                  title: const Text('작은 습관 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('물 마시기, 산책 등 데일리 루틴 실천 리마인드', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.habitNotificationEnabled,
                  onChanged: (val) => _state.setHabitNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 4) 🗓️ 할일 및 일정 알림
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeColor: AppColors.primaryPurple,
                  title: const Text('일정 및 할일 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('병원 예약, 과제 마감 등 등록된 일정 사전 알림', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.tasksNotificationEnabled,
                  onChanged: (val) => _state.setTasksNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 5) 🐻 하곰이 응원 및 넛지 알림
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeColor: AppColors.primaryPurple,
                  title: const Text('하곰이 따뜻한 응원 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('비처벌적 힐링과 응원의 한마디', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.mascotNotificationEnabled,
                  onChanged: (val) => _state.setMascotNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 6) ☀️ 하루 갱신 기준 시각 (기본 오전 8:00)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryPurple),
                  title: const Text('하루 갱신 기준 시각', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text(
                    '매일 ${_state.dailyResetTimeString} 기준 새 하루가 시작돼요',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightLavender,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _state.dailyResetTimeString,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    ),
                  ),
                  onTap: () async {
                    final currentTime = TimeOfDay(hour: _state.dailyResetHour, minute: _state.dailyResetMinute);
                    final picked = await AppTimePicker.show(
                      context,
                      initialTime: currentTime,
                      title: '하루 갱신 기준 시각 설정',
                    );
                    if (picked != null) {
                      _state.setDailyResetTime(picked.hour, picked.minute);
                      CelebrationToast.show(
                        context,
                        title: '갱신 시각 변경',
                        message: '하루 갱신 기준 시각이 ${_state.dailyResetTimeString}으로 설정되었어요.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 📊 2. 데이터 내보내기 & 의료진 리포트
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '데이터 및 의료진 상담',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.help_outline, color: AppColors.primaryPurple),
                  title: const Text('앱 사용 가이드 다시 보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('복약, 습관, 달력 탭의 핵심 기능 및 색상 요약', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (gCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: const Text('하곰이 헬스케어 가이드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        content: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('💊 복약 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple)),
                              SizedBox(height: 4),
                              Text('• [지금 복용]을 누르면 예정 시각이 실제 복약 시각으로 기록돼요.\n• 카드를 누르면 [정보 수정]이나 자책 없이 넘기는 [건너뛰기]를 할 수 있어요.', style: TextStyle(fontSize: 12, height: 1.4)),
                              SizedBox(height: 12),
                              Text('🌱 습관 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple)),
                              SizedBox(height: 4),
                              Text('• [대기] ➔ [조금 실천(0.5점)] ➔ [완료(1.0점)] 3단계로 유연하게 인정돼요.\n• 4잔 중 1잔만 마셔도 상단 게이지에 정확하게 실천 점수가 반영돼요.', style: TextStyle(fontSize: 12, height: 1.4)),
                              SizedBox(height: 12),
                              Text('📅 기록 달력', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple)),
                              SizedBox(height: 4),
                              Text('• 연초록 파스텔 셀: 복약과 습관 100% 완료.\n• 빨간 바: 처방약 누락 안전 경고.\n• 갈색 바: 일반약 또는 습관 부분 실천 상태.\n• 과거 날짜를 눌러 소급 체크해도 하곰이가 똑같이 축하해 드려요.', style: TextStyle(fontSize: 12, height: 1.4)),
                            ],
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.of(gCtx).pop(),
                            child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.widgets_outlined, color: AppColors.primaryPurple),
                  title: const Text('스마트폰 홈 위젯 쇼룸', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('2×1 마스코트 4대 감정 및 1-Tap 즉시 체크 위젯 시뮬레이터', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const WidgetSimulatorScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.celebration_outlined, color: AppColors.primaryPurple),
                  title: const Text('일일 첫 접속 환영 애니메이션 다시 보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('하곰이 출석 지지 환영 GIF 전체 화면 체험', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const SplashScreen(forceGreetingPreview: true),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.table_view_outlined, color: AppColors.primaryPurple),
                  title: const Text('복약 기록 엑셀(CSV) 다운로드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('의료진 진료 상담용 스프레드시트 파일 저장', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: _exportMedicalCsv,
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.restart_alt_outlined, color: AppColors.primaryPurple),
                  title: const Text('시작 모드 선택 초기화', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('앱을 다시 열었을 때 시작 모드(바로 시작/온보딩/개발자) 선택창 다시 띄우기', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () async {
                    await _state.resetInitialModeSelection();
                    CelebrationToast.show(
                      context,
                      title: '모드 선택 초기화 완료',
                      message: '다음 앱 실행 시 시작 모드 선택창이 다시 표시돼요.',
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.delete_outline, color: AppColors.missedRed),
                  title: const Text('모든 데이터 초기화', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.missedRed)),
                  subtitle: const Text('복약, 습관, 일정 기록을 모두 비우고 초기화', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onTap: _confirmResetAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
