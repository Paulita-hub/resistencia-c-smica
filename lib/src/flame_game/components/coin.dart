import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_layout.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';
import 'medialuna_flash.dart';

class Coin extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  Coin({required Vector2 position})
    : super(
        position: position,
        size: Vector2(GameLayout.coinWidth, GameLayout.coinWidth * 0.6),
        anchor: Anchor.center,
      );

  double _t = 0;
  Sprite? sprite;
  bool _eaten = false;

  double get _width => GameLayout.coinWidthFor(game.level.number);

  @override
  Future<void> onLoad() async {
    await _loadSprite();
    await add(
      RectangleHitbox.relative(
        Vector2(1.35, 1.45),
        parentSize: size,
        position: Vector2(-size.x * 0.175, -size.y * 0.225),
        collisionType: CollisionType.passive,
      ),
    );
  }

  Future<void> _loadSprite() async {
    sprite =
        await game.trySprite('items/food.png') ??
        await game.trySprite('items/star.png');
    final w = _width;
    if (sprite != null) {
      final src = sprite!.srcSize;
      size = Vector2(w, w * src.y / src.x);
    } else {
      size = Vector2(w, w * 0.6);
    }
  }

  void eat() {
    if (_eaten) return;
    _eaten = true;
    game.world.add(
      MedialunaFlash(position: absoluteCenter.clone(), food: sprite),
    );
    game.collectCoin();
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.started) return;
    _t += dt * 6;
    position.y += sin(_t) * 24 * dt;
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      sprite!.render(canvas, size: size);
      return;
    }
    final path = Path()
      ..moveTo(2, size.y * 0.55)
      ..quadraticBezierTo(size.x * 0.25, 0, size.x * 0.5, 4)
      ..quadraticBezierTo(size.x * 0.75, 0, size.x - 2, size.y * 0.55)
      ..quadraticBezierTo(size.x * 0.5, size.y * 0.35, 2, size.y * 0.55);
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8A0B8));
  }
}
