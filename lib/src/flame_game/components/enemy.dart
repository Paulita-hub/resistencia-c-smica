import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';
import 'solid_block.dart';

class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  Enemy({required Vector2 position})
    : super(
        position: position,
        size: Vector2(48, 40),
        anchor: Anchor.bottomLeft,
      );

  static const speed = 70.0;
  double direction = 1;
  bool stomped = false;
  Sprite? sprite;

  @override
  Future<void> onLoad() async {
    final folder = 'levels/${game.level.number}';
    sprite = await game.trySprite('$folder/enemy.png');
    await add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    if (stomped) return;

    position.x += direction * speed * dt;

    final ahead = Vector2(
      direction > 0 ? position.x + size.x + 2 : position.x - 2,
      position.y + 4,
    );
    final groundAhead = Vector2(
      direction > 0 ? position.x + size.x - 6 : position.x + 6,
      position.y + 8,
    );

    var wall = false;
    var floor = false;
    for (final block in game.world.children.whereType<SolidBlock>()) {
      final rect = block.toAbsoluteRect();
      if (rect.contains(ahead.toOffset())) wall = true;
      if (rect.contains(groundAhead.toOffset())) floor = true;
    }
    if (wall || !floor) {
      direction *= -1;
    }
  }

  void stomp() {
    stomped = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      canvas.save();
      if (direction < 0) {
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      sprite!.render(canvas, size: size);
      canvas.restore();
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 8, size.x, size.y - 8),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF9B2226),
    );
  }
}
