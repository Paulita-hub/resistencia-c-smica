import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Monstruo volador del nivel 2: flota a la derecha y ataca con hipnosis.
class FlyingMonster extends PositionComponent
    with HasGameReference<ResistenciaGame> {
  FlyingMonster()
    : super(
        size: Vector2(82, 108),
        anchor: Anchor.topCenter,
        priority: 16,
      );

  /// Alto del cuerpo en idle recortado; las ondas de ataque se escalan igual.
  static const displayHeight = 130.0;
  static const appearDelay = 3.0;
  static const _idleSrcH = 270.0;
  static const _origHeadX = 490.0;
  static const _origHeadY = 200.0;
  static const _cropOrigins = [
    Offset(389, 153),
    Offset(150, 152),
    Offset(22, 29),
    Offset(27, 29),
  ];

  Sprite? idle;
  final attackFrames = <Sprite>[];
  double _bob = 0;
  double _phaseT = 0;
  double _animT = 0;
  bool _attacking = false;
  double _alive = 0;
  bool _announced = false;
  int _waveCycle = -1;

  bool get attacking => _attacking;
  bool get appeared => game.started && _alive >= appearDelay;

  Vector2 get headPoint => position.clone();

  double get _scale => displayHeight / _idleSrcH;

  @override
  Future<void> onLoad() async {
    idle = await game.trySprite('levels/2/monster_1.png');
    for (var i = 2; i <= 4; i++) {
      final frame = await game.trySprite('levels/2/monster_$i.png');
      if (frame != null) attackFrames.add(frame);
    }
    _layoutSprite();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt;
    _placeInView();

    if (!game.started || game.finished || game.gameOver) {
      _attacking = false;
      _phaseT = 0;
      _waveCycle = -1;
      if (!game.started) {
        _alive = 0;
        _announced = false;
      }
      _layoutSprite();
      return;
    }

    _alive += dt;
    if (!appeared) {
      _attacking = false;
      _phaseT = 0;
      _waveCycle = -1;
      _layoutSprite();
      return;
    }
    if (!_announced) {
      _announced = true;
      game.hint = '';
      game.hud.value++;
    }

    _phaseT += dt;
    if (_attacking) {
      _animT += dt;
      final n = attackFrames.isEmpty ? 1 : attackFrames.length;
      final cycle = (_animT / (0.16 * n)).floor();
      if (cycle != _waveCycle) {
        _waveCycle = cycle;
        game.audio.playSfx(SfxType.hypnoWave);
      }
      if (_phaseT >= 2.2) {
        game.resolveBattle();
        _attacking = false;
        _phaseT = 0;
        _waveCycle = -1;
      }
    } else if (_phaseT >= 1.8) {
      _attacking = true;
      _phaseT = 0;
      _animT = 0;
      _waveCycle = -1;
      game.beginBattle();
    }
    _layoutSprite();
  }

  void _placeInView() {
    final zoom = game.camera.viewfinder.zoom;
    if (zoom <= 0 || zoom.isNaN) return;
    final viewW = game.viewWidth / zoom;
    final camX = game.camera.viewfinder.position.x;
    final floorTop = game.spawnPoint.y;
    final t = _bob;
    final centerX = camX + viewW * 0.68;
    final centerY = max(28.0, floorTop * 0.32);
    final flyX = sin(t * 0.85) * viewW * 0.2 + sin(t * 1.7) * 16;
    final flyY = cos(t * 1.05) * min(34.0, floorTop * 0.18) + sin(t * 2.3) * 8;
    position.x = (centerX + flyX).clamp(camX + viewW * 0.38, camX + viewW * 0.92);
    position.y = (centerY + flyY).clamp(32.0, max(44.0, floorTop - 130));
  }

  void _layoutSprite() {
    final sprite = _sprite;
    if (sprite == null) return;
    final src = sprite.srcSize;
    final scale = _scale;
    size = Vector2(src.x * scale, src.y * scale);
    final origin = _originFor(sprite);
    final hx = (_origHeadX - origin.dx) * scale;
    final hy = (_origHeadY - origin.dy) * scale;
    if (size.x > 0 && size.y > 0) {
      anchor = Anchor(hx / size.x, hy / size.y);
    }
  }

  Offset _originFor(Sprite sprite) {
    if (idle != null && sprite.image == idle!.image) {
      return _cropOrigins[0];
    }
    for (var i = 0; i < attackFrames.length; i++) {
      if (sprite.image == attackFrames[i].image) {
        return _cropOrigins[i + 1];
      }
    }
    return _cropOrigins[0];
  }

  Sprite? get _sprite {
    if (_attacking && attackFrames.isNotEmpty) {
      final i = (_animT / 0.16).floor() % attackFrames.length;
      return attackFrames[i];
    }
    return idle ?? (attackFrames.isEmpty ? null : attackFrames.first);
  }

  @override
  void render(Canvas canvas) {
    if (!appeared) return;
    final sprite = _sprite;
    if (sprite == null) return;
    final fade = ((_alive - appearDelay) / 0.4).clamp(0.0, 1.0);
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (fade < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, fade);
    }
    sprite.render(canvas, size: size, overridePaint: paint);
  }
}
