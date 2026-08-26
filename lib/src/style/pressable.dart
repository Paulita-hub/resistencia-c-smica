import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';

/// Hundimiento al tocar, pensado para touch y grabar pantalla.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.overlay = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool overlay;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  static const _holdAfterUp = Duration(milliseconds: 220);

  bool _pressed = false;
  Timer? _release;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    _release?.cancel();
    if (value) {
      if (!_pressed) {
        _playClick();
        setState(() => _pressed = true);
      }
      return;
    }
    _release = Timer(_holdAfterUp, () {
      if (mounted && _pressed) setState(() => _pressed = false);
    });
  }

  void _playClick() {
    if (!widget.enabled) return;
    if (widget.onPressed == null) return;
    AudioController.playClick();
    if (AudioController.instance != null) return;
    try {
      context.read<AudioController>().playSfx(SfxType.buttonTap);
    } catch (_) {}
  }

  @override
  void dispose() {
    _release?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final pressed = active && _pressed;

    return Listener(
      onPointerDown: active ? (_) => _setPressed(true) : null,
      onPointerUp: active ? (_) => _setPressed(false) : null,
      onPointerCancel: active ? (_) => _setPressed(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? widget.onPressed : null,
        child: Transform.translate(
          offset: Offset(0, pressed ? 5 : 0),
          child: Transform.scale(
            scale: pressed ? 0.86 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
