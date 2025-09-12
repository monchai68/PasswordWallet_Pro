import 'package:flutter/widgets.dart';

class CustomRefreshIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const CustomRefreshIcon({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/refresh_icon.png', // Update this path if needed
      width: size,
      height: size,
      color: color,
    );
  }
}
