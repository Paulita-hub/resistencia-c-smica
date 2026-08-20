import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../style/palette.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  static const _design = Size(994, 491);
  static const _cards = [
    Rect.fromLTWH(178, 91, 183, 330),
    Rect.fromLTWH(389, 91, 183, 330),
    Rect.fromLTWH(609, 91, 183, 330),
  ];
  static const _arrowSize = Size(85, 79);
  /// Bottom-right of each card, mostly on the card (not in the gap).
  static const _arrowOffset = Offset(88, 258);
  static const _fichas = [
    'assets/images/ui/ficha_luna.png',
    'assets/images/ui/ficha_milo.png',
    'assets/images/ui/ficha_xel.png',
  ];
  static const _empezar = Rect.fromLTWH(773, 396, 111, 40);

  int? _selected;
  int? _detail;

  void _onCardTap(int index) {
    final audio = context.read<AudioController>();
    audio.playSfx(SfxType.buttonTap);
    if (_selected == index) {
      setState(() => _detail = index);
      return;
    }
    setState(() => _selected = index);
  }

  void _openLevels() {
    context.read<AudioController>().playSfx(SfxType.buttonTap);
    GoRouter.of(context).go('/play/levels');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      key: const Key('character-select'),
      backgroundColor: palette.backgroundLevelSelection,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / _design.width,
            constraints.maxHeight / _design.height,
          );
          final drawnW = _design.width * scale;
          final drawnH = _design.height * scale;
          final ox = (constraints.maxWidth - drawnW) / 2;
          final oy = (constraints.maxHeight - drawnH) / 2;

          Rect mapRect(Rect r) => Rect.fromLTWH(
            ox + r.left * scale,
            oy + r.top * scale,
            r.width * scale,
            r.height * scale,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: ox,
                top: oy,
                width: drawnW,
                height: drawnH,
                child: Image.asset(
                  'assets/images/ui/character_select.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),
              for (var i = 0; i < _cards.length; i++)
                Positioned.fromRect(
                  rect: mapRect(_cards[i]),
                  child: GestureDetector(
                    key: Key('character-${i + 1}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onCardTap(i),
                  ),
                ),
              if (_selected != null)
                Positioned(
                  left:
                      ox +
                      (_cards[_selected!].left + _arrowOffset.dx) * scale,
                  top:
                      oy + (_cards[_selected!].top + _arrowOffset.dy) * scale,
                  width: _arrowSize.width * scale,
                  height: _arrowSize.height * scale,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/ui/select_arrow.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              if (_detail != null) ...[
                Positioned(
                  left: ox,
                  top: oy,
                  width: drawnW,
                  height: drawnH,
                  child: Image.asset(
                    _fichas[_detail!],
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 8,
                  child: TextButton.icon(
                    key: const Key('ficha-back'),
                    onPressed: () {
                      context.read<AudioController>().playSfx(
                        SfxType.buttonTap,
                      );
                      setState(() => _detail = null);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Volver',
                      style: TextStyle(
                        fontFamily: 'Permanent Marker',
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: mapRect(_empezar),
                  child: GestureDetector(
                    key: const Key('empezar'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _openLevels,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
