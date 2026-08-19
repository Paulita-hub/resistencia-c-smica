import 'package:flutter/material.dart';

/// Imagen de resultado a pantalla completa, con zonas táctiles
/// alineadas a los botones del arte (794×496).
class ResultArtOverlay extends StatelessWidget {
  const ResultArtOverlay({
    required this.art,
    required this.hotspots,
    super.key,
  });

  static const designSize = Size(794, 496);

  final String art;
  final List<ResultHotspot> hotspots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              art,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
            ),
            for (final spot in hotspots)
              Positioned(
                left: spot.design.left / designSize.width * w,
                top: spot.design.top / designSize.height * h,
                width: spot.design.width / designSize.width * w,
                height: spot.design.height / designSize.height * h,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: spot.onPressed,
                ),
              ),
          ],
        );
      },
    );
  }
}

class ResultHotspot {
  const ResultHotspot({
    required this.design,
    required this.onPressed,
  });

  final Rect design;
  final VoidCallback onPressed;
}

abstract final class ResultButtons {
  static const retryWin = Rect.fromLTWH(292, 368, 72, 74);
  static const exitWin = Rect.fromLTWH(448, 368, 73, 74);
  static const nextWin = Rect.fromLTWH(614, 366, 55, 74);

  static const retryLose = Rect.fromLTWH(296, 364, 72, 74);
  static const exitLose = Rect.fromLTWH(450, 366, 73, 74);

  static const retryLose3 = Rect.fromLTWH(262, 376, 72, 74);
  static const exitLose3 = Rect.fromLTWH(416, 378, 73, 74);
}
