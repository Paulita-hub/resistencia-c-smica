import 'package:flutter/material.dart';

import 'pressable.dart';

class JugarButton extends StatelessWidget {
  const JugarButton({required this.onPressed, this.height = 55, super.key});

  static const asset = 'assets/images/ui/button_jugar.png';
  static const srcSize = Size(381, 142);

  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * srcSize.width / srcSize.height;
    return Pressable(
      onPressed: onPressed,
      child: Semantics(
        button: true,
        label: 'Jugar',
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
