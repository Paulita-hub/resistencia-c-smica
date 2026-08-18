import 'dart:ui';

import 'package:flame/components.dart';

/// Escala por alto (sin deformar) y dibuja copias completas, sin recortar.
void renderFloorSprite(Canvas canvas, Sprite sprite, Vector2 size) {
  final image = sprite.image;
  final srcW = image.width.toDouble();
  final srcH = image.height.toDouble();
  if (srcW <= 0 || srcH <= 0 || size.x <= 0 || size.y <= 0) return;

  final destH = size.y;
  final destW = destH * (srcW / srcH);
  final paint = Paint()..filterQuality = FilterQuality.none;

  var x = 0.0;
  while (x < size.x - 0.5) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, srcW, srcH),
      Rect.fromLTWH(x, 0, destW, destH),
      paint,
    );
    x += destW;
  }
}

/// Una sola copia, centrada, sin deformar. Puede dibujar fuera del componente.
void renderCenteredFloorSprite(Canvas canvas, Sprite sprite, Vector2 size) {
  final image = sprite.image;
  final srcW = image.width.toDouble();
  final srcH = image.height.toDouble();
  if (srcW <= 0 || srcH <= 0 || size.y <= 0) return;

  final destH = size.y;
  final destW = destH * (srcW / srcH);
  final ox = (size.x - destW) / 2;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, srcW, srcH),
    Rect.fromLTWH(ox, 0, destW, destH),
    Paint()..filterQuality = FilterQuality.none,
  );
}
