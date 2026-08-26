// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _shipAsset = 'assets/images/ui/loading_ship.png';
const _cargandoAsset = 'assets/images/ui/loading_cargando.png';

CustomTransitionPage<T> buildMyTransition<T>({
  required Widget child,
  String? name,
  Object? arguments,
  String? restorationId,
  LocalKey? key,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _LoadingReveal(animation: animation, child: child);
    },
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionDuration: const Duration(milliseconds: 2800),
    reverseTransitionDuration: const Duration(milliseconds: 1800),
  );
}

class _LoadingReveal extends StatefulWidget {
  const _LoadingReveal({required this.child, required this.animation});

  final Widget child;
  final Animation<double> animation;

  @override
  State<_LoadingReveal> createState() => _LoadingRevealState();
}

class _LoadingRevealState extends State<_LoadingReveal> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_statusListener);
    _finished = widget.animation.status == AnimationStatus.completed;
  }

  @override
  void didUpdateWidget(covariant _LoadingReveal oldWidget) {
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_statusListener);
      widget.animation.addStatusListener(_statusListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_statusListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final raw = widget.animation.value.clamp(0.0, 1.0);
        // Reveal LTR and fade 20%→100% in the first ~1.3s, then hold.
        final fadeT = Curves.easeInOut.transform((raw / 0.45).clamp(0.0, 1.0));
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF000000)),
            _LoadingArt(shipOpacity: 0.2 + 0.8 * fadeT, reveal: fadeT),
            IgnorePointer(
              ignoring: !_finished,
              child: AnimatedOpacity(
                opacity: _finished ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }

  void _statusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        setState(() => _finished = true);
      case AnimationStatus.forward:
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        setState(() => _finished = false);
    }
  }
}

class _LoadingArt extends StatelessWidget {
  const _LoadingArt({required this.shipOpacity, required this.reveal});

  final double shipOpacity;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shipW = (constraints.maxWidth * 0.62).clamp(
          220.0,
          constraints.maxWidth * 0.82,
        ) * 0.85;
        final textW = shipW * 0.48;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: shipOpacity,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    final edge = reveal.clamp(0.0, 1.0);
                    if (edge >= 0.999) {
                      return const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                      ).createShader(rect);
                    }
                    final mid = edge < 0.001 ? 0.001 : edge;
                    final soft = (edge + 0.34).clamp(mid + 0.001, 1.0);
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, mid, soft],
                    ).createShader(rect);
                  },
                  child: Image.asset(
                    _shipAsset,
                    width: shipW,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              SizedBox(height: shipW * 0.055),
              Image.asset(
                _cargandoAsset,
                width: textW,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
