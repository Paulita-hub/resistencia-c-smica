import 'package:flutter/material.dart';

import '../resistencia_game.dart';
import '../../style/jugar_button.dart';

class StartPlayOverlay extends StatelessWidget {
  const StartPlayOverlay({required this.game, super.key});

  final ResistenciaGame game;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).shortestSide;
    return Center(
      child: JugarButton(
        key: const Key('jugar'),
        height: (h * 0.2).clamp(72.0, 120.0),
        onPressed: game.beginRun,
      ),
    );
  }
}
