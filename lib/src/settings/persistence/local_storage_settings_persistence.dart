// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_persistence.dart';

/// An implementation of [SettingsPersistence] that uses
/// `package:shared_preferences`.
class LocalStorageSettingsPersistence extends SettingsPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<bool> getMusicOn() async {
    final prefs = await instanceFuture;
    return prefs.getBool('musicOn') ?? true;
  }

  @override
  Future<bool> getMuted({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('mute') ?? defaultValue;
  }

  @override
  Future<String> getPlayerName() async {
    final prefs = await instanceFuture;
    return prefs.getString('playerName') ?? 'Player';
  }

  @override
  Future<bool> getSoundsOn() async {
    final prefs = await instanceFuture;
    return prefs.getBool('soundsOn') ?? true;
  }

  @override
  Future<double> getMusicVolume() async {
    final prefs = await instanceFuture;
    final stored = prefs.getDouble('musicVolume');
    if (stored != null) return stored.clamp(0.0, 1.0);
    return (prefs.getBool('musicOn') ?? true) ? 1.0 : 0.0;
  }

  @override
  Future<double> getSoundsVolume() async {
    final prefs = await instanceFuture;
    final stored = prefs.getDouble('soundsVolume');
    if (stored != null) return stored.clamp(0.0, 1.0);
    return (prefs.getBool('soundsOn') ?? true) ? 1.0 : 0.0;
  }

  @override
  Future<void> saveMusicOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('musicOn', value);
  }

  @override
  Future<void> saveMuted(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('mute', value);
  }

  @override
  Future<void> savePlayerName(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('playerName', value);
  }

  @override
  Future<void> saveSoundsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('soundsOn', value);
  }

  @override
  Future<void> saveMusicVolume(double value) async {
    final prefs = await instanceFuture;
    await prefs.setDouble('musicVolume', value);
  }

  @override
  Future<void> saveSoundsVolume(double value) async {
    final prefs = await instanceFuture;
    await prefs.setDouble('soundsVolume', value);
  }
}
