import 'package:flutter/material.dart';

import '../resistencia_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    required this.game,
    required this.onExit,
    super.key,
  });

  final ResistenciaGame game;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pausa',
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: game.resumeGame,
              child: const Text('Continuar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('Salir'),
            ),
          ],
        ),
      ),
    );
  }
}
