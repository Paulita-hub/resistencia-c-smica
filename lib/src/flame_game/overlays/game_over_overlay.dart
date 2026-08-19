import 'package:flutter/material.dart';

import '../resistencia_game.dart';
import 'result_art_overlay.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.game,
    required this.onRetry,
    required this.onExit,
    super.key,
  });

  final ResistenciaGame game;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  static const _art = {
    1: 'assets/images/hud/victory/lose_nivel_1.png',
    2: 'assets/images/hud/victory/lose_nivel_2.png',
    3: 'assets/images/hud/victory/lose_nivel_3.png',
  };

  @override
  Widget build(BuildContext context) {
    final level3 = game.level.number == 3;
    return ResultArtOverlay(
      art: _art[game.level.number] ?? _art[1]!,
      hotspots: [
        ResultHotspot(
          design: level3 ? ResultButtons.retryLose3 : ResultButtons.retryLose,
          onPressed: onRetry,
        ),
        ResultHotspot(
          design: level3 ? ResultButtons.exitLose3 : ResultButtons.exitLose,
          onPressed: onExit,
        ),
      ],
    );
  }
}
