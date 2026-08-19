import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';

class Goal extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  Goal({required Vector2 position})
    : super(
        position: position,
        size: Vector2(48, 96),
        anchor: Anchor.bottomCenter,
      );

  Sprite? sprite;

  @override
  Future<void> onLoad() async {
    if (game.level.number == 3) {
      sprite = await game.trySprite('levels/3/libra_corp.png') ??
          await game.trySprite('items/libra_corp.png');
      if (sprite != null) {
        final src = sprite!.srcSize;
        size = Vector2(78, 78 * src.y / src.x);
      }
    } else {
      sprite = await game.trySprite('items/goal.png');
    }
    await add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      sprite!.render(canvas, size: size);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 4, 0, 8, size.y),
      Paint()..color = const Color(0xFFE0E1DD),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, 36),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF7B2CBF),
    );
  }
}
