import 'package:flutter/material.dart';

import '../resistencia_game.dart';

class TouchControls extends StatelessWidget {
  const TouchControls({required this.game, super.key});

  final ResistenciaGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (game.manualMove) ...[
              _HoldButton(
                label: '◀',
                width: 72,
                onHeld: (held) => game.input.left = held,
              ),
              const SizedBox(width: 10),
              _HoldButton(
                label: '▶',
                width: 72,
                onHeld: (held) => game.input.right = held,
              ),
            ],
            const Spacer(),
            _HoldButton(
              label: 'Saltar',
              width: game.manualMove ? 110 : 140,
              onHeld: (held) => game.input.jumpHeld = held,
            ),
            if (game.manualMove) ...[
              const SizedBox(width: 10),
              _HoldButton(
                label: 'Atacar',
                accent: true,
                onTap: game.tapAttack,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.label,
    this.onHeld,
    this.onTap,
    this.width = 140,
    this.accent = false,
  });

  final String label;
  final ValueChanged<bool>? onHeld;
  final VoidCallback? onTap;
  final double width;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        onTap?.call();
        onHeld?.call(true);
      },
      onPointerUp: (_) => onHeld?.call(false),
      onPointerCancel: (_) => onHeld?.call(false),
      child: Container(
        width: width,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent ? const Color(0x99D0089A) : const Color(0x661D3557),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent ? const Color(0xFFFF5AD6) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
