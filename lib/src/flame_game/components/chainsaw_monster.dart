import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Monstruo del nivel 3: flota y dispara un láser con la motosierra.
class ChainsawMonster extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  ChainsawMonster()
    : super(
        size: Vector2(120, 100),
        anchor: Anchor.center,
        priority: 16,
      );

  static const appearDelay = 2.2;
  static const _muzzle = Offset(0.78, 0.58);

  Sprite? idle;
  final attackFrames = <Sprite>[];
  double _bob = 0;
  double _alive = 0;
  double _phaseT = 0;
  double _animT = 0;
  double _stunT = 0;
  bool _firing = false;
  bool _hitThisPulse = false;
  bool dying = false;
  Vector2? _lockedAim;

  bool get appeared => game.started && _alive >= appearDelay;
  bool get firing => _firing && appeared && _stunT <= 0 && !dying;

  void stun() {
    if (dying) return;
    _stunT = 1.4;
    _firing = false;
    _phaseT = 0;
  }

  void defeat() {
    dying = true;
    _firing = false;
    _stunT = 0;
  }

  @override
  Future<void> onLoad() async {
    idle = await game.trySprite('levels/3/monster_1.png');
    for (var i = 2; i <= 3; i++) {
      final frame = await game.trySprite('levels/3/monster_$i.png');
      if (frame != null) attackFrames.add(frame);
    }
    await add(CircleHitbox());
    _layout();
  }

  void _layout() {
    final sprite = _sprite;
    if (sprite == null) return;
    final src = sprite.srcSize;
    const h = 200.0;
    size = Vector2(h * src.x / src.y, h);
  }

  Sprite? get _sprite {
    if (_firing && attackFrames.isNotEmpty && _stunT <= 0) {
      final i = (_animT / 0.14).floor() % attackFrames.length;
      return attackFrames[i];
    }
    return idle ?? (attackFrames.isEmpty ? null : attackFrames.first);
  }

  Offset get muzzlePoint {
    return Offset(
      position.x - size.x / 2 + size.x * _muzzle.dx,
      position.y - size.y / 2 + size.y * _muzzle.dy,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt;
    if (dying) {
      position.y += 260 * dt;
      if (position.y > game.mapSize.y + 90) {
        removeFromParent();
      }
      return;
    }
    _placeInView();
    _layout();

    if (!game.started || game.finished || game.gameOver) {
      _firing = false;
      if (!game.started) {
        _alive = 0;
        _phaseT = 0;
      }
      return;
    }

    _alive += dt;
    if (!appeared) return;
    if (_stunT > 0) {
      _stunT -= dt;
      _firing = false;
      return;
    }

    _phaseT += dt;
    if (_firing) {
      _animT += dt;
      _tryHitPlayer();
      if (_phaseT >= 0.7) {
        _firing = false;
        _phaseT = 0;
        _hitThisPulse = false;
      }
    } else if (_phaseT >= 2.4) {
      _firing = true;
      _phaseT = 0;
      _animT = 0;
      _hitThisPulse = false;
      _lockAim();
    }
  }

  void _placeInView() {
    final zoom = game.camera.viewfinder.zoom;
    if (zoom <= 0 || zoom.isNaN) return;
    final viewW = game.viewWidth / zoom;
    final camX = game.camera.viewfinder.position.x;
    final t = _bob;
    position.x = camX + viewW * 0.74 + sin(t * 0.9) * 16;
    position.y = game.mapSize.y * 0.42 + cos(t * 1.1) * 14;
  }

  void _lockAim() {
    final p = game.player;
    _lockedAim = Vector2(
      p.position.x + p.size.x * 0.4,
      p.position.y - p.size.y * 0.5,
    );
  }

  Vector2 get muzzleVector => Vector2(
    position.x - size.x / 2 + size.x * _muzzle.dx,
    position.y - size.y / 2 + size.y * _muzzle.dy,
  );

  void _tryHitPlayer() {
    if (_hitThisPulse || game.player.invulnerableTime > 0) return;
    if (game.player.fallingOut) return;
    final aim = _lockedAim;
    if (aim == null) return;
    final p = game.player;
    final chest = Vector2(
      p.position.x + p.size.x * 0.4,
      p.position.y - p.size.y * 0.5,
    );
    if (_distanceToSegment(muzzleVector, aim, chest) < 44) {
      _hitThisPulse = true;
      game.laserHitPlayer();
    }
  }

  double _distanceToSegment(Vector2 a, Vector2 b, Vector2 p) {
    final ab = b - a;
    final len2 = ab.length2;
    if (len2 < 0.001) return p.distanceTo(a);
    final t = ((p - a).dot(ab) / len2).clamp(0.0, 1.0);
    return p.distanceTo(a + ab * t);
  }

  @override
  void render(Canvas canvas) {
    if (!appeared) return;
    final sprite = _sprite;
    if (sprite == null) return;
    final fade = ((_alive - appearDelay) / 0.35).clamp(0.0, 1.0);
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (fade < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, fade);
    }
    sprite.render(canvas, size: size, overridePaint: paint);

    if (!firing || game.finished) return;
    final from = Offset(size.x * _muzzle.dx, size.y * _muzzle.dy);
    final aim = _lockedAim ?? Vector2(
      game.player.position.x + game.player.size.x * 0.4,
      game.player.position.y - game.player.size.y * 0.5,
    );
    final target = Offset(
      aim.x - (position.x - size.x / 2),
      aim.y - (position.y - size.y / 2),
    );
    final beam = Paint()
      ..isAntiAlias = false
      ..strokeCap = StrokeCap.round;
    beam
      ..color = const Color(0xFF7CFF00)
      ..strokeWidth = 5;
    canvas.drawLine(from, target, beam);
    beam
      ..color = const Color(0xFFB4FF6A)
      ..strokeWidth = 3;
    canvas.drawLine(from, target, beam);
    beam
      ..color = const Color(0xFFE8FFE0)
      ..strokeWidth = 1.4;
    canvas.drawLine(from, target, beam);
  }
}
