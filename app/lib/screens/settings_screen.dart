import 'dart:io';
import 'package:flutter/services.dart';
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

  static const MethodChannel _exportChannel = MethodChannel('com.healthpharma.hagom_app/export');

  // 📥 [보건약학 임상/교수님 자문용] 4대 영역 맞춤형 CSV 엑셀 다운로드 & 공유 모달
  Future<void> _exportMedicalCsv() async {
    bool includePrescription = true;
    bool includeOtc = true;
    bool includeHabits = true;
    bool includeTasks = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (mCtx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '건강 기록 데이터 추출 및 다운로드',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(mCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                '다운로드할 카테고리를 선택해 주세요. 앱에 기록된 모든 로우 데이터가 엑셀(CSV) 스프레드시트로 생성돼요.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),

              // 체크박스 4대 영역
              _buildCategoryCheckbox('처방약 데이터 (필수 복용약, 용법/용량, 복용 시각, 엄수 여부)', includePrescription, (val) {
                setModalState(() => includePrescription = val ?? false);
              }),
              _buildCategoryCheckbox('일반약 및 영양제 데이터 (비처방약, 일일 루틴, 복약 이행률)', includeOtc, (val) {
                setModalState(() => includeOtc = val ?? false);
              }),
              _buildCategoryCheckbox('작은 습관 데이터 (일일 실천 횟수, 주간 완료율, 비처벌 점수)', includeHabits, (val) {
                setModalState(() => includeHabits = val ?? false);
              }),
              _buildCategoryCheckbox('할일 및 진료 일정 데이터 (병원 방문, 복약 점검, 완료 현황)', includeTasks, (val) {
                setModalState(() => includeTasks = val ?? false);
              }),

              const SizedBox(height: 20),
              Row(
                children: [
                  // 1) 스마트폰 공용 Download 폴더에 진짜 파일 저장
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.primaryPurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (!includePrescription && !includeOtc && !includeHabits && !includeTasks)
                          ? null
                          : () async {
                              Navigator.of(mCtx).pop();
                              await _performCsvDownload(
                                includePrescription: includePrescription,
                                includeOtc: includeOtc,
                                includeHabits: includeHabits,
                                includeTasks: includeTasks,
                                isShare: false,
                              );
                            },
                      child: const Text('다운로드 폴더 저장', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 2) 카카오톡 / 메일 / 드라이브로 즉시 파일 내보내기 & 공유
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (!includePrescription && !includeOtc && !includeHabits && !includeTasks)
                          ? null
                          : () async {
                              Navigator.of(mCtx).pop();
                              await _performCsvDownload(
                                includePrescription: includePrescription,
                                includeOtc: includeOtc,
                                includeHabits: includeHabits,
                                includeTasks: includeTasks,
                                isShare: true,
                              );
                            },
                      child: const Text('파일 공유 및 전송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCsvDownload({
    required bool includePrescription,
    required bool includeOtc,
    required bool includeHabits,
    required bool includeTasks,
    required bool isShare,
  }) async {
    try {
      final csvContent = _state.generateComprehensiveHealthDataReport(
        includePrescription: includePrescription,
        includeOtc: includeOtc,
        includeHabits: includeHabits,
        includeTasks: includeTasks,
      );

      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = '하곰이_종합건강기록_$dateStr.csv';

      if (isShare) {
        // 안드로이드 공유창 (카카오톡, 메일, 드라이브)
        await _exportChannel.invokeMethod('shareCsv', {
          'fileName': fileName,
          'content': csvContent,
        });
      } else {
        // 안드로이드 공용 Download 폴더에 실제 다운로드
        final res = await _exportChannel.invokeMethod<Map>('downloadCsv', {
          'fileName': fileName,
          'content': csvContent,
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: const Text('다운로드 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Text(
                '스마트폰의 [다운로드] 폴더에 실제 엑셀(CSV) 파일이 성공적으로 저장되었어요!\n\n파일명: $fileName\n\n내 파일 앱의 [다운로드] 카테고리나 엑셀 앱에서 바로 열어보실 수 있어요.',
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
      }
    } catch (e) {
      if (mounted) {
        CelebrationToast.show(
          context,
          title: '파일 처리 오류',
          message: '파일 내보내기 중 문제가 발생했어요: $e',
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
                      '정신약학 비처벌 복약 솔루션 · v0.87.147',
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
                  leading: const Icon(Icons.palette_outlined, color: AppColors.primaryPurple),
                  title: const Text('테마 및 색상 설정 (개발자)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                  subtitle: Text('현재: ${_themeName(_state.currentThemeKey)} · 딥 바이올렛/위젯 미니 테마', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryPurple),
                  onTap: _showDeveloperThemeModal,
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
  String _themeName(String key) {
    switch (key) {
      case AppColors.themeDeepViolet:
        return '딥 바이올렛 (#EAE2FB 메인 / #541D7A 진한 글씨)';
      case AppColors.themeWidgetHabitBrown:
        return '습관 위젯 웜 브라운 미니 테마';
      case AppColors.themeWidgetTaskOcher:
        return '할일 위젯 오커 골드 미니 테마';
      case AppColors.themeCustom:
        return '사용자 정의 커스텀 테마';
      case AppColors.themeDefault:
      default:
        return '기본 라벤더 퍼플 & 웜 브라운';
    }
  }

  void _showDeveloperThemeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (bCtx, setMState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🛠️ 개발자 모드: 테마 및 색상 실시간 전환',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  '선택 즉시 앱 전체 폰트·배경·포인트 컬러가 실시간으로 재렌더링돼요.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // 1) 프리셋 라디오 타일들
                _buildThemeRadio(
                  title: '기본 테마',
                  subtitle: '오리지널 라벤더 퍼플 (#7B61A8) & 웜 브라운',
                  key: AppColors.themeDefault,
                  previewColors: [const Color(0xFF7B61A8), const Color(0xFF8B5E3C), const Color(0xFFF3EFF8)],
                  setMState: setMState,
                ),
                _buildThemeRadio(
                  title: '딥 바이올렛 테마 (#EAE2FB / #541D7A)',
                  subtitle: '#EAE2FB 연보라 메인 배경과 #541D7A 또렷한 딥 퍼플 글씨',
                  key: AppColors.themeDeepViolet,
                  previewColors: [const Color(0xFF541D7A), const Color(0xFFEAE2FB), const Color(0xFFF7F3FD)],
                  setMState: setMState,
                ),
                _buildThemeRadio(
                  title: '습관 위젯 미니 테마 (웜 브라운)',
                  subtitle: '습관 위젯의 따뜻한 웜 브라운 톤앤매너를 앱 전체 포인트로 적용',
                  key: AppColors.themeWidgetHabitBrown,
                  previewColors: [const Color(0xFF8B5E3C), const Color(0xFF6B4226), const Color(0xFFF7F3EE)],
                  setMState: setMState,
                ),
                _buildThemeRadio(
                  title: '할일 위젯 미니 테마 (더스티 오커)',
                  subtitle: '할일 위젯의 차분한 황토 골드 톤앤매너를 앱 전체 포인트로 적용',
                  key: AppColors.themeWidgetTaskOcher,
                  previewColors: [const Color(0xFFB58A32), const Color(0xFF8B5E3C), const Color(0xFFFBF6E9)],
                  setMState: setMState,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🎨 탭별 미니 테마 (복약·습관·달력 고유 포인트)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  '기본 톤은 유지하면서 각 탭의 제목/아이콘/위젯 색상만 각각 커스텀해요.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // 미니 테마 스위치
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryPurple,
                  title: const Text('탭별 미니 테마 포인트 활성화', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: AppColors.useTabMiniThemes,
                  onChanged: (val) {
                    _state.setTabMiniThemeColors(enabled: val);
                    setMState(() {});
                    setState(() {});
                  },
                ),

                if (AppColors.useTabMiniThemes) ...[
                  const SizedBox(height: 6),
                  _buildMiniThemeColorRow(
                    label: '복약 탭 & 위젯 포인트',
                    color: AppColors.tabMedsColor,
                    onTap: () => _showColorPickDialog(
                      title: '복약 포인트 색상 변경',
                      initial: AppColors.tabMedsColor,
                      onPicked: (c) {
                        _state.setTabMiniThemeColors(meds: c);
                        setMState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  _buildMiniThemeColorRow(
                    label: '습관 탭 & 위젯 포인트',
                    color: AppColors.tabHabitsColor,
                    onTap: () => _showColorPickDialog(
                      title: '습관 포인트 색상 변경',
                      initial: AppColors.tabHabitsColor,
                      onPicked: (c) {
                        _state.setTabMiniThemeColors(habits: c);
                        setMState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  _buildMiniThemeColorRow(
                    label: '달력/할일 탭 & 위젯 포인트',
                    color: AppColors.tabCalendarColor,
                    onTap: () => _showColorPickDialog(
                      title: '달력/할일 포인트 색상 변경',
                      initial: AppColors.tabCalendarColor,
                      onPicked: (c) {
                        _state.setTabMiniThemeColors(calendar: c);
                        setMState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: AppColors.primaryPurple),
                    ),
                    icon: Icon(Icons.colorize, size: 16, color: AppColors.primaryPurple),
                    label: Text(
                      '사용자 지정 색상 코드 직접 입력',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showCustomHexColorDialog();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeRadio({
    required String title,
    required String subtitle,
    required String key,
    required List<Color> previewColors,
    required StateSetter setMState,
  }) {
    final isSelected = (_state.currentThemeKey == key);
    return InkWell(
      onTap: () {
        _state.setTheme(key);
        setMState(() {});
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightLavender.withOpacity(0.5) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // 컬러 팔레트 스와치 3색 프리뷰
            Row(
              children: previewColors.map((c) => Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
              )).toList(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 18, color: AppColors.primaryPurple)
            else
              const Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showCustomHexColorDialog() {
    final primaryCtl = TextEditingController(text: '#541D7A');
    final bgCtl = TextEditingController(text: '#F7F3FD');
    final textCtl = TextEditingController(text: '#541D7A');
    final tintCtl = TextEditingController(text: '#EAE2FB');

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('사용자 테마 색상 직접 지정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('원하는 HEX 색상 코드를 입력하면 변수에 실시간 반영돼요.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              _buildHexField('메인 브랜드 컬러 (Primary)', primaryCtl),
              _buildHexField('앱 배경 컬러 (Background)', bgCtl),
              _buildHexField('연한 카드/틴트 배경 (Light Tint)', tintCtl),
              _buildHexField('주요 텍스트 컬러 (Text Primary)', textCtl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              try {
                final p = _parseHex(primaryCtl.text.trim());
                final b = _parseHex(bgCtl.text.trim());
                final t = _parseHex(tintCtl.text.trim());
                final txt = _parseHex(textCtl.text.trim());

                _state.setCustomTheme(
                  primary: p,
                  background: b,
                  lightTint: t,
                  textPrimary: txt,
                  warmAccent: AppColors.warmBrown,
                );
                Navigator.of(dCtx).pop();
                setState(() {});
                CelebrationToast.show(
                  context,
                  title: '커스텀 테마 적용 완료',
                  message: '지정한 색상 변수로 앱 전체가 전환되었어요.',
                );
              } catch (_) {
                CelebrationToast.show(
                  context,
                  title: '색상 코드 형식 오류',
                  message: '#RRGGBB 형식으로 입력해 주세요.',
                );
              }
            },
            child: const Text('적용하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHexField(String label, TextEditingController ctl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          TextField(
            controller: ctl,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Color _parseHex(String hex) {
    var str = hex.replaceAll('#', '');
    if (str.length == 6) {
      str = 'FF$str';
    }
    return Color(int.parse(str, radix: 16));
  }

  Widget _buildMiniThemeColorRow({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            Text(
              '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showColorPickDialog({
    required String title,
    required Color initial,
    required ValueChanged<Color> onPicked,
  }) {
    final hexCtl = TextEditingController(
      text: '#${initial.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('원하는 포인트 색상의 HEX 코드를 입력해 주세요.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: hexCtl,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: '#RRGGBB',
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const Color(0xFF7B61A8), // 라벤더 퍼플
                const Color(0xFF541D7A), // 딥 바이올렛
                const Color(0xFF8B5E3C), // 웜 브라운
                const Color(0xFFB58A32), // 더스티 오커
                const Color(0xFF4A88B8), // 소프트 데님
                const Color(0xFF557A5E), // 세이지 그린
                const Color(0xFF475569), // 슬레이트
              ].map((c) => InkWell(
                onTap: () {
                  hexCtl.text = '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black26)),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              try {
                final c = _parseHex(hexCtl.text.trim());
                onPicked(c);
                Navigator.of(dCtx).pop();
              } catch (_) {
                CelebrationToast.show(context, title: '형식 오류', message: '#RRGGBB 형식으로 입력해 주세요.');
              }
            },
            child: const Text('적용', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
