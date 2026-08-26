import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../style/letterbox.dart';
import '../style/palette.dart';
import '../style/pressable.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  static const _design = Size(994, 491);
  static const _cards = [
    _CharacterCard(
      front: 'assets/images/ui/card_luna.png',
      back: 'assets/images/ui/ficha_luna.png',
      rect: Rect.fromLTWH(120, 70, 244, 335),
      elegirFrac: Rect.fromLTWH(0.7704, 0.8367, 0.2019, 0.1247),
    ),
    _CharacterCard(
      front: 'assets/images/ui/card_milo.png',
      back: 'assets/images/ui/ficha_milo.png',
      rect: Rect.fromLTWH(386, 70, 228, 335),
      elegirFrac: Rect.fromLTWH(0.7774, 0.8222, 0.2022, 0.1270),
    ),
    _CharacterCard(
      front: 'assets/images/ui/card_xel.png',
      back: 'assets/images/ui/ficha_xel.png',
      rect: Rect.fromLTWH(636, 70, 238, 335),
      elegirFrac: Rect.fromLTWH(0.7692, 0.8399, 0.2019, 0.1276),
    ),
  ];
  static const _detailSize = Size(832, 441);
  static const _backRect = Rect.fromLTWH(16, 8, 64, 59);

  late final List<AnimationController> _flips;

  Rect get _centeredDetail {
    return Rect.fromLTWH(
      (_design.width - _detailSize.width) / 2,
      (_design.height - _detailSize.height) / 2,
      _detailSize.width,
      _detailSize.height,
    );
  }

  @override
  void initState() {
    super.initState();
    _flips = List.generate(
      _cards.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 720),
      ),
    );
  }

  @override
  void dispose() {
    for (final flip in _flips) {
      flip.dispose();
    }
    super.dispose();
  }

  void _toggle(int index) {
    final open =
        _flips[index].status == AnimationStatus.forward ||
        _flips[index].status == AnimationStatus.completed;
    if (open) {
      _flips[index].reverse();
      return;
    }
    for (var i = 0; i < _flips.length; i++) {
      if (i == index) {
        _flips[i].forward();
      } else {
        _flips[i].reverse();
      }
    }
  }

  void _closeOpenDetail() {
    final open = _flips.any((flip) => flip.value > 0.02);
    if (!open) return;
    context.read<AudioController>().playSfx(SfxType.buttonTap);
    for (final flip in _flips) {
      if (flip.value > 0) flip.reverse();
    }
  }

  void _openLevels() {
    GoRouter.of(context).go('/play');
  }

  void _goBack() {
    GoRouter.of(context).go('/play');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      key: const Key('character-select'),
      backgroundColor: palette.backgroundLevelSelection,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frame = LetterboxFrame.of(constraints.biggest, _design);
          final scale = frame.scale;
          final drawnW = frame.drawn.width;
          final drawnH = frame.drawn.height;
          final ox = frame.offset.dx;
          final oy = frame.offset.dy;

          Rect mapRect(Rect r) => Rect.fromLTWH(
            ox + r.left * scale,
            oy + r.top * scale,
            r.width * scale,
            r.height * scale,
          );
          final pad = MediaQuery.paddingOf(context);
          final back = mapRect(_backRect).shift(
            Offset(
              math.max(0, pad.left + 8 - (ox + _backRect.left * scale)),
              math.max(0, pad.top + 6 - (oy + _backRect.top * scale)),
            ),
          );

          return AnimatedBuilder(
            animation: Listenable.merge(_flips),
            builder: (context, _) {
              final openIndex = _flips.indexWhere((flip) => flip.value > 0.02);
              return Stack(
                clipBehavior: Clip.hardEdge,
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
                  if (openIndex >= 0)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeOpenDetail,
                      ),
                    ),
                  for (var i = 0; i < _cards.length; i++)
                    if (openIndex < 0 || i == openIndex)
                      _buildCard(
                        index: i,
                        mapped: mapRect(_cards[i].rect),
                        detailMapped: mapRect(_centeredDetail),
                        t: Curves.easeInOut.transform(_flips[i].value),
                      ),
                  Positioned.fromRect(
                    rect: back,
                    child: Pressable(
                      key: const Key('back'),
                      onPressed: _goBack,
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
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required int index,
    required Rect mapped,
    required Rect detailMapped,
    required double t,
  }) {
    final card = _cards[index];
    final rect = Rect.lerp(mapped, detailMapped, t)!;
    final angle = t * math.pi;
    final showBack = t >= 0.5;
    final parallax = math.sin(angle) * 12;
    final elegir = Rect.fromLTWH(
      rect.width * card.elegirFrac.left,
      rect.height * card.elegirFrac.top,
      rect.width * card.elegirFrac.width,
      rect.height * card.elegirFrac.height,
    );

    return Positioned.fromRect(
      rect: rect,
      child: Pressable(
        key: Key('character-${index + 1}'),
        enabled: t < 0.5,
        onPressed: t < 0.5 ? () => _toggle(index) : null,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        card.back,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                      ),
                      if (t > 0.85)
                        Positioned.fromRect(
                          rect: elegir,
                          child: ColoredBox(
                            color: const Color(0xFFFFFFFF),
                            child: Pressable(
                              key: index == 0 ? const Key('empezar') : null,
                              onPressed: _openLevels,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  elegir.height / 2,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Positioned(
                                      left: -elegir.left,
                                      top: -elegir.top,
                                      width: rect.width,
                                      height: rect.height,
                                      child: Image.asset(
                                        card.back,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.none,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Transform.translate(
                  offset: Offset(parallax, 0),
                  child: Image.asset(
                    card.front,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CharacterCard {
  const _CharacterCard({
    required this.front,
    required this.back,
    required this.rect,
    required this.elegirFrac,
  });

  final String front;
  final String back;
  final Rect rect;
  final Rect elegirFrac;
}
