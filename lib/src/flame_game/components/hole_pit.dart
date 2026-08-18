import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';
import 'floor_sprite.dart';

/// Hueco con piso roto: se ve la grieta real, no un sprite estirado.
class HolePit extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  HolePit({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        anchor: Anchor.topLeft,
        priority: 3,
      );

  Sprite? sprite;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    unawaited(_loadSprite());
  }

  Future<void> _loadSprite() async {
    sprite = await game.trySprite('levels/${game.level.number}/broken.png');
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF050508));
    if (sprite != null) {
      renderCenteredFloorSprite(canvas, sprite!, size);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.28, 0, size.x * 0.44, size.y),
      Paint()..color = const Color(0xFF050508),
    );
  }
}
