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

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 520;
    final energyH = compact ? 32.0 : 44.0;
    final iconH = compact ? 32.0 : 40.0;

    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: game.hud,
        builder: (context, _, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox.expand(),
              Positioned(
                top: compact ? 4 : 8,
                left: 0,
                right: 0,
                height: energyH,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: EnergyBar.player(game: game, height: energyH),
                      ),
                    ),
                    if (game.level.number == 2 || game.level.number == 3)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: EnergyBar.monster(game: game, height: energyH),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_settings.png',
                          srcSize: const Size(90, 96),
                          height: iconH,
                          onPressed: onSettings,
                        ),
                        const SizedBox(width: 8),
                        _LevelPlaque(
                          level: game.level.number,
                          height: iconH,
                        ),
                        const SizedBox(width: 8),
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_pause.png',
                          srcSize: const Size(112, 100),
                          height: iconH,
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
                  top: (compact ? 4 : 8) + energyH + 6,
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

  static const _art = {
    1: 'assets/images/hud/hud_nivel.png',
    2: 'assets/images/hud/hud_nivel_2.png',
    3: 'assets/images/hud/hud_nivel_3.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _art[level];
    if (asset == null) return const SizedBox.shrink();
    final width = height * 198 / 109;
    return Image.asset(
      asset,
      width: width,
      height: height,
      filterQuality: FilterQuality.none,
      fit: BoxFit.fill,
      gaplessPlayback: true,
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
