import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../style/jugar_button.dart';
import '../style/palette.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const _design = Size(1024, 572);
  static const _buttonSize = Size(200, 74);
  static const _buttonTop = 465.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final audioController = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.max(
            constraints.maxWidth / _design.width,
            constraints.maxHeight / _design.height,
          );
          final drawnW = _design.width * scale;
          final drawnH = _design.height * scale;
          final ox = (constraints.maxWidth - drawnW) / 2;
          final oy = (constraints.maxHeight - drawnH) / 2;

          return Stack(
            children: [
              Positioned(
                left: ox,
                top: oy,
                width: drawnW,
                height: drawnH,
                child: Image.asset(
                  'assets/images/ui/cover.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                left: ox + (_design.width - _buttonSize.width) / 2 * scale,
                top: oy + _buttonTop * scale,
                width: _buttonSize.width * scale,
                height: _buttonSize.height * scale,
                child: JugarButton(
                  key: const Key('jugar'),
                  height: _buttonSize.height * scale,
                  onPressed: () {
                    audioController.playSfx(SfxType.buttonTap);
                    GoRouter.of(context).go('/play');
                  },
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  key: const Key('settings'),
                  tooltip: 'Ajustes',
                  color: Colors.white,
                  onPressed: () => GoRouter.of(context).push('/settings'),
                  icon: const Icon(Icons.settings),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
