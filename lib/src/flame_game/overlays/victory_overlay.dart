import 'package:flutter/material.dart';

import '../../level_selection/levels.dart';
import '../resistencia_game.dart';
import 'result_art_overlay.dart';

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({
    required this.game,
    required this.onRetry,
    required this.onExit,
    required this.onNext,
    super.key,
  });

  final ResistenciaGame game;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onNext;

  static const _art = {
    1: 'assets/images/hud/victory/win_nivel_1.png',
    2: 'assets/images/hud/victory/win_nivel_2.png',
    3: 'assets/images/hud/victory/win_nivel_3.png',
  };

  bool get _hasNext => game.level.number < gameLevels.length;

  @override
  Widget build(BuildContext context) {
    return ResultArtOverlay(
      art: _art[game.level.number] ?? _art[1]!,
      hotspots: [
        ResultHotspot(design: ResultButtons.retryWin, onPressed: onRetry),
        ResultHotspot(design: ResultButtons.exitWin, onPressed: onExit),
        ResultHotspot(
          design: ResultButtons.nextWin,
          onPressed: _hasNext ? onNext : onExit,
        ),
      ],
    );
  }
}
