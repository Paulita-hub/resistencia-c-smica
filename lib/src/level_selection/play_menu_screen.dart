import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../player_progress/player_progress.dart';
import '../style/letterbox.dart';
import '../style/palette.dart';
import '../style/pressable.dart';

class PlayMenuScreen extends StatelessWidget {
  const PlayMenuScreen({super.key});

  static const _design = Size(1024, 571);
  static const _backRect = Rect.fromLTWH(16, 8, 64, 59);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final progress = context.watch<PlayerProgress>();

    return Scaffold(
      key: const Key('play-menu'),
      backgroundColor: palette.backgroundLevelSelection,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frame = LetterboxFrame.of(constraints.biggest, _design);
          final scale = frame.scale;
          final drawnW = frame.drawn.width;
          final drawnH = frame.drawn.height;
          final ox = frame.offset.dx;
          final oy = frame.offset.dy;
          final btnScale = (drawnH * 0.84) / 800;

          void tap(VoidCallback action) {
            action();
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: ox,
                top: oy,
                width: drawnW,
                height: drawnH,
                child: Image.asset(
                  'assets/images/ui/play_menu_bg.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                left: ox,
                top: oy,
                width: drawnW,
                height: drawnH,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 28 * scale,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuButton(
                            key: const Key('choose-character'),
                            asset: 'assets/images/ui/btn_choose_character.png',
                            srcSize: const Size(725, 156),
                            scale: btnScale * 0.6,
                            onPressed: () => tap(
                              () => GoRouter.of(context).go('/play/characters'),
                            ),
                          ),
                          SizedBox(height: 10 * btnScale * 0.6),
                          _MenuButton(
                            asset: 'assets/images/ui/btn_levels.png',
                            srcSize: const Size(395, 127),
                            scale: btnScale * 0.6,
                          ),
                          SizedBox(height: 8 * btnScale * 0.6),
                          for (var level = 1; level <= 3; level++) ...[
                            _MenuButton(
                              key: Key('level-$level'),
                              asset: 'assets/images/ui/btn_level_$level.png',
                              srcSize: const Size(403, 156),
                              scale: btnScale * 0.6,
                              enabled:
                                  progress.highestLevelReached >= level - 1,
                              onPressed: () => tap(
                                () => GoRouter.of(
                                  context,
                                ).go('/play/session/$level'),
                              ),
                            ),
                            if (level < 3) SizedBox(height: 6 * btnScale * 0.6),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: math.max(
                  ox + _backRect.left * scale,
                  MediaQuery.paddingOf(context).left + 8,
                ),
                top: math.max(
                  oy + _backRect.top * scale,
                  MediaQuery.paddingOf(context).top + 6,
                ),
                width: _backRect.width * scale,
                height: _backRect.height * scale,
                child: Pressable(
                  key: const Key('back'),
                  onPressed: () => tap(() => GoRouter.of(context).go('/')),
                  child: Image.asset(
                    'assets/images/ui/back_arrow.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
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

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.asset,
    required this.srcSize,
    required this.scale,
    this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String asset;
  final Size srcSize;
  final double scale;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Image.asset(
        asset,
        width: srcSize.width * scale,
        height: srcSize.height * scale,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      ),
    );
    if (onPressed == null || !enabled) return child;
    return Pressable(onPressed: onPressed, child: child);
  }
}
