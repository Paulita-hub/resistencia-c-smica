// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../in_app_purchase/in_app_purchase.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../style/pressable.dart';
import '../style/responsive_screen.dart';
import 'custom_name_dialog.dart';
import 'settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.watch<Palette>();
    final compact = MediaQuery.sizeOf(context).height < 500;
    final titleSize = compact ? 32.0 : 55.0;
    final lineSize = compact ? 22.0 : 30.0;
    final gap = SizedBox(height: compact ? 16 : 60);

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      body: SafeArea(
        child: ResponsiveScreen(
          squarishMainArea: ListView(
            children: [
              gap,
              Text(
                'Ajustes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: titleSize,
                  height: 1,
                ),
              ),
              gap,
              _NameChangeLine('Nombre', fontSize: lineSize),
              ValueListenableBuilder<bool>(
                valueListenable: settings.soundsOn,
                builder: (context, soundsOn, child) => _SettingsLine(
                  'Sonido',
                  Icon(soundsOn ? Icons.graphic_eq : Icons.volume_off),
                  fontSize: lineSize,
                  onSelected: () => settings.toggleSoundsOn(),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.musicOn,
                builder: (context, musicOn, child) => _SettingsLine(
                  'Music',
                  Icon(musicOn ? Icons.music_note : Icons.music_off),
                  fontSize: lineSize,
                  onSelected: () => settings.toggleMusicOn(),
                ),
              ),
              Consumer<InAppPurchaseController?>(
                builder: (context, inAppPurchase, child) {
                  if (inAppPurchase == null) {
                    return const SizedBox.shrink();
                  }

                  Widget icon;
                  VoidCallback? callback;
                  if (inAppPurchase.adRemoval.active) {
                    icon = const Icon(Icons.check);
                  } else if (inAppPurchase.adRemoval.pending) {
                    icon = const CircularProgressIndicator();
                  } else {
                    icon = const Icon(Icons.ad_units);
                    callback = () {
                      inAppPurchase.buy();
                    };
                  }
                  return _SettingsLine(
                    'Quitar anuncios',
                    icon,
                    fontSize: lineSize,
                    onSelected: callback,
                  );
                },
              ),
              _SettingsLine(
                'Reiniciar progreso',
                const Icon(Icons.delete),
                fontSize: lineSize,
                onSelected: () {
                  context.read<PlayerProgress>().reset();

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Se reinició el progreso.')),
                  );
                },
              ),
              gap,
            ],
          ),
          rectangularMenuArea: Pressable(
            onPressed: () => GoRouter.of(context).pop(),
            child: IgnorePointer(
              child: FilledButton(onPressed: () {}, child: const Text('Back')),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameChangeLine extends StatelessWidget {
  const _NameChangeLine(this.title, {required this.fontSize});

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Pressable(
      onPressed: () => showCustomNameDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: fontSize,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: settings.playerName,
              builder: (context, name, child) => Text(
                '‘$name’',
                style: TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine(
    this.title,
    this.icon, {
    required this.fontSize,
    this.onSelected,
  });

  final String title;
  final Widget icon;
  final double fontSize;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: onSelected != null,
      onPressed: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: fontSize,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
