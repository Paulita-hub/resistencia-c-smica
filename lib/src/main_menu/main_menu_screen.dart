import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../style/jugar_button.dart';
import '../style/letterbox.dart';
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
          final frame = LetterboxFrame.of(constraints.biggest, _design);
          final pad = MediaQuery.paddingOf(context);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: frame.offset.dx,
                top: frame.offset.dy,
                width: frame.drawn.width,
                height: frame.drawn.height,
                child: Image.asset(
                  'assets/images/ui/cover.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                left: frame.offset.dx +
                    (_design.width - _buttonSize.width) / 2 * frame.scale,
                top: frame.offset.dy + _buttonTop * frame.scale,
                width: _buttonSize.width * frame.scale,
                height: _buttonSize.height * frame.scale,
                child: JugarButton(
                  key: const Key('jugar'),
                  height: _buttonSize.height * frame.scale,
                  onPressed: () {
                    audioController.playSfx(SfxType.buttonTap);
                    GoRouter.of(context).go('/play');
                  },
                ),
              ),
              Positioned(
                top: pad.top + 8,
                right: pad.right + 8,
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
