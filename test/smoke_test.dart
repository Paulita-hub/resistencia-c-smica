// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_template/main.dart';
import 'package:game_template/src/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:game_template/src/settings/persistence/memory_settings_persistence.dart';

void main() {
  testWidgets('smoke test', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        settingsPersistence: MemoryOnlySettingsPersistence(),
        playerProgressPersistence: MemoryOnlyPlayerProgressPersistence(),
        adsController: null,
        gamesServicesController: null,
        inAppPurchaseController: null,
      ),
    );

    expect(find.byKey(const Key('jugar')), findsOneWidget);
    expect(find.byKey(const Key('settings')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings')));
    await tester.pumpAndSettle();
    expect(find.text('Music'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('jugar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('play-menu')), findsOneWidget);
    expect(find.byKey(const Key('choose-character')), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('play session')), findsOneWidget);
  });
}
