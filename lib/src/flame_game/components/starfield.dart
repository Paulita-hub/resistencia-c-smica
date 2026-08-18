import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class Starfield extends Component with HasGameReference {
  Starfield({this.starCount = 90});

  final int starCount;
  final List<_Star> _stars = [];
  final Random _random = Random(42);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < starCount; i++) {
      _stars.add(
        _Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 0.6 + _random.nextDouble() * 1.6,
          alpha: 0.35 + _random.nextDouble() * 0.65,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size.toSize();
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF070B1A),
    );
    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        Paint()..color = Color.fromRGBO(230, 240, 255, star.alpha),
      );
    }
  }
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
  });

  final double x;
  final double y;
  final double radius;
  final double alpha;
}
