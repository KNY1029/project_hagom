import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import 'splash_screen.dart';
import 'widget_simulator_screen.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/hagom_celebration_overlay.dart';
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
  // 🔔 [알림 테스트 발송 기능]
  Future<void> _sendTestNotification() async {
    String message;
    try {
      final sent = await _exportChannel.invokeMethod<bool>('showTestNotification');
      message = sent == true
          ? '테스트 알림을 보냈어요.'
          : '알림 권한이 꺼져 있어요. 권한을 허용한 뒤 다시 눌러 주세요.';
    } on PlatformException catch (error) {
      message = '테스트 알림을 보내지 못했어요: ${error.message ?? error.code}';
    } on MissingPluginException {
      message = '이 기기에서는 알림 테스트를 지원하지 않아요.';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
                color: Colors.black.withValues(alpha: 0.12),
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
                  Text(
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
              Text(
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
                          );
                        },
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 19),
                  label: const Text(
                    '엑셀(CSV) 파일 다운로드',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
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
                style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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

      // 안드로이드 공용 Download 폴더에 실제 다운로드
      await _exportChannel.invokeMethod<Map>('downloadCsv', {
        'fileName': fileName,
        'content': csvContent,
      });
        if (mounted) {
          showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: Text('다운로드 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  child: Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
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
        title: Text('모든 데이터 초기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.missedRed)),
        content: Text(
          '등록된 모든 복약, 습관, 일정 기록이 완전히 삭제되고 초기 상태로 되돌아갑니다. 정말 초기화할까요?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
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
            child: Text('초기화 확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
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
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
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
                Column(
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
                      '정신약학 비처벌 복약 솔루션 · v0.90.207',
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
          Padding(
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
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
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
                          Text('알림 반복 빈도', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(_state.notificationFrequency, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
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
                  activeThumbColor: AppColors.primaryPurple,
                  title: Text('복약 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                          title: Text('복약 알림 안내', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          content: Text(
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
                              child: Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  activeThumbColor: AppColors.primaryPurple,
                  title: Text('작은 습관 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('물 마시기, 산책 등 데일리 루틴 실천 리마인드', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.habitNotificationEnabled,
                  onChanged: (val) => _state.setHabitNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 4) 🗓️ 할일 및 일정 알림
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeThumbColor: AppColors.primaryPurple,
                  title: Text('일정 및 할일 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('병원 예약, 과제 마감 등 등록된 일정 사전 알림', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.tasksNotificationEnabled,
                  onChanged: (val) => _state.setTasksNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 5) 🐻 하곰이 응원 및 넛지 알림
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeThumbColor: AppColors.primaryPurple,
                  title: Text('하곰이 따뜻한 응원 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('비처벌적 힐링과 응원의 한마디', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.mascotNotificationEnabled,
                  onChanged: (val) => _state.setMascotNotification(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 🌟 [완료 기록 안내 팝업(토스트) 켜기/끄기 스위치]
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  activeThumbColor: AppColors.primaryPurple,
                  title: Text('기록 완료 안내 팝업 켜기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('복약·습관·할 일 기록 완료 시 하단에 뜨는 축하 안내 팝업을 표시해요', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: _state.completionFeedbackEnabled,
                  onChanged: (val) => _state.setCompletionFeedbackEnabled(val),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),

                // 🌟 [알림 테스트 (개발자 모드용)]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('알림 테스트 (개발자)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('실제 기기에 하곰이 테스트 푸시 알림을 한 번 보냅니다.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: Icon(Icons.notifications_active_outlined, color: AppColors.primaryPurple),
                        label: Text('테스트 알림 보내기', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('올클리어 축하 오버레이 시안 프리뷰 (개발자)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('기존에 제작된 11가지 축하 오버레이 시안(0안~5안)을 직접 둘러봅니다.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          HagomCelebrationOverlay.show(
                            context,
                            assetPath: AppAssets.medsAllDoneWebp,
                            title: '오늘의 복약 완료!',
                            subtitle: '하곰이가 정성껏 준비한 응원이에요',
                            isDevPreview: true,
                          );
                        },
                        icon: Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
                        label: Text('축하 오버레이 11종 시안 둘러보기', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                // 6) ☀️ 하루 갱신 기준 시각 (기본 오전 8:00)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.wb_sunny_outlined, color: AppColors.primaryPurple),
                  title: Text('하루 갱신 기준 시각', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text(
                    '매일 ${_state.dailyResetTimeString} 기준 새 하루가 시작돼요',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightLavender,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _state.dailyResetTimeString,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
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
          Padding(
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
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.help_outline, color: AppColors.primaryPurple),
                  title: Text('앱 사용 가이드 다시 보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('처음 시작했을 때 보여줬던 가이드', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (gCtx) => const SplashScreen(forceGreetingPreview: true),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.widgets_outlined, color: AppColors.primaryPurple),
                  title: Text('스마트폰 홈 위젯 쇼룸', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('2×1 마스코트 4대 감정 및 1-Tap 즉시 체크 위젯 시뮬레이터', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
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
                  leading: Icon(Icons.celebration_outlined, color: AppColors.primaryPurple),
                  title: Text('일일 첫 접속 환영 애니메이션 다시 보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('하곰이 출석 지지 환영 GIF 전체 화면 체험', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
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
                  leading: Icon(Icons.medication_outlined, color: AppColors.primaryPurple),
                  title: Text('복약 올클리어 축하 애니메이션 미리보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('오늘 복약 100% 달성 시 플로팅 축하 오버레이 팝업', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: Icon(Icons.play_circle_outline, size: 20, color: AppColors.primaryPurple),
                  onTap: () {
                    HagomCelebrationOverlay.show(
                      context,
                      assetPath: AppAssets.medsAllDoneWebp,
                      title: '오늘 복약 모두 완료!',
                      subtitle: '정말 대단해요! 오늘 복약을 전부 챙기셨어요.',
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.favorite_border, color: AppColors.primaryPurple),
                  title: Text('습관 올클리어 축하 애니메이션 미리보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('오늘 습관 100% 달성 시 플로팅 축하 오버레이 팝업', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: Icon(Icons.play_circle_outline, size: 20, color: AppColors.primaryPurple),
                  onTap: () {
                    HagomCelebrationOverlay.show(
                      context,
                      assetPath: AppAssets.habitsAllDoneWebp,
                      title: '오늘 습관 모두 실천 완료!',
                      subtitle: '스스로와의 약속을 멋지게 지켜내셨어요.',
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.table_view_outlined, color: AppColors.primaryPurple),
                  title: Text('복약 기록 엑셀(CSV) 다운로드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('의료진 진료 상담용 스프레드시트 파일 저장', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: _exportMedicalCsv,
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.restart_alt_outlined, color: AppColors.primaryPurple),
                  title: Text('시작 모드 선택 초기화', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Text('앱을 다시 열었을 때 시작 모드(바로 시작/온보딩/개발자) 선택창 다시 띄우기', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
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
                  title: Text('모든 데이터 초기화', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.missedRed)),
                  subtitle: Text('복약, 습관, 일정 기록을 모두 비우고 초기화', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
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