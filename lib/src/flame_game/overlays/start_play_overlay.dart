import 'package:flutter/material.dart';

import '../resistencia_game.dart';

class StartPlayOverlay extends StatelessWidget {
  const StartPlayOverlay({required this.game, super.key});

  final ResistenciaGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.center,
        child: FilledButton(
          onPressed: game.beginRun,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 28,
            ),
          ),
          child: const Text('Play'),
        ),
      ),
    );
  }
}
