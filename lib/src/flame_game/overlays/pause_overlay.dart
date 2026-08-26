import 'package:flutter/material.dart';

import '../../style/pressable.dart';
import '../resistencia_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, required this.onExit, super.key});

  final ResistenciaGame game;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final iconH = (MediaQuery.sizeOf(context).shortestSide * 0.14).clamp(
      56.0,
      88.0,
    );
    final gap = iconH * 0.28;

    return ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PauseIcon(
                asset: 'assets/images/hud/victory/button_exit.png',
                size: iconH,
                onPressed: onExit,
              ),
              SizedBox(width: gap),
              _PauseIcon(
                asset: 'assets/images/hud/victory/button_retry.png',
                size: iconH,
                onPressed: game.restartLevel,
              ),
              SizedBox(width: gap),
              _PauseIcon(
                asset: 'assets/images/hud/victory/button_play.png',
                size: iconH,
                onPressed: game.resumeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseIcon extends StatelessWidget {
  const _PauseIcon({
    required this.asset,
    required this.size,
    required this.onPressed,
  });

  final String asset;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
