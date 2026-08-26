import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../settings/settings.dart';
import '../../style/pressable.dart';

/// Filas de sonido y música, como en el mock: ícono on, barra, mute.
class AudioMixerPanel extends StatelessWidget {
  const AudioMixerPanel({required this.iconHeight, super.key});

  final double iconHeight;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsController>();
    final barH = (iconHeight * 0.5).clamp(16.0, 24.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MixerRow(
          iconHeight: iconHeight,
          barHeight: barH,
          onAsset: 'assets/images/hud/audio/sonido_on.png',
          muteAsset: 'assets/images/hud/audio/sonido_mute.png',
          volumeListenable: settings.soundsVolume,
          onVolume: settings.setSoundsVolume,
        ),
        SizedBox(height: iconHeight * 0.18),
        _MixerRow(
          iconHeight: iconHeight,
          barHeight: barH,
          onAsset: 'assets/images/hud/audio/musica_on.png',
          muteAsset: 'assets/images/hud/audio/musica_mute.png',
          volumeListenable: settings.musicVolume,
          onVolume: settings.setMusicVolume,
        ),
      ],
    );
  }
}

class _MixerRow extends StatelessWidget {
  const _MixerRow({
    required this.iconHeight,
    required this.barHeight,
    required this.onAsset,
    required this.muteAsset,
    required this.volumeListenable,
    required this.onVolume,
  });

  final double iconHeight;
  final double barHeight;
  final String onAsset;
  final String muteAsset;
  final ValueNotifier<double> volumeListenable;
  final ValueChanged<double> onVolume;

  @override
  Widget build(BuildContext context) {
    final barW = barHeight * 189 / 27;
    final gap = barW * 0.10;
    final padH = iconHeight * 0.52;
    final padV = iconHeight * 0.4;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/hud/audio/fondo.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MixerIcon(
                asset: onAsset,
                size: iconHeight,
                onPressed: () => onVolume(1),
              ),
              SizedBox(width: gap),
              ValueListenableBuilder<double>(
                valueListenable: volumeListenable,
                builder: (context, volume, _) {
                  return _PixelSlider(
                    height: barHeight,
                    value: volume,
                    onChanged: onVolume,
                  );
                },
              ),
              SizedBox(width: gap),
              _MixerIcon(
                asset: muteAsset,
                size: iconHeight,
                onPressed: () => onVolume(0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MixerIcon extends StatelessWidget {
  const _MixerIcon({
    required this.asset,
    required this.size,
    required this.onPressed,
  });

  final String asset;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _PixelSlider extends StatelessWidget {
  const _PixelSlider({
    required this.height,
    required this.value,
    required this.onChanged,
  });

  static const _barAsset = 'assets/images/hud/audio/barra.png';
  static const _thumbAsset = 'assets/images/hud/audio/regulador.png';
  static const _barSrc = Size(189, 27);
  static const _thumbSrc = Size(24, 39);

  final double height;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final barH = height;
    final barW = barH * _barSrc.width / _barSrc.height;
    final thumbH = barH * (_thumbSrc.height / _barSrc.height);
    final thumbW = thumbH * _thumbSrc.width / _thumbSrc.height;

    void setFromDx(double dx) {
      final span = (barW - thumbW).clamp(1.0, barW);
      onChanged(((dx - thumbW / 2) / span).clamp(0.0, 1.0));
    }

    return SizedBox(
      width: barW,
      height: thumbH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          AudioController.playClick();
          setFromDx(d.localPosition.dx);
        },
        onHorizontalDragUpdate: (d) => setFromDx(d.localPosition.dx),
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Image.asset(
                _barAsset,
                width: barW,
                height: barH,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
            Positioned(
              left: (barW - thumbW) * value.clamp(0.0, 1.0),
              child: Image.asset(
                _thumbAsset,
                width: thumbW,
                height: thumbH,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
