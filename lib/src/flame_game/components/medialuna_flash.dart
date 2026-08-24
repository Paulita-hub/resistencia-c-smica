import 'dart:ui';

import 'package:flame/components.dart';

import '../game_layout.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Destello detrás de la medialuna al comerla.
class MedialunaFlash extends PositionComponent
    with HasGameReference<ResistenciaGame> {
  MedialunaFlash({required Vector2 position, this.food})
    : super(
        position: position,
        size: Vector2.all(GameLayout.coinWidth),
        anchor: Anchor.center,
        priority: 18,
      );

  final Sprite? food;
  Sprite? destello;
  double _t = 0;
  static const life = 0.55;

  @override
  Future<void> onLoad() async {
    destello = await game.trySprite('items/destellomedialuna.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    angle = _t * 6;
    if (_t >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / life).clamp(0.0, 1.0);
    final fade = (1 - p).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    if (destello != null) {
      final flash = GameLayout.coinWidth * 1.6 * (1.0 + p * 1.4);
      destello!.render(
        canvas,
        position: Vector2(-flash / 2, -flash / 2),
        size: Vector2.all(flash),
        overridePaint: Paint()
          ..color = Color.fromRGBO(255, 255, 255, fade)
          ..blendMode = BlendMode.plus,
      );
    }

    if (food != null) {
      final src = food!.srcSize;
      final fw = GameLayout.coinWidth * (1 - p * 0.45);
      final fh = fw * src.y / src.x;
      food!.render(
        canvas,
        position: Vector2(-fw / 2, -fh / 2),
        size: Vector2(fw, fh),
        overridePaint: Paint()..color = Color.fromRGBO(255, 255, 255, fade),
      );
    }
    canvas.restore();
  }
}
