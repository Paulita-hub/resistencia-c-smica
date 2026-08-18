import 'dart:ui';

import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Piso continuo: cada `ground.png` se dibuja entero, sin recortar.
class GroundLayer extends PositionComponent
    with HasGameReference<ResistenciaGame> {
  GroundLayer({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        anchor: Anchor.topLeft,
        priority: 2,
      );

  @override
  Future<void> onLoad() async {
    final sprite =
        await game.trySprite('levels/${game.level.number}/ground.png') ??
        await game.trySprite('levels/1/ground.png');
    if (sprite == null) {
      add(_SolidFloorFallback(size: size));
      return;
    }

    final image = sprite.image;
    final destH = size.y;
    final destW = destH * image.width / image.height;
    var x = 0.0;
    while (x < size.x) {
      add(
        SpriteComponent(
          sprite: sprite,
          position: Vector2(x, 0),
          size: Vector2(destW, destH),
          anchor: Anchor.topLeft,
        )..paint.filterQuality = FilterQuality.none,
      );
      x += destW;
    }
  }
}

class _SolidFloorFallback extends PositionComponent {
  _SolidFloorFallback({required super.size});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF8B6914));
  }
}
