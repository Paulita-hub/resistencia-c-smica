import 'package:flutter/material.dart';

import '../resistencia_game.dart';
import 'energy_bar.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.game,
    required this.onSettings,
    required this.onPause,
    super.key,
  });

  final ResistenciaGame game;
  final VoidCallback onSettings;
  final VoidCallback onPause;

  static const _iconH = 40.0;
  static const _energyH = 60.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: game.hud,
        builder: (context, _, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox.expand(),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                height: _energyH,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: EnergyBar.player(game: game, height: _energyH),
                      ),
                    ),
                    if (game.level.number == 2)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: EnergyBar.monster(game: game, height: _energyH),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_settings.png',
                          srcSize: const Size(90, 96),
                          height: _iconH,
                          onPressed: onSettings,
                        ),
                        const SizedBox(width: 8),
                        _LevelPlaque(
                          level: game.level.number,
                          height: _iconH,
                        ),
                        const SizedBox(width: 8),
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_pause.png',
                          srcSize: const Size(112, 100),
                          height: _iconH,
                          onPressed: onPause,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (game.hint.isNotEmpty)
                Positioned(
                  right: 16,
                  top: 8 + _energyH + 6,
                  left: 16,
                  child: Text(
                    game.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Permanent Marker',
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelPlaque extends StatelessWidget {
  const _LevelPlaque({required this.level, required this.height});

  final int level;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 198 / 109;
    if (level == 1) {
      return Image.asset(
        'assets/images/hud/hud_nivel.png',
        width: width,
        height: height,
        filterQuality: FilterQuality.none,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      );
    }
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF020A46),
        border: Border.all(color: const Color(0xFF7CFF00), width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'NIVEL $level',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Permanent Marker',
          fontSize: 16,
          height: 1,
        ),
      ),
    );
  }
}

class _HudImageButton extends StatelessWidget {
  const _HudImageButton({
    required this.asset,
    required this.srcSize,
    required this.height,
    required this.onPressed,
  });

  final String asset;
  final Size srcSize;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final width = height * srcSize.width / srcSize.height;
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        asset,
        width: width,
        height: height,
        filterQuality: FilterQuality.none,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    );
  }
}
