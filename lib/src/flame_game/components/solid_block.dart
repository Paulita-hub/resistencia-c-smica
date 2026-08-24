import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_layout.dart';
import '../level_maps.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';

class SolidBlock extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  SolidBlock({
    required Vector2 position,
    required Vector2 size,
    this.platform = false,
    this.oneWay = false,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.topLeft,
         priority: 2,
       );

  final bool platform;
  /// If true, you can jump through from below. Level 1 platforms are solid.
  final bool oneWay;
  Sprite? sprite;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    unawaited(_loadSprite());
  }

  Future<void> _loadSprite() async {
    if (!platform) return;
    final loaded = await game.trySprite(
      'levels/${game.level.number}/platform.png',
    );
    if (loaded == null) return;
    final src = loaded.srcSize;
    final tile = LevelMaps.tileSize;
    final fitted = src.y * (tile / src.x);
    size = Vector2(
      size.x,
      fitted < GameLayout.platformMinHeight
          ? GameLayout.platformMinHeight
          : fitted,
    );
    sprite = loaded;
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      sprite!.render(canvas, size: size);
      return;
    }
    if (!platform) return;
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFF9B8EC4),
    );
  }
}
