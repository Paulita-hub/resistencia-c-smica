import 'dart:ui';

import 'package:flame/components.dart';

import '../game_layout.dart';
import '../resistencia_game.dart';
import '../sprite_loading.dart';

/// Computadora decorativa apoyada en el piso. No bloquea al personaje.
class ComputerProp extends SpriteComponent
    with HasGameReference<ResistenciaGame> {
  ComputerProp({required Vector2 position, required this.asset})
    : super(
        position: position,
        anchor: Anchor.bottomCenter,
        priority: 8,
      );

  final String asset;

  static const displayHeight = GameLayout.tileSize * 1.2;

  @override
  Future<void> onLoad() async {
    sprite = await game.trySprite(asset);
    if (sprite == null) {
      removeFromParent();
      return;
    }
    paint.filterQuality = FilterQuality.none;
    final src = sprite!.srcSize;
    size = Vector2(displayHeight * src.x / src.y, displayHeight);
  }
}
