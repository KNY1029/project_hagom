import 'package:flutter/material.dart';

/// 넓은 화면에서도 카드와 텍스트가 과하게 퍼지지 않도록 콘텐츠 폭을 제한한다.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContent({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
