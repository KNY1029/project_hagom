import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 🌟 [슬림 세로 2단 스와이프 액션 카드]
/// 
/// 1. 버튼 크기는 원래의 넉넉한 크기(72dp)로 유지하여 글자/아이콘이 완벽한 정중앙에 위치!
/// 2. 밀리는 범위만 56dp로 제한하여 카드가 과하게 밀리지 않음!
/// 3. 되돌리기 쪽 틈새 색상 분리:
///    - 위쪽 틈새는 수정 색상(슬레이트 블루), 아래쪽 틈새는 되돌리기 색상(웜브라운)으로
///      각 버튼의 색이 그대로 안쪽까지 이어져 틈새 색상이 어색하게 섞이지 않음!
class SwipeableActionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback? onRevert;
  final double buttonWidth;
  final double maxDragLimit;

  const SwipeableActionCard({
    super.key,
    required this.child,
    required this.onEdit,
    this.onRevert,
    this.buttonWidth = 72.0,    // 넉넉한 버튼 본체 크기 (글자가 중앙에 오도록)
    this.maxDragLimit = 56.0,   // 카드가 밀리는 최대 범위 (과하게 밀리지 않게 제한!)
  });

  @override
  State<SwipeableActionCard> createState() => _SwipeableActionCardState();
}

class _SwipeableActionCardState extends State<SwipeableActionCard> {
  double _dragOffset = 0.0;
  bool _isOpen = false;

  static const Color _editBtnColor = Color(0xFF475569); // 세련된 딥 슬레이트 블루

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset < -widget.maxDragLimit) {
        _dragOffset = -widget.maxDragLimit;
      } else if (_dragOffset > 0) {
        _dragOffset = 0;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      if (_dragOffset < -(widget.maxDragLimit * 0.4)) {
        _dragOffset = -widget.maxDragLimit;
        _isOpen = true;
      } else {
        _dragOffset = 0.0;
        _isOpen = false;
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _dragOffset = 0.0;
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDraggingOrOpen = _dragOffset < -1 || _isOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // 🛡️ [뒤쪽 세로 2단 액션 바]
          if (isDraggingOrOpen)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: widget.buttonWidth + 16, // 모서리 틈새를 커버하도록 안쪽으로 연장
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 위쪽: [✏️ 수정] 영역 (틈새까지 슬레이트 블루로 일체형)
                      Expanded(
                        child: Material(
                          color: _editBtnColor,
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                          child: InkWell(
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                            onTap: () {
                              _close();
                              widget.onEdit();
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6.0), // 살짝 오른쪽으로 미세 이동!
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '수정',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 구분선
                      if (widget.onRevert != null)
                        Container(height: 1, color: Colors.white.withOpacity(0.2)),

                      // 2. 아래쪽: [↩️ 되돌리기] 영역 (틈새까지 웜브라운으로 일체형!)
                      if (widget.onRevert != null)
                        Expanded(
                          child: Material(
                            color: AppColors.warmBrown,
                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                            child: InkWell(
                              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                              onTap: () {
                                _close();
                                widget.onRevert!();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 6.0), // 살짝 오른쪽으로 미세 이동!
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.undo, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '되돌리기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                  ),
                ),
              ),
            ),

          // 🎴 [앞쪽 카드 본체]
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: _isOpen ? _close : null,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
