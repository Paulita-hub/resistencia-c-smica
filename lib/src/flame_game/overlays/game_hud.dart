import 'package:flutter/material.dart';

import '../../style/pressable.dart';
import '../resistencia_game.dart';
import 'audio_mixer_panel.dart';
import 'energy_bar.dart';

class GameHud extends StatefulWidget {
  const GameHud({required this.game, required this.onPause, super.key});

  final ResistenciaGame game;
  final VoidCallback onPause;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  bool _audioOpen = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final energyH = (shortest * 0.05).clamp(24.0, 36.0);
    final iconH = (shortest * 0.1).clamp(52.0, 80.0);
    final plaqueH = game.level.number == 2 ? iconH * 0.8 : iconH;
    final mixerIconH = plaqueH * 0.55;

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
                left: 8,
                child: IgnorePointer(
                  child: EnergyBar.player(game: game, height: energyH),
                ),
              ),
              if (game.level.number == 2 || game.level.number == 3)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: EnergyBar.monster(game: game, height: energyH),
                  ),
                ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_settings.png',
                          height: plaqueH,
                          onPressed: () =>
                              setState(() => _audioOpen = !_audioOpen),
                        ),
                        const SizedBox(width: 8),
                        _LevelPlaque(level: game.level.number, height: plaqueH),
                        const SizedBox(width: 8),
                        _HudImageButton(
                          asset: 'assets/images/hud/hud_pause.png',
                          height: plaqueH,
                          onPressed: () {
                            setState(() => _audioOpen = false);
                            widget.onPause();
                          },
                        ),
                      ],
                    ),
                    if (_audioOpen) ...[
                      SizedBox(height: plaqueH * 0.14),
                      AudioMixerPanel(iconHeight: mixerIconH),
                    ],
                  ],
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
    return Image.asset(
      asset,
      height: height,
      filterQuality: FilterQuality.none,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
    );
  }
}

class _HudImageButton extends StatelessWidget {
  const _HudImageButton({
    required this.asset,
    required this.height,
    required this.onPressed,
  });

  final String asset;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Image.asset(
        asset,
        height: height,
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}
