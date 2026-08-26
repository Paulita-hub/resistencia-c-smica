// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../style/pressable.dart';
import '../style/responsive_screen.dart';
import 'levels.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerProgress = context.watch<PlayerProgress>();

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Select level',
                  style: TextStyle(
                    fontFamily: 'Permanent Marker',
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: ListView(
                children: [
                  for (final level in gameLevels)
                    Pressable(
                      enabled:
                          playerProgress.highestLevelReached >=
                          level.number - 1,
                      onPressed:
                          playerProgress.highestLevelReached >= level.number - 1
                          ? () {
                              GoRouter.of(
                                context,
                              ).go('/play/session/${level.number}');
                            }
                          : null,
                      child: IgnorePointer(
                        child: ListTile(
                          enabled:
                              playerProgress.highestLevelReached >=
                              level.number - 1,
                          onTap: () {},
                          leading: Text(level.number.toString()),
                          title: Text('Level #${level.number}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        rectangularMenuArea: Pressable(
          onPressed: () => GoRouter.of(context).go('/play'),
          child: IgnorePointer(
            child: FilledButton(onPressed: () {}, child: const Text('Back')),
          ),
        ),
      ),
    );
  }
}
