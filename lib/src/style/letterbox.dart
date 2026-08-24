import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Encaja un arte de diseño fijo cubriendo toda la pantalla (recorta bordes).
class LetterboxFrame {
  const LetterboxFrame({
    required this.scale,
    required this.offset,
    required this.drawn,
  });

  final double scale;
  final Offset offset;
  final Size drawn;

  Rect map(Rect design) => Rect.fromLTWH(
    offset.dx + design.left * scale,
    offset.dy + design.top * scale,
    design.width * scale,
    design.height * scale,
  );

  static LetterboxFrame of(Size viewport, Size design) {
    final scale = math.max(
      viewport.width / design.width,
      viewport.height / design.height,
    );
    final drawn = Size(design.width * scale, design.height * scale);
    return LetterboxFrame(
      scale: scale,
      offset: Offset(
        (viewport.width - drawn.width) / 2,
        (viewport.height - drawn.height) / 2,
      ),
      drawn: drawn,
    );
  }
}
