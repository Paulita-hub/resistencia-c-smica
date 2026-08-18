import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../../audio/sounds.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';
import 'coin.dart';
import 'enemy.dart';
import 'flying_monster.dart';
import 'goal.dart';
import 'hole_pit.dart';
import 'sector_door.dart';
import 'solid_block.dart';

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  Player({required Vector2 position})
    : super(
        position: position,
        size: Vector2(48, 64),
        anchor: Anchor.bottomLeft,
        priority: 20,
      );

  static const gravity = 1800.0;
  static const jumpSpeed = -760.0;
  static const moveSpeed = 230.0;

  final velocity = Vector2.zero();
  bool onGround = false;
  bool facingRight = true;
  double invulnerableTime = 0;
  bool _jumpWasHeld = false;

  Sprite? idle;
  Sprite? jump;
  Sprite? fall;
  Sprite? hurt;
  Sprite? attack;
  Sprite? destello;
  SpriteAnimation? run;
  SpriteAnimationTicker? _runTicker;
  final hypnotizedSprites = <Sprite>[];
  bool hypnotized = false;
  double _hypnoT = 0;
  double _hypnoLandedAt = -1;
  double attackFlash = 0;
  double _laserT = 0;

  bool get isAttacking => attackFlash > 0 && !hypnotized;

  void flashAttack() {
    if (hypnotized) return;
    attackFlash = 0.22;
    facingRight = true;
  }

  @override
  Future<void> onLoad() async {
    await add(
      RectangleHitbox.relative(
        Vector2(0.72, 0.9),
        parentSize: size,
        position: Vector2(size.x * 0.14, size.y * 0.1),
      ),
    );
    await _loadSprites();
  }

  Future<void> _loadSprites() async {
    await _loadFromFolder('characters/hero_${game.level.number}');
    if (idle == null && game.level.number != 1) {
      await _loadFromFolder('characters/hero_1');
    }
    idle ??= run?.frames.first.sprite;
    jump ??= idle;
    fall ??= idle;
    attack ??= idle;
    destello ??= await game.trySprite('items/destellomedialuna.png');
    if (run != null) {
      final src = run!.frames.first.sprite.srcSize;
      size = Vector2(52, (52 * src.y / src.x).roundToDouble());
    }
  }

  Future<void> _loadFromFolder(String folder) async {
    idle =
        await game.trySprite('$folder/run_1.png') ??
        await game.trySprite('$folder/idle.png');
    jump = await game.trySprite('$folder/jump.png');
    fall = await game.trySprite('$folder/fall.png');
    hurt = await game.trySprite('$folder/hurt.png');
    attack = await game.trySprite('$folder/attack.png');
    run = await game.tryStripAnimation('$folder/run.png');
    _runTicker = run?.createTicker();
    hypnotizedSprites.clear();
    for (var i = 1; i <= 3; i++) {
      final frame = await game.trySprite('$folder/hypnotized_$i.png');
      if (frame != null) hypnotizedSprites.add(frame);
    }
  }

  void startHypnotized() {
    hypnotized = true;
    _hypnoT = 0;
    _hypnoLandedAt = -1;
    velocity.x = 0;
    attackFlash = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hypnotized) {
      _updateHypnotized(dt);
      return;
    }
    if (!game.started || game.finished) return;

    if (attackFlash > 0) {
      attackFlash -= dt;
      _laserT += dt;
    } else {
      _laserT = 0;
    }
    if (invulnerableTime > 0) {
      invulnerableTime -= dt;
    }

    if (game.manualMove) {
      velocity.x = game.input.axisX * moveSpeed;
      if (isAttacking || velocity.x > 0) facingRight = true;
      if (!isAttacking && velocity.x < 0) facingRight = false;
    } else {
      velocity.x = moveSpeed;
      facingRight = true;
    }
    if (onGround && velocity.x.abs() > 10) {
      _runTicker?.update(dt);
    }

    final jumpHeld = game.input.jumpHeld;
    if (jumpHeld && !_jumpWasHeld && onGround) {
      velocity.y = jumpSpeed;
      onGround = false;
      game.audio.playSfx(SfxType.jump);
    }
    _jumpWasHeld = jumpHeld;

    velocity.y += gravity * dt;
    if (velocity.y > 900) velocity.y = 900;

    _moveAxis(dt, horizontal: true);
    _moveAxis(dt, horizontal: false);

    if (position.y > game.spawnPoint.y + 70) {
      game.hurtPlayer();
    }
  }

  void _updateHypnotized(double dt) {
    _hypnoT += dt;
    velocity.x = 0;
    velocity.y += gravity * dt;
    if (velocity.y > 900) velocity.y = 900;
    _moveAxis(dt, horizontal: false);

    if (onGround && _hypnoT >= 0.85) {
      if (_hypnoLandedAt < 0) _hypnoLandedAt = _hypnoT;
      if (_hypnoT - _hypnoLandedAt >= 1.15) {
        game.onHypnotizedFinished();
      }
    } else if (position.y > game.spawnPoint.y + 80) {
      game.onHypnotizedFinished();
    }
  }

  bool get _hypnoDown => hypnotized && _hypnoLandedAt >= 0;

  void _moveAxis(double dt, {required bool horizontal}) {
    if (horizontal) {
      position.x += velocity.x * dt;
    } else {
      position.y += velocity.y * dt;
      onGround = false;
    }

    final inHole = _feetOverHole();
    final playerRect = toAbsoluteRect();
    for (final block in game.world.children.whereType<SolidBlock>()) {
      final rect = block.toAbsoluteRect();
      if (!playerRect.overlaps(rect)) continue;

      if (!block.platform && inHole) continue;

      if (horizontal) {
        if (velocity.x > 0) {
          position.x = rect.left - size.x;
        } else if (velocity.x < 0) {
          position.x = rect.right;
        }
        velocity.x = 0;
      } else {
        if (velocity.y > 0) {
          position.y = rect.top;
          velocity.y = 0;
          onGround = true;
        } else if (velocity.y < 0) {
          position.y = rect.bottom + size.y;
          velocity.y = 0;
        }
      }
    }

    position.x = position.x.clamp(0, game.mapSize.x - size.x);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.finished) return;

    if (other is Coin) {
      other.eat();
    } else if (other is Enemy && !other.stomped) {
      final stomping = velocity.y > 80 && position.y <= other.position.y;
      if (stomping) {
        other.stomp();
        velocity.y = jumpSpeed * 0.55;
        game.audio.playSfx(SfxType.stomp);
      } else {
        game.hurtPlayer();
      }
    } else if (other is Goal) {
      game.reachGoal();
    } else if (other is SectorDoor) {
      game.enterDoor(other);
    } else if (other.parent is SectorDoor) {
      game.enterDoor(other.parent! as SectorDoor);
    }
  }

  @override
  void render(Canvas canvas) {
    if (invulnerableTime > 0 && (invulnerableTime * 12).floor().isEven) {
      return;
    }

    final sprite = _currentSprite();
    if (sprite != null) {
      canvas.save();
      final zoom = game.camera.viewfinder.zoom;
      if (zoom > 0 && zoom.isFinite) {
        canvas.translate(
          (position.x * zoom).round() / zoom - position.x,
          (position.y * zoom).round() / zoom - position.y,
        );
      }
      if (!facingRight && !isAttacking && !hypnotized) {
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      final src = sprite.srcSize;
      var destH = size.x * src.y / src.x;
      var destW = size.x;
      var destX = 0.0;
      var destY = size.y - destH;
      Offset? laserFrom;
      Offset? laserTo;
      if (isAttacking && attack != null) {
        destH = size.y;
        destW = destH * src.x / src.y;
        destY = size.y - destH;
        const muzzleX = 244.0;
        const muzzleY = 90.0;
        final scale = destH / src.y;
        laserFrom = Offset(destX + muzzleX * scale, destY + muzzleY * scale);
        for (final monster in game.world.children.whereType<FlyingMonster>()) {
          if (!monster.appeared) continue;
          final target = monster.headPoint;
          laserTo = Offset(
            target.x - position.x,
            target.y - (position.y - size.y),
          );
          break;
        }
      } else if (hypnotized) {
        final refH = hypnotizedSprites.isNotEmpty
            ? hypnotizedSprites.first.srcSize.y
            : src.y;
        final scale = size.y / refH;
        destH = src.y * scale;
        destW = src.x * scale;
        destX = (size.x - destW).clamp(-size.x, size.x) * 0.2;
        destY = size.y - destH;
      }
      sprite.render(
        canvas,
        position: Vector2(destX, destY),
        size: Vector2(destW, destH),
        overridePaint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );
      if (laserFrom != null && laserTo != null) {
        _drawLaser(canvas, laserFrom, laserTo);
      }
      canvas.restore();
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 8, size.x - 8, size.y - 8),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF4CC9F0),
    );
  }

  void _drawLaser(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()..isAntiAlias = false;
    paint
      ..color = const Color(0xFFFF3DA8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(from, to, paint);
    paint
      ..color = const Color(0xFFFF5AD6)
      ..strokeWidth = 3;
    canvas.drawLine(from, to, paint);
    paint
      ..color = const Color(0xFFFFF36A)
      ..strokeWidth = 1.5;
    canvas.drawLine(from, to, paint);

    final pulse = 0.75 + 0.25 * sin(_laserT * 26);
    final flash = 22.0 * pulse;
    canvas.save();
    canvas.translate(to.dx, to.dy);

    if (destello != null) {
      destello!.render(
        canvas,
        position: Vector2(-flash, -flash),
        size: Vector2.all(flash * 2),
        overridePaint: Paint()
          ..blendMode = BlendMode.plus
          ..color = Color.fromRGBO(255, 255, 255, 0.85 + 0.15 * pulse),
      );
    }

    paint
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.fill;
    paint.color = const Color(0xFFFF3DA8);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * pulse, height: 14 * pulse), paint);
    paint.color = const Color(0xFFFF5AD6);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 9 * pulse, height: 9 * pulse), paint);
    paint.color = const Color(0xFFFFF36A);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 5 * pulse, height: 5 * pulse), paint);
    paint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 2, height: 2), paint);

    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final a = _laserT * 10 + i * pi / 2;
      final len = 6.0 + 5 * pulse;
      paint.color = i.isEven ? const Color(0xFFFFF36A) : const Color(0xFFFFFFFF);
      canvas.drawLine(
        Offset(cos(a) * 3, sin(a) * 3),
        Offset(cos(a) * len, sin(a) * len),
        paint,
      );
    }
    canvas.restore();
  }

  Sprite? _currentSprite() {
    if (hypnotized && hypnotizedSprites.isNotEmpty) {
      if (_hypnoDown) return hypnotizedSprites.last;
      if (_hypnoT < 0.4 && onGround) return hypnotizedSprites[0];
      return hypnotizedSprites.length > 1
          ? hypnotizedSprites[1]
          : hypnotizedSprites[0];
    }
    if (!game.started) return idle;
    if (isAttacking) return attack ?? idle;
    if (invulnerableTime > 0.8) return hurt ?? idle;
    if (!onGround) {
      if (velocity.y < 0 || _hasGroundBelow()) {
        return jump ?? idle;
      }
      return fall ?? jump ?? idle;
    }
    if (velocity.x.abs() > 10 && _runTicker != null) {
      return _runTicker!.getSprite();
    }
    return idle;
  }

  bool _hasGroundBelow() {
    if (_feetOverHole()) return false;
    final feetY = position.y;
    final left = position.x + size.x * 0.2;
    final right = position.x + size.x * 0.8;
    for (final block in game.world.children.whereType<SolidBlock>()) {
      final rect = block.toAbsoluteRect();
      if (rect.top >= feetY - 4 && rect.left < right && rect.right > left) {
        return true;
      }
    }
    return false;
  }

  bool _feetOverHole() {
    final midX = position.x + size.x * 0.5;
    final feetY = position.y + 2;
    for (final hole in game.world.children.whereType<HolePit>()) {
      final rect = hole.toAbsoluteRect();
      if (midX > rect.left &&
          midX < rect.right &&
          feetY >= rect.top &&
          feetY <= rect.bottom) {
        return true;
      }
    }
    return false;
  }
}
