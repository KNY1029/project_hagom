import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';
import '../widgets/responsive_content.dart';
import 'splash_screen.dart';
import 'main_navigation_shell.dart';
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

  static const MethodChannel _exportChannel = MethodChannel(
    'com.healthpharma.hagom_app/export',
  );
  // 🔔 [알림 테스트 발송 기능]
  Future<void> _sendTestNotification() async {
    String message;
    try {
      final sent = await _exportChannel.invokeMethod<bool>(
        'showTestNotification',
      );
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
    // 📅 기본 기간: 기록 시작일부터 오늘까지 (기록 시작일이 없으면 최근 1달)
    final now = DateTime.now();
    DateTimeRange selectedRange = DateTimeRange(
      start: _state.trackingStartDate,
      end: DateTime(now.year, now.month, now.day),
    );

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
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(mCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '다운로드할 기간과 카테고리를 선택해 주세요. 각 카테고리가 깔끔하게 번호별 개별 시트(CSV) 파일로 저장돼요.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // 📅 다운로드 기간 선택 UI
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightLavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '데이터 추출 기간',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedRange.start.year}.${selectedRange.start.month.toString().padLeft(2, '0')}.${selectedRange.start.day.toString().padLeft(2, '0')} ~ ${selectedRange.end.year}.${selectedRange.end.month.toString().padLeft(2, '0')}.${selectedRange.end.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: BorderSide(color: AppColors.primaryPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: selectedRange,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryPurple,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedRange = picked);
                        }
                      },
                      child: Text(
                        '기간 변경',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 체크박스 4대 영역
              _buildCategoryCheckbox('1. 처방약 관리 데이터', includePrescription, (
                val,
              ) {
                setModalState(() => includePrescription = val ?? false);
              }),
              _buildCategoryCheckbox('2. 일반의약품 및 영양제 데이터', includeOtc, (val) {
                setModalState(() => includeOtc = val ?? false);
              }),
              _buildCategoryCheckbox('3. 작은 습관 관리 데이터', includeHabits, (val) {
                setModalState(() => includeHabits = val ?? false);
              }),
              _buildCategoryCheckbox('4. 할일 및 일정 관리 데이터', includeTasks, (val) {
                setModalState(() => includeTasks = val ?? false);
              }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      (!includePrescription &&
                          !includeOtc &&
                          !includeHabits &&
                          !includeTasks)
                      ? null
                      : () async {
                          Navigator.of(mCtx).pop();
                          await _performCsvDownload(
                            startDate: selectedRange.start,
                            endDate: selectedRange.end,
                            includePrescription: includePrescription,
                            includeOtc: includeOtc,
                            includeHabits: includeHabits,
                            includeTasks: includeTasks,
                          );
                        },
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  label: const Text(
                    '엑셀(CSV) 파일 다운로드',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCsvDownload({
    required DateTime startDate,
    required DateTime endDate,
    required bool includePrescription,
    required bool includeOtc,
    required bool includeHabits,
    required bool includeTasks,
  }) async {
    try {
      // 🌟 단일 엑셀 파일 안에 4대 카테고리가 4개의 개별 시트(Sheet)로 깔끔하게 분리되어 들어감!
      final excelBytes = _state.generateExcelWorkbook(
        startDate: startDate,
        endDate: endDate,
        includePrescription: includePrescription,
        includeOtc: includeOtc,
        includeHabits: includeHabits,
        includeTasks: includeTasks,
      );

      final now = DateTime.now();
      // 🌟 요청하신 파일명 형식: hagom_날짜_시간.xlsx (예: hagom_20261109_0015.xlsx)
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'hagom_${dateStr}_$timeStr.xlsx';
      // 안드로이드 공용 Download 폴더에 단일 엑셀 파일 다운로드
      await _exportChannel.invokeMethod<Map>('downloadExcel', {
        'fileName': fileName,
        'bytes': excelBytes,
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(
              '다운로드 완료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Text(
              '스마트폰의 [다운로드] 폴더에 하나의 엑셀 파일로 성공적으로 저장되었어요!\n\n'
              '📄 저장된 파일명:\n• $fileName\n\n'
              '📅 조회 기간: ${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} ~ ${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}\n\n'
              '📑 파일 내부 분리된 시트(Sheet) 목록:\n'
              '• 1. 처방약 관리\n'
              '• 2. 일반약 및 영양제\n'
              '• 3. 작은 습관\n'
              '• 4. 할일 및 일정\n\n'
              '엑셀(Excel)이나 한셀 앱에서 열면 하단 탭으로 시트별 데이터를 확인하실 수 있어요.',
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  // 📜 개인정보 처리방침 모달 (인앱 뷰어 + 외부 링크 열기)
  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (pCtx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.primaryPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '하곰이 개인정보 처리방침',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.of(pCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '환자 중심의 안전한 로컬 저장 솔루션 원칙',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _buildPolicySection(
                        title: '1. 수집 항목',
                        content:
                            '하곰이 앱은 유저님의 개인정보(이름, 주민번호, 연락처 등)를 절대 요구하지 않아요!\n'
                            '입력하시는 복약 정보와 생활 습관, 알림 설정 등은 오직 유저님의 스마트폰 내부(로컬)에만 안전하게 보관되며, '
                            '외부 서버로 전송되지 않습니다. 복약 데이터는 유저님이 직접 엑셀 파일로 추출하여 담당 의료진에게 자유롭게 전달하고 공유하는 안전한 시스템입니다.',
                        icon: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        title: '2. 보관 기간',
                        content:
                            '저희는 외부 서버에 개인정보를 보관하지 않습니다. '
                            '유저님이 스마트폰에서 직접 삭제하기 전까지 데이터는 앱 내부 로컬 저장소에 남아 있어요!\n'
                            '설정의 [기록 및 데이터 관리]에서 지우고 싶은 기간이나 특정 항목만 골라서 안전하게 지울 수도 있답니다.',
                        icon: Icons.history_toggle_off,
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        title: '3. 활용 목적',
                        content:
                            '저희가 유저님의 데이터를 수집한다 해도, 그걸 대체 어디에 활용할지 모르겠네요.\n'
                            '하곰이 앱은 유저님 개인의 편리한 복약과 자기 돌봄을 위한 순수한 건강 관리 서비스일 뿐입니다!',
                        icon: Icons.volunteer_activism_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        title: '4. 계정 및 데이터 삭제 방법',
                        content:
                            '계정을 만들고 로그인하는 기능은 추후 업데이트로 구현될 예정입니다. '
                            '현재 버전에서는 앱을 삭제(삭제 시 기기 내 모든 데이터 영구 소멸)하시거나, 설정 탭의 [모든 데이터 전체 초기화]를 통해 언제든 하곰이와 깨끗하게 작별할 수 있어요.',
                        icon: Icons.delete_forever_outlined,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryPurple),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            Icons.open_in_browser,
                            size: 18,
                            color: AppColors.primaryPurple,
                          ),
                          label: Text(
                            '원문 보기',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              await _exportChannel.invokeMethod('openUrl', {
                                'url': 'https://lit.link/ko/hagom',
                              });
                            } catch (_) {}
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 📖 앱 사용 가이드 모달 (요약 버전 + 처음 시작할 때처럼 화면 이동하며 체험하는 버튼 탑재)
  void _showAppGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (gCtx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.primaryPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '앱 사용 가이드 (요약본)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.of(gCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '핵심 기능 7대 포인트 한눈에 보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // 🚀 [사용자 요구 반영]: 맨 처음에 시작할 때 봤던 것처럼 직접 화면을 이동하며 체험하는 버튼!
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '처음처럼 화면 이동하며 체험하기',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '탭을 넘나들며 직접 버튼을 누르고 배우는 온보딩 가이드',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(gCtx).pop(); // 모달 닫고
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (ctx) => const MainNavigationShell(
                                startWithTutorial: true,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          '체험 시작',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: _buildUserRequestedGuideItems(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 📝 요약본 7대 항목 (간결하고 직관적인 개조식 요약본)
  List<Widget> _buildUserRequestedGuideItems() {
    return [
      _buildGuideCard(
        number: '1',
        title: '복약 관리',
        icon: Icons.medication_outlined,
        items: [
          '(1) 약 이름, 복용법 입력 (예 : 콘서타, 물과 함께 경구 복용)',
          '(2) 의사 처방 약물일 경우 체크 (아닐 경우 체크하지 않음)',
          '(3) 복용 주기와 시간 설정: 시간대 칩은 처음 누를 때 알림 시각을 설정하고 이후에는 저장된 시간이 바로 적용돼요. 오늘만은 등록한 당일에만 표시되고 다음 날 사라져요. 필요 시는 직접 삭제하기 전까지 계속 남아 있다가, 실제 복용한 때만 기록해요. 두 유형 모두 정기 복약 성공·실패와 복약 퍼센트에 포함되지 않아요.',
        ],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '2',
        title: '습관 관리',
        icon: Icons.eco_outlined,
        items: [
          '(1) 습관 이름, 작은 목표, 하루 목표 입력 (예 : 물 마시기, 1잔씩, 4회)',
          '(2) 실천 주기 설정 (옵션 : 매일, 요일 선택, 주간 횟수, 오늘만)',
          '(3) 알림 시각 지정 (직접 설정 가능) 또는 미지정 선택',
        ],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '3',
        title: '기록 달력',
        icon: Icons.calendar_month_outlined,
        items: [
          '(1) 해당 날짜의 복약 현황, 습관 현황 조회 가능',
          '(2) 하단 바의 색상 의미 :\n  • 붉은색 하단 바 - 처방약을 먹지 않았을 때\n  • 회색 하단 바 – 약(처방약 제외)이나 습관을 통틀어 하나라도 미완료일 때\n  • 초록색 하단 바 – 복약과 습관을 모두 완료했을 때',
          '(3) 오늘의 할 일 : 사용자가 별도로 추가 가능, 완료 이전에는 보라색 점이었다가 완료 후에 초록색 점으로 변환',
        ],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '4',
        title: '설정 (우측 상단 톱니바퀴)',
        icon: Icons.settings_outlined,
        items: [
          '(1) 개인 성향에 따른 맞춤 설정 : 알림 반복 빈도(최소, 기본, 적극적 3가지 모드), 각 기능에 대해 별도로 알림 on/off 가능',
          '(2) 복약 기록 다운로드 : 의료진과의 상담 등 도움, 엑셀 파일 형식, 추출할 정보 선택 가능, 저장 및 공유 기능 지원',
        ],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '5',
        title: '하곰이 (우측 상단)',
        icon: Icons.sentiment_satisfied_alt_outlined,
        items: ['(1) 짧게 누르면 : 하곰이와의 대화', '(2) 길게 누르면 : 하곰이의 방으로 이동'],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '6',
        title: '하곰이의 방',
        icon: Icons.home_outlined,
        items: [
          '(1) 하곰이, 하곰이의 위로와 응원, 누적접속일수 조회 가능',
          '(2) 하곰이와의 유대감과 성취감을 충전할 수 있는 곳',
        ],
      ),
      const SizedBox(height: 12),
      _buildGuideCard(
        number: '7',
        title: '위젯',
        icon: Icons.widgets_outlined,
        items: [
          '(1) 복약 관리, 습관 관리, 오늘의 할 일, 기록 달력 조회 가능',
          '(2) 시간 순으로 정리된 목록',
          '(3) 위젯 클릭 시 앱으로 이동',
        ],
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildGuideCard({
    required String number,
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                it,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🗑️ 데이터 기록 관리 & 선택적 삭제 모달
  void _showDataManagementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (mCtx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      '기록 및 데이터 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '탭에서 삭제한 항목은 기록 보존을 위해 과거 달력과 엑셀에 남아있습니다. 기록까지 완전히 지우려면 아래에서 선택하세요.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // 1) 특정 기간 동안의 기록 삭제
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.date_range,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '특정 기간 동안의 기록 삭제',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '원하는 시작일~종료일 사이의 복약/습관/할일 기록만 핀셋 삭제',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onTap: () {
                        Navigator.of(mCtx).pop();
                        _showDateRangeDeleteDialog();
                      },
                    ),
                    const Divider(height: 1),

                    // 2) 특정 복약/습관/할일 완전 삭제
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.checklist,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '특정 항목 영구 삭제',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '더 이상 보존하지 않을 약, 습관, 할일을 골라 기록까지 완전히 삭제',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onTap: () {
                        Navigator.of(mCtx).pop();
                        _showSpecificItemDeleteDialog();
                      },
                    ),
                    const Divider(height: 1),

                    // 3) 모든 데이터 초기화
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.missedRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_forever,
                          color: AppColors.missedRed,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '모든 데이터 전체 초기화',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.missedRed,
                        ),
                      ),
                      subtitle: Text(
                        '앱의 모든 복약, 습관, 일정 및 과거 기록을 완전히 비움',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onTap: () {
                        Navigator.of(mCtx).pop();
                        _confirmResetAllData();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🗓️ 1. 특정 기간 동안의 기록 부분 삭제 팝업
  void _showDateRangeDeleteDialog() async {
    final now = DateTime.now();
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      helpText: '삭제할 기간 선택',
      cancelText: '취소',
      confirmText: '이 기간 선택',
    );

    if (picked == null || !mounted) return;

    bool delMeds = true;
    bool delHabits = true;
    bool delTasks = true;

    showDialog(
      context: context,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final sStr =
                '${picked.start.year}.${picked.start.month}.${picked.start.day}';
            final eStr =
                '${picked.end.year}.${picked.end.month}.${picked.end.day}';

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                '기간별 기록 삭제',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.missedRed,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택한 기간: $sStr ~ $eStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '해당 기간에 기록된 데이터를 영구 삭제합니다. 삭제할 항목을 선택하세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '복약 체크 기록',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: delMeds,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (v) => setDlgState(() => delMeds = v ?? true),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '습관 실천 기록',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: delHabits,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (v) => setDlgState(() => delHabits = v ?? true),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '일정 및 할일',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: delTasks,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (v) => setDlgState(() => delTasks = v ?? true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dCtx).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.missedRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _state.deleteRecordsForDateRange(
                      startDate: picked.start,
                      endDate: picked.end,
                      deleteMeds: delMeds,
                      deleteHabits: delHabits,
                      deleteTasks: delTasks,
                    );
                    Navigator.of(dCtx).pop();
                    CelebrationToast.show(
                      context,
                      title: '기간 기록 삭제 완료',
                      message: '$sStr ~ $eStr 기록이 정리되었어요.',
                    );
                  },
                  child: const Text(
                    '삭제 확정',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🎯 2. 특정 항목 영구 삭제 (보관된 약, 습관, 할일 중 선택 삭제)
  void _showSpecificItemDeleteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sCtx) {
        return StatefulBuilder(
          builder: (ctx, setSState) {
            final allMeds = _state.allMedications;
            final allHabits = _state.allHabits;
            final allTasks = _state.allTasks;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    '특정 항목 영구 삭제',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '과거 기록까지 완전히 지울 항목의 [영구 삭제] 버튼을 누르세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        if (allMeds.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '💊 복약 목록 (${allMeds.length}개)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                          ...allMeds.map(
                            (m) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${m.name} (${m.dosage})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                m.isArchived
                                    ? '상태: 탭에서 숨김(보관됨)'
                                    : '상태: 현재 복용 중',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: m.isArchived
                                      ? Colors.orange
                                      : AppColors.successGreen,
                                ),
                              ),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.missedRed,
                                ),
                                onPressed: () {
                                  _state.permanentlyDeleteMedication(m.id);
                                  setSState(() {});
                                  CelebrationToast.show(
                                    context,
                                    title: '영구 삭제 완료',
                                    message: '\'${m.name}\' 기록이 완전히 삭제되었어요.',
                                  );
                                },
                                child: const Text(
                                  '영구 삭제',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (allHabits.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '🌱 습관 목록 (${allHabits.length}개)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                          ...allHabits.map(
                            (h) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                h.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                h.isArchived
                                    ? '상태: 탭에서 숨김(보관됨)'
                                    : '상태: 현재 실천 중',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: h.isArchived
                                      ? Colors.orange
                                      : AppColors.successGreen,
                                ),
                              ),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.missedRed,
                                ),
                                onPressed: () {
                                  _state.permanentlyDeleteHabit(h.id);
                                  setSState(() {});
                                  CelebrationToast.show(
                                    context,
                                    title: '영구 삭제 완료',
                                    message: '\'${h.title}\' 기록이 완전히 삭제되었어요.',
                                  );
                                },
                                child: const Text(
                                  '영구 삭제',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (allTasks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '🗓️ 할일 목록 (${allTasks.length}개)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFB58A32),
                              ),
                            ),
                          ),
                          ...allTasks.map(
                            (t) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                t.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${t.date.year}.${t.date.month}.${t.date.day} · ${t.isArchived ? "보관됨" : (t.isCompleted ? "완료" : "대기")}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.missedRed,
                                ),
                                onPressed: () {
                                  _state.permanentlyDeleteTask(t.id);
                                  setSState(() {});
                                  CelebrationToast.show(
                                    context,
                                    title: '영구 삭제 완료',
                                    message: '\'${t.title}\' 할일이 완전히 삭제되었어요.',
                                  );
                                },
                                child: const Text(
                                  '영구 삭제',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ⚠️ 전체 데이터 초기화 다이얼로그
  void _confirmResetAllData() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(
          '모든 데이터 초기화',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.missedRed,
          ),
        ),
        content: Text(
          '등록된 모든 복약, 습관, 일정 및 과거 기록이 완전히 삭제되고 초기 상태로 되돌아갑니다. 정말 초기화할까요?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
            child: Text(
              '초기화 확정',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 🐻 상단 하곰이 마스코트 프로필 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
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
                        '정신약학 맞춤 복약 솔루션 · v1.08.311',
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  // 1) 알림 빈도 강도 조절 (최소 / 기본 / 적극적)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '알림 반복 빈도',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _state.notificationFrequency,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _state.notificationFrequency == '최소'
                              ? '직접 계획한 실천사항을 시간에 맞춰 안내해요!'
                              : (_state.notificationFrequency == '기본'
                                    ? '실천 알림에 더해, 하곰이가 종종 말을 걸어와요!'
                                    : '하곰이의 밀착 케어! 스파르타식 관리를 받아요!'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: ['최소', '기본', '적극적'].map((freq) {
                            final isSel = _state.notificationFrequency == freq;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Center(child: Text(freq)),
                                  selected: isSel,
                                  showCheckmark: false,
                                  selectedColor: AppColors.lightLavender,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSel
                                        ? AppColors.primaryPurple
                                        : AppColors.textSecondary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSel
                                          ? AppColors.primaryPurple
                                          : AppColors.divider,
                                    ),
                                  ),
                                  onSelected: (val) {
                                    if (val)
                                      _state.setNotificationFrequency(freq);
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    title: Text(
                      '복약 알림',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      _state.medsNotificationEnabled
                          ? '일반약 및 필수 처방약 알림 수신 중'
                          : '일반약 알림 OFF (처방약은 안전을 위해 켜짐 유지)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _state.medsNotificationEnabled
                            ? AppColors.textSecondary
                            : AppColors.missedRed,
                      ),
                    ),
                    value: _state.medsNotificationEnabled,
                    onChanged: (val) {
                      if (!val) {
                        // 처방약 보호 안내 다이얼로그
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              '복약 알림 안내',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              '일반약 알림만 꺼지며, 처방약은 안전을 위해 켜짐이 유지돼요.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _state.setMedsNotification(false);
                                },
                                child: Text(
                                  '확인',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    title: Text(
                      '작은 습관 알림',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '물 마시기, 산책 등 데일리 루틴 실천 리마인드',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _state.habitNotificationEnabled,
                    onChanged: (val) => _state.setHabitNotification(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),

                  // 4) 🗓️ 할일 및 일정 알림
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    title: Text(
                      '일정 및 할일 알림',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '병원 예약, 과제 마감 등 등록된 일정 사전 알림',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _state.tasksNotificationEnabled,
                    onChanged: (val) => _state.setTasksNotification(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),

                  // 5) 🐻 하곰이 응원 및 넛지 알림
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    title: Text(
                      '하곰이 따뜻한 응원 알림',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '다정한 힐링과 응원의 한마디',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _state.mascotNotificationEnabled,
                    onChanged: (val) => _state.setMascotNotification(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),

                  // 🌟 [완료 기록 안내 팝업(토스트) 켜기/끄기 스위치]
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    title: Text(
                      '기록 완료 안내 팝업 켜기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '복약·습관·할 일 기록 완료 시 하단에 뜨는 축하 안내 팝업을 표시해요',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _state.completionFeedbackEnabled,
                    onChanged: (val) =>
                        _state.setCompletionFeedbackEnabled(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),

                  // 🌟 [알림 테스트 (개발자 모드용)]
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 테스트 (개발자)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '실제 기기에 하곰이 테스트 푸시 알림을 한 번 보냅니다.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _sendTestNotification,
                          icon: Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primaryPurple,
                          ),
                          label: Text(
                            '테스트 알림 보내기',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '올클리어 축하 오버레이 시안 프리뷰 (개발자)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '기존에 제작된 11가지 축하 오버레이 시안(0안~5안)을 직접 둘러봅니다.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                          icon: Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryPurple,
                          ),
                          label: Text(
                            '축하 오버레이 11종 시안 둘러보기',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  // 6) 🎨 적록색맹 보조 색상 모드
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    activeThumbColor: AppColors.primaryPurple,
                    secondary: Icon(
                      Icons.visibility_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '적록색맹 보조 색상 모드',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '완료·성공 색상은 파랑으로, 경고·미완료 색상은 노랑으로 표시해요',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _state.colorVisionModeEnabled,
                    onChanged: (val) => _state.setColorVisionMode(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  // 6) ☀️ 하루 갱신 기준 시각 (기본 오전 8:00)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '하루 갱신 기준 시각',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '매일 ${_state.dailyResetTimeString} 기준 새 하루가 시작돼요',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _state.dailyResetTimeString,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final currentTime = TimeOfDay(
                        hour: _state.dailyResetHour,
                        minute: _state.dailyResetMinute,
                      );
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
                          message:
                              '하루 갱신 기준 시각이 ${_state.dailyResetTimeString}으로 설정되었어요.',
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '개인정보 처리방침',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '수집 항목, 보관 기간 및 활용 목적 안내',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: _showPrivacyPolicyModal,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.help_outline,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '앱 사용 가이드 다시 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '핵심 요약 가이드 및 화면 이동 체험 가이드',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: _showAppGuideModal,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.widgets_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '스마트폰 홈 위젯 쇼룸',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '2×1 마스코트 4대 감정 및 1-Tap 즉시 체크 위젯 시뮬레이터',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const WidgetSimulatorScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.celebration_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '일일 첫 접속 환영 애니메이션 다시 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '하곰이 출석 지지 환영 GIF 전체 화면 체험',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) =>
                              const SplashScreen(forceGreetingPreview: true),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.medication_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '복약 올클리어 축하 애니메이션 미리보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '오늘 복약 100% 달성 시 플로팅 축하 오버레이 팝업',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: AppColors.primaryPurple,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.favorite_border,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '습관 올클리어 축하 애니메이션 미리보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '오늘 습관 100% 달성 시 플로팅 축하 오버레이 팝업',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: AppColors.primaryPurple,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.table_view_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '복약 기록 엑셀(CSV) 다운로드',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '의료진 진료 상담용 스프레드시트 파일 저장',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: _exportMedicalCsv,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.restart_alt_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      '시작 모드 선택 초기화',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '앱을 다시 열었을 때 시작 모드(바로 시작/온보딩/개발자) 선택창 다시 띄우기',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.missedRed,
                    ),
                    title: Text(
                      '기록 및 데이터 관리 (선택/전체 삭제)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.missedRed,
                      ),
                    ),
                    subtitle: Text(
                      '기간별 기록 삭제, 특정 항목 영구 삭제, 전체 초기화',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: _showDataManagementModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
