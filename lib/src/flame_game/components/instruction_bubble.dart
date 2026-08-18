import 'dart:ui';

import 'package:flame/components.dart';

import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Viñeta de instrucciones al lado de la cara, solo antes de Play.
class InstructionBubble extends PositionComponent
    with HasGameReference<ResistenciaGame> {
  InstructionBubble()
    : super(
        size: Vector2(80, 42),
        anchor: Anchor.centerLeft,
        priority: 25,
      );

  Sprite? sprite;

  @override
  Future<void> onLoad() async {
    await _loadSprite();
    _fitToPlayer();
  }

  Future<void> _loadSprite() async {
    sprite =
        await game.trySprite('items/vinetadelpersonaje.png') ??
        await game.trySprite('items/viñetadelpersonaje.png');
    _fitToPlayer();
  }

  /// Cabeza (pelo + cara) medida en `idle.png` 154×260.
  static const _spriteW = 154.0;
  static const _spriteH = 260.0;
  static const _headRight = 96.0;
  static const _headTop = 11.0;
  static const _headBottom = 78.0;

  void _fitToPlayer() {
    if (game.started) return;
    final player = game.player;
    final src = sprite?.srcSize ?? Vector2(244, 129);
    final scaleX = player.size.x / _spriteW;
    final scaleY = player.size.y / _spriteH;
    final faceH = (_headBottom - _headTop) * scaleY;
    size = Vector2(faceH * src.x / src.y, faceH);
    final faceRight = player.x + _headRight * scaleX;
    final faceCenterY =
        player.y - (_spriteH - (_headTop + _headBottom) / 2) * scaleY;
    position = Vector2(faceRight + 3, faceCenterY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.started) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.started) return;
    _fitToPlayer();
    if (sprite != null) {
      sprite!.render(canvas, size: size);
      return;
    }
    final r = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFF7CFC00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
