import 'dart:ui';

import 'package:flame/components.dart';

/// Fondo de circuito verde del nivel 1, si todavía no hay imagen.
class CircuitBackground extends Component with HasGameReference {
  static const _tile = 48.0;

  @override
  void render(Canvas canvas) {
    final size = game.size.toSize();
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF8FBF3A));
    final line = Paint()
      ..color = const Color(0xFF6B9A28)
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += _tile) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += _tile) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final dot = Paint()..color = const Color(0xFF4E7A18);
    for (var x = _tile / 2; x < size.width; x += _tile) {
      for (var y = _tile / 2; y < size.height; y += _tile) {
        canvas.drawCircle(Offset(x, y), 3, dot);
      }
    }
  }
}
