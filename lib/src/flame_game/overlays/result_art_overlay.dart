import 'package:flutter/material.dart';

import '../../style/letterbox.dart';
import '../../style/pressable.dart';

/// Imagen de resultado a pantalla completa, con zonas táctiles
/// alineadas a los botones del arte (794×496).
class ResultArtOverlay extends StatelessWidget {
  const ResultArtOverlay({
    required this.art,
    required this.hotspots,
    this.captionBottom = 311,
    super.key,
  });

  static const designSize = Size(794, 496);
  static const _gapBelowText = 12.0;
  static const _fillOrigin = Offset(16, 416);

  final String art;
  final List<ResultHotspot> hotspots;

  /// Última línea del texto blanco en coords de diseño.
  final double captionBottom;

  Rect _raised(Rect button) {
    final top = captionBottom + _gapBelowText;
    return Rect.fromLTWH(button.left, top, button.width, button.height);
  }

  Rect _fillSource(Rect button) {
    return Rect.fromLTWH(
      _fillOrigin.dx,
      _fillOrigin.dy,
      button.width,
      button.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frame = LetterboxFrame.of(constraints.biggest, designSize);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: frame.offset.dx,
                top: frame.offset.dy,
                width: frame.drawn.width,
                height: frame.drawn.height,
                child: Image.asset(
                  art,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),
              for (final spot in hotspots)
                _ClippedArt(
                  art: art,
                  frame: frame,
                  mapped: frame.map(spot.design),
                  source: _fillSource(spot.design),
                ),
              for (final spot in hotspots)
                _SinkingArtButton(
                  art: art,
                  frame: frame,
                  mapped: frame.map(_raised(spot.design)),
                  source: spot.design,
                  onPressed: spot.onPressed,
                ),
            ],
          );
        },
      ),
    );
  }
}

class ResultHotspot {
  const ResultHotspot({required this.design, required this.onPressed});

  final Rect design;
  final VoidCallback onPressed;
}

abstract final class ResultButtons {
  static const retryWin = Rect.fromLTWH(292, 368, 72, 74);
  static const exitWin = Rect.fromLTWH(448, 368, 73, 74);
  static const nextWin = Rect.fromLTWH(610, 360, 70, 80);

  static const retryLose = Rect.fromLTWH(296, 364, 72, 74);
  static const exitLose = Rect.fromLTWH(450, 366, 73, 74);

  static const retryLose3 = Rect.fromLTWH(262, 376, 72, 74);
  static const exitLose3 = Rect.fromLTWH(416, 378, 73, 74);
}

class _ClippedArt extends StatelessWidget {
  const _ClippedArt({
    required this.art,
    required this.frame,
    required this.mapped,
    required this.source,
  });

  final String art;
  final LetterboxFrame frame;
  final Rect mapped;
  final Rect source;

  @override
  Widget build(BuildContext context) {
    final sourceMapped = frame.map(source);
    return Positioned.fromRect(
      rect: mapped,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: frame.offset.dx - sourceMapped.left,
              top: frame.offset.dy - sourceMapped.top,
              width: frame.drawn.width,
              height: frame.drawn.height,
              child: Image.asset(
                art,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recorta el botón del arte y lo hunde al tocarlo, como el resto del juego.
class _SinkingArtButton extends StatelessWidget {
  const _SinkingArtButton({
    required this.art,
    required this.frame,
    required this.mapped,
    required this.source,
    required this.onPressed,
  });

  final String art;
  final LetterboxFrame frame;
  final Rect mapped;
  final Rect source;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sourceMapped = frame.map(source);
    return Positioned.fromRect(
      rect: mapped,
      child: ColoredBox(
        color: const Color(0xFF141E16),
        child: Pressable(
          onPressed: onPressed,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: frame.offset.dx - sourceMapped.left,
                  top: frame.offset.dy - sourceMapped.top,
                  width: frame.drawn.width,
                  height: frame.drawn.height,
                  child: Image.asset(
                    art,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
