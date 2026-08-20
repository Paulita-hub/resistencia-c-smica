import 'package:flutter/material.dart';

import '../resistencia_game.dart';
import '../../style/jugar_button.dart';

class StartPlayOverlay extends StatelessWidget {
  const StartPlayOverlay({required this.game, super.key});

  final ResistenciaGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: const Alignment(0, 0.3),
        child: JugarButton(
          key: const Key('jugar'),
          onPressed: game.beginRun,
        ),
      ),
    );
  }
}
