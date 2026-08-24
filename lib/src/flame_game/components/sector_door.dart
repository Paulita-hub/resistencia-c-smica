import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';

class SectorDoor extends PositionComponent
    with CollisionCallbacks, HasGameReference<ResistenciaGame> {
  SectorDoor({
    required Vector2 position,
    required this.label,
    required this.isCorrect,
    required this.color,
  }) : super(
         position: position,
         size: Vector2(180, 240),
         anchor: Anchor.bottomCenter,
         priority: 8,
       );

  final String label;
  final bool isCorrect;
  final Color color;
  Sprite? sprite;
  Sprite? _openSprite;
  bool opening = false;
  double _openedFor = 0;
  static const _openThenWin = 0.9;

  @override
  Future<void> onLoad() async {
    await _loadSprite();
    await add(
      RectangleHitbox(
        collisionType: CollisionType.passive,
      ),
    );
  }

  Future<void> _loadSprite() async {
    final file = isCorrect ? 'door_saber.png' : 'door_economia.png';
    sprite =
        await game.trySprite('levels/${game.level.number}/$file') ??
        await game.trySprite('items/$file');
    if (isCorrect) {
      _openSprite =
          await game.trySprite(
            'levels/${game.level.number}/door_saberabriendose.png',
          ) ??
          await game.trySprite('items/door_saberabriendose.png');
    }
    if (sprite != null) {
      final src = sprite!.srcSize;
      size = Vector2(200, 200 * src.y / src.x);
    }
  }

  void open() {
    if (opening) return;
    opening = true;
    if (_openSprite == null) {
      game.reachGoal();
      return;
    }
    sprite = _openSprite;
    final src = _openSprite!.srcSize;
    final height = size.y * 0.82;
    size = Vector2(height * src.x / src.y, height);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!opening || _openSprite == null) return;
    _openedFor += dt;
    if (_openedFor >= _openThenWin) {
      game.reachGoal();
    }
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      sprite!.render(
        canvas,
        size: size,
        overridePaint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );
      return;
    }

    final doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 18, size.x - 8, size.y - 18),
      const Radius.circular(18),
    );
    canvas.drawRRect(doorRect, Paint()..color = color);
    canvas.drawRRect(
      doorRect,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 8,
          fontFamily: 'Permanent Marker',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, 8),
          width: tp.width + 10,
          height: 14,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xCC000000),
    );
    tp.paint(canvas, Offset((size.x - tp.width) / 2, 2));
  }
}
