import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';
import 'chainsaw_monster.dart';

/// Nube de aerosol que apunta sola al monstruo.
class AerosolBurst extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  AerosolBurst({required Vector2 position, required Vector2 dir})
    : dir = dir.clone(),
      super(
        position: position,
        size: Vector2(110, 82),
        anchor: Anchor.centerLeft,
        priority: 18,
      );

  final Vector2 dir;
  final frames = <Sprite>[];
  double _life = 2.8;
  double _t = 0;
  bool _spent = false;

  @override
  Future<void> onLoad() async {
    for (var i = 1; i <= 3; i++) {
      final frame =
          await game.trySprite('items/aerosol_$i.png') ??
          await game.trySprite('levels/3/aerosol_$i.png');
      if (frame != null) frames.add(frame);
    }
    if (frames.isEmpty) {
      final fallback =
          await game.trySprite('items/aerosol.png') ??
          await game.trySprite('levels/3/aerosol.png');
      if (fallback != null) frames.add(fallback);
    }
    if (frames.isNotEmpty) {
      final src = frames.first.srcSize;
      size = Vector2(120, 120 * src.y / src.x);
    }
    await add(RectangleHitbox.relative(Vector2(1, 1), parentSize: size));
    _faceDir();
  }

  Sprite? get _sprite {
    if (frames.isEmpty) return null;
    final i = (_t / 0.16).floor().clamp(0, frames.length - 1);
    return frames[i];
  }

  void _home(double dt) {
    ChainsawMonster? monster;
    for (final child in game.world.children.whereType<ChainsawMonster>()) {
      monster = child;
      break;
    }
    if (monster == null || !monster.appeared || monster.dying) return;
    final to = monster.position - position;
    if (to.length2 < 4) return;
    to.normalize();
    dir.setFrom(to);
    if (dir.length2 > 0.001) dir.normalize();
    _faceDir();
  }

  void _faceDir() {
    // El sprite sale hacia arriba-derecha; alineamos ese eje al monstruo.
    angle = atan2(dir.y, dir.x) - atan2(-0.35, 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _home(dt);
    position += dir * 480 * dt;
    size += Vector2.all(28 * dt);
    _life -= dt;
    _tryHitMonster();
    if (_life <= 0) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ChainsawMonster) {
      _impact(other);
    }
  }

  void _tryHitMonster() {
    if (_spent) return;
    for (final monster in game.world.children.whereType<ChainsawMonster>()) {
      if (!monster.appeared || monster.dying) continue;
      if (position.distanceTo(monster.position) < monster.size.x * 0.7) {
        _impact(monster);
        return;
      }
    }
  }

  void _impact(ChainsawMonster monster) {
    if (_spent || monster.dying) return;
    _spent = true;
    monster.stun();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return;
    final src = sprite.srcSize;
    final destH = size.x * src.y / src.x;
    sprite.render(
      canvas,
      size: Vector2(size.x, destH),
      overridePaint: Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..color = const Color.fromRGBO(255, 220, 245, 0.82),
    );
    final mist = Paint()
      ..isAntiAlias = false
      ..color = const Color.fromRGBO(255, 160, 230, 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.55, destH * 0.45),
        width: size.x * 0.9,
        height: destH * 0.7,
      ),
      mist,
    );
  }
}
