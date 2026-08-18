import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

extension SpriteLoading on FlameGame {
  static const _timeout = Duration(milliseconds: 800);

  Future<Sprite?> trySprite(String path) async {
    try {
      final image = await images.load(path).timeout(_timeout);
      return Sprite(image);
    } catch (_) {
      return null;
    }
  }

  Future<SpriteAnimation?> tryStripAnimation(
    String path, {
    double stepTime = 0.12,
  }) async {
    try {
      final image = await images.load(path).timeout(_timeout);
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      if (width <= 0 || height <= 0) return null;

      late final int amount;
      late final Vector2 textureSize;
      if (width >= height * 1.5) {
        amount = 4;
        if (width % 4 != 0) return null;
        textureSize = Vector2(width / 4, height);
      } else {
        final frame = height;
        amount = (width / frame).round().clamp(1, 16);
        if (amount < 2) return null;
        textureSize = Vector2.all(frame);
      }

      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: textureSize,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
