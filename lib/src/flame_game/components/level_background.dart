import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../resistencia_game.dart';

class LevelBackground extends SpriteComponent
    with HasGameReference<ResistenciaGame> {
  LevelBackground(this.assetPath);

  final String assetPath;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(assetPath);
    paint.filterQuality = FilterQuality.none;
    _cover(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _cover(size);
  }

  void _cover(Vector2 screen) {
    if (sprite == null) return;
    final img = sprite!.originalSize;
    final scale = max(screen.x / img.x, screen.y / img.y);
    size = img * scale;
    position = Vector2((screen.x - size.x) / 2, (screen.y - size.y) / 2);
  }
}
