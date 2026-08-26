// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'persistence/settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  final SettingsPersistence _persistence;

  /// Whether or not the sound is on at all. This overrides both music
  /// and sound.
  ValueNotifier<bool> muted = ValueNotifier(false);

  ValueNotifier<String> playerName = ValueNotifier('Player');

  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  ValueNotifier<bool> musicOn = ValueNotifier(true);

  ValueNotifier<double> soundsVolume = ValueNotifier(1);

  ValueNotifier<double> musicVolume = ValueNotifier(1);

  /// Creates a new instance of [SettingsController] backed by [persistence].
  SettingsController({required SettingsPersistence persistence})
    : _persistence = persistence;

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence() async {
    await Future.wait([
      _persistence
          // On the web, sound can only start after user interaction, so
          // we start muted there.
          // On any other platform, we start unmuted.
          .getMuted(defaultValue: false)
          .then((value) => muted.value = value),
      _persistence.getSoundsOn().then((value) => soundsOn.value = value),
      _persistence.getMusicOn().then((value) => musicOn.value = value),
      _persistence.getSoundsVolume().then(
        (value) => soundsVolume.value = value,
      ),
      _persistence.getMusicVolume().then((value) => musicVolume.value = value),
      _persistence.getPlayerName().then((value) => playerName.value = value),
    ]);
    soundsOn.value = soundsVolume.value > 0.02;
    musicOn.value = musicVolume.value > 0.02;
  }

  void setPlayerName(String name) {
    playerName.value = name;
    _persistence.savePlayerName(playerName.value);
  }

  void unmute() {
    if (!muted.value) return;
    muted.value = false;
    _persistence.saveMuted(false);
  }

  void toggleMusicOn() {
    setMusicVolume(musicOn.value ? 0 : 1);
  }

  void toggleMuted() {
    muted.value = !muted.value;
    _persistence.saveMuted(muted.value);
  }

  void toggleSoundsOn() {
    setSoundsVolume(soundsOn.value ? 0 : 1);
  }

  void setMusicVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    musicVolume.value = v;
    final on = v > 0.02;
    if (musicOn.value != on) {
      musicOn.value = on;
      _persistence.saveMusicOn(on);
    }
    if (on) unmute();
    _persistence.saveMusicVolume(v);
  }

  void setSoundsVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    soundsVolume.value = v;
    final on = v > 0.02;
    if (soundsOn.value != on) {
      soundsOn.value = on;
      _persistence.saveSoundsOn(on);
    }
    if (on) unmute();
    _persistence.saveSoundsVolume(v);
  }
}
