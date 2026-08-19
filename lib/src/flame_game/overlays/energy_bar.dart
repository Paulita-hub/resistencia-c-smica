import 'package:flutter/material.dart';

import '../resistencia_game.dart';

enum EnergyBarTheme { player, monster }

/// Cabeza a un lado y barra de 5 segmentos a la misma altura.
class EnergyBar extends StatelessWidget {
  const EnergyBar({
    required this.filled,
    required this.height,
    required this.headAsset,
    required this.headSrcSize,
    this.slots = ResistenciaGame.energySlots,
    this.headOnRight = false,
    this.theme = EnergyBarTheme.player,
    super.key,
  });

  final int filled;
  final int slots;
  final double height;
  final String headAsset;
  final Size headSrcSize;
  final bool headOnRight;
  final EnergyBarTheme theme;

  factory EnergyBar.player({
    required ResistenciaGame game,
    required double height,
  }) {
    if (game.level.number == 2) {
      return EnergyBar(
        filled: game.energy,
        height: height,
        headAsset: 'assets/images/hud/cabezachabon.png',
        headSrcSize: const Size(127, 154),
      );
    }
    if (game.level.number == 3) {
      return EnergyBar(
        filled: game.energy,
        height: height,
        headAsset: 'assets/images/hud/cabeza_alien.png',
        headSrcSize: const Size(101, 165),
      );
    }
    return EnergyBar(
      filled: game.energy,
      height: height,
      headAsset: 'assets/images/hud/cabezachica.png',
      headSrcSize: const Size(136, 111),
    );
  }

  factory EnergyBar.monster({
    required ResistenciaGame game,
    required double height,
  }) {
    return EnergyBar(
      filled: game.monsterEnergy,
      height: height,
      headAsset: 'assets/images/hud/cabezamonstruo.png',
      headSrcSize: const Size(155, 150),
      headOnRight: true,
      theme: EnergyBarTheme.monster,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clamped = filled.clamp(0, slots);
    final pad = (height * 0.14).clamp(3.0, 8.0);
    final gap = (height * 0.1).clamp(2.0, 5.0);
    final cell = (height - pad * 2).clamp(10.0, height);
    final trackW = pad * 2 + slots * cell + (slots - 1) * gap;
    final headH = height;
    final headW = headH * headSrcSize.width / headSrcSize.height;
    final overlap = headW * 0.18;

    final head = Positioned(
      left: headOnRight ? trackW - overlap : 0,
      top: 0,
      width: headW,
      height: headH,
      child: Image(
        image: AssetImage(headAsset),
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
    final track = Positioned(
      left: headOnRight ? 0 : headW - overlap,
      top: 0,
      width: trackW,
      height: height,
      child: CustomPaint(
        size: Size(trackW, height),
        painter: _EnergyTrackPainter(
          filled: clamped,
          slots: slots,
          cell: cell,
          pad: pad,
          gap: gap,
          theme: theme,
        ),
      ),
    );

    return SizedBox(
      width: headW + trackW - overlap,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: headOnRight ? [track, head] : [track, head],
      ),
    );
  }
}

class _EnergyTrackPainter extends CustomPainter {
  _EnergyTrackPainter({
    required this.filled,
    required this.slots,
    required this.cell,
    required this.pad,
    required this.gap,
    required this.theme,
  });

  final int filled;
  final int slots;
  final double cell;
  final double pad;
  final double gap;
  final EnergyBarTheme theme;

  static const _frame = Color(0xFF020A46);
  static const _frameEdge = Color(0xFF0A4A82);
  static const _emptyInner = Color(0xFF010B48);
  static const _emptyBorder = Color(0xFF0474A8);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final padY = (size.height - cell) / 2;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    paint.color = _frame;
    canvas.drawRRect(frame, paint);
    paint
      ..color = _frameEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(frame.deflate(1.5), paint);
    paint.style = PaintingStyle.fill;

    for (var i = 0; i < slots; i++) {
      final r = Rect.fromLTWH(pad + i * (cell + gap), padY, cell, cell);
      if (i < filled) {
        _drawFilled(canvas, r, paint);
      } else {
        _drawEmpty(canvas, r, paint);
      }
    }
  }

  void _drawEmpty(Canvas canvas, Rect r, Paint paint) {
    paint.color = _emptyBorder;
    canvas.drawRect(r, paint);
    paint.color = _emptyInner;
    canvas.drawRect(r.deflate(2.5), paint);
  }

  void _drawFilled(Canvas canvas, Rect r, Paint paint) {
    final outer = theme == EnergyBarTheme.monster
        ? const Color(0xFF6B1C5A)
        : const Color(0xFF1F6B1C);
    final mid = theme == EnergyBarTheme.monster
        ? const Color(0xFFD0089A)
        : const Color(0xFF3CD008);
    final fill = theme == EnergyBarTheme.monster
        ? const Color(0xFFFF5AD6)
        : const Color(0xFF8FFF02);
    final hi = theme == EnergyBarTheme.monster
        ? const Color(0xFFFFB4EC)
        : const Color(0xFFC8FF6A);
    final lo = theme == EnergyBarTheme.monster
        ? const Color(0xFFA80478)
        : const Color(0xFF2EA804);

    paint.color = outer;
    canvas.drawRect(r, paint);
    paint.color = mid;
    canvas.drawRect(r.deflate(2), paint);
    paint.color = fill;
    final inner = r.deflate((cell * 0.12).clamp(2.0, 4.0));
    canvas.drawRect(inner, paint);
    final hiH = (cell * 0.1).clamp(2.0, 3.5);
    paint.color = hi;
    canvas.drawRect(
      Rect.fromLTWH(inner.left, inner.top, inner.width, hiH),
      paint,
    );
    paint.color = lo;
    canvas.drawRect(
      Rect.fromLTWH(inner.left, inner.bottom - hiH, inner.width, hiH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyTrackPainter oldDelegate) {
    return oldDelegate.filled != filled ||
        oldDelegate.slots != slots ||
        oldDelegate.cell != cell ||
        oldDelegate.pad != pad ||
        oldDelegate.gap != gap ||
        oldDelegate.theme != theme;
  }
}
