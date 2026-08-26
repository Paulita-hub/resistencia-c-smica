// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../settings/settings.dart';
import 'songs.dart';
import 'sounds.dart';

/// Allows playing music and sound. A facade to `package:audioplayers`.
class AudioController {
  static final _log = Logger('AudioController');

  static AudioController? instance;

  final AudioPlayer _musicPlayer;

  /// This is a list of [AudioPlayer] instances which are rotated to play
  /// sound effects.
  final List<AudioPlayer> _sfxPlayers;

  int _currentSfxPlayer = 0;

  final Queue<Song> _playlist;

  final Random _random = Random();

  SettingsController? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Evita que `unmute()` arranque la música antes del clic de un botón.
  bool _ignoreMusicOnUnmute = false;

  /// Creates an instance that plays music and sound.
  ///
  /// Use [polyphony] to configure the number of sound effects (SFX) that can
  /// play at the same time. A [polyphony] of `1` will always only play one
  /// sound (a new sound will stop the previous one). See discussion
  /// of [_sfxPlayers] to learn why this is the case.
  ///
  /// Background music does not count into the [polyphony] limit. Music will
  /// never be overridden by sound effects because that would be silly.
  AudioController({int polyphony = 8})
    : assert(polyphony >= 1),
      _musicPlayer = AudioPlayer(playerId: 'musicPlayer'),
      _sfxPlayers = Iterable.generate(
        polyphony,
        (i) => AudioPlayer(playerId: 'sfxPlayer#$i'),
      ).toList(growable: false),
      _playlist = Queue.of(List<Song>.of(songs)) {
    instance = this;
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.onPlayerComplete.listen(_changeSong);
  }

  /// Enables the [AudioController] to listen to [AppLifecycleState] events,
  /// and therefore do things like stopping playback when the game
  /// goes into the background.
  void attachLifecycleNotifier(
    ValueNotifier<AppLifecycleState> lifecycleNotifier,
  ) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  /// Enables the [AudioController] to track changes to settings.
  /// Namely, when any of [SettingsController.muted],
  /// [SettingsController.musicOn] or [SettingsController.soundsOn] changes,
  /// the audio controller will act accordingly.
  void attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.muted.removeListener(_mutedHandler);
      oldSettings.musicOn.removeListener(_musicOnHandler);
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
      oldSettings.musicVolume.removeListener(_musicVolumeHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.muted.addListener(_mutedHandler);
    settingsController.musicOn.addListener(_musicOnHandler);
    settingsController.soundsOn.addListener(_soundsOnHandler);
    settingsController.musicVolume.addListener(_musicVolumeHandler);
    _applyMusicVolume();

    if (!settingsController.muted.value && settingsController.musicOn.value) {
      _startMusic();
    }
  }

  /// Call from a tap so the browser allows audio and the loop can start.
  void handleUserGesture() {
    _settings?.unmute();
    if (_settings == null) return;
    if (_settings!.muted.value) return;
    if (_settings!.musicOn.value) {
      _ensureMusicPlaying();
    }
  }

  /// Clic de menú / botón. Usa el singleton para overlays de Flame.
  static void playClick() {
    instance?.playSfx(SfxType.buttonTap);
  }

  void dispose() {
    if (instance == this) instance = null;
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    _musicPlayer.dispose();
    for (final player in _sfxPlayers) {
      player.dispose();
    }
  }

  /// Preloads all sound effects.
  Future<void> initialize() async {
    _log.info('Preloading sound effects');
    try {
      await AudioCache.instance.loadAll(
        SfxType.values
            .expand(soundTypeToFilename)
            .toSet()
            .map((path) => 'sfx/$path')
            .toList(),
      );
    } catch (e) {
      _log.warning('Could not preload all SFX: $e');
    }
  }

  void playSfx(SfxType type) {
    var muted = _settings?.muted.value ?? false;
    // El clic de menú desmutea, pero la música arranca después del SFX
    // para no comerse el gesto del navegador.
    if (muted && type == SfxType.buttonTap) {
      _ignoreMusicOnUnmute = true;
      _settings?.unmute();
      _ignoreMusicOnUnmute = false;
      muted = false;
    }
    if (muted) {
      _log.info(() => 'Ignoring playing sound ($type) because audio is muted.');
      return;
    }
    final soundsOn = _settings?.soundsOn.value ?? true;
    // Clicks de menú siempre suenan; el resto respeta el slider de sonido.
    if (type != SfxType.buttonTap && !soundsOn) {
      _log.info(
        () => 'Ignoring playing sound ($type) because sounds are turned off.',
      );
      return;
    }

    _log.info(() => 'Playing sound: $type');
    final options = soundTypeToFilename(type);
    final filename = options[_random.nextInt(options.length)];
    final volume = soundTypeToVolume(type) *
        (type == SfxType.buttonTap
            ? (_settings?.soundsVolume.value ?? 1).clamp(0.35, 1.0)
            : (_settings?.soundsVolume.value ?? 1));

    final currentPlayer = _sfxPlayers[_currentSfxPlayer];
    currentPlayer.play(AssetSource('sfx/$filename'), volume: volume);
    _currentSfxPlayer = (_currentSfxPlayer + 1) % _sfxPlayers.length;
  }

  void _changeSong(void _) {
    _log.info('Music finished; looping.');
    _playFirstSongInPlaylist();
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAllSound();
      case AppLifecycleState.resumed:
        if (!_settings!.muted.value && _settings!.musicOn.value) {
          _resumeMusic();
        }
      case AppLifecycleState.inactive:
        // No need to react to this state change.
        break;
    }
  }

  void _musicOnHandler() {
    if (_settings!.musicOn.value) {
      // Music got turned on.
      if (!_settings!.muted.value) {
        _resumeMusic();
      }
    } else {
      // Music got turned off.
      _stopMusic();
    }
  }

  void _mutedHandler() {
    if (_settings!.muted.value) {
      _stopAllSound();
    } else if (!_ignoreMusicOnUnmute && _settings!.musicOn.value) {
      _resumeMusic();
    }
  }

  Future<void> _playFirstSongInPlaylist() async {
    _log.info(() => 'Playing ${_playlist.first} now.');
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(AssetSource('music/${_playlist.first.filename}'));
    await _applyMusicVolume();
  }

  Future<void> _applyMusicVolume() async {
    final muted = _settings?.muted.value ?? true;
    final on = _settings?.musicOn.value ?? false;
    final volume = _settings?.musicVolume.value ?? 1;
    await _musicPlayer.setVolume(muted || !on ? 0 : volume);
  }

  void _musicVolumeHandler() {
    _applyMusicVolume();
  }

  Future<void> _resumeMusic() async {
    _log.info('Resuming music');
    switch (_musicPlayer.state) {
      case PlayerState.paused:
        _log.info('Calling _musicPlayer.resume()');
        try {
          await _musicPlayer.resume();
          await _applyMusicVolume();
        } catch (e) {
          // Sometimes, resuming fails with an "Unexpected" error.
          _log.severe(e);
          await _playFirstSongInPlaylist();
        }
      case PlayerState.stopped:
        _log.info(
          "resumeMusic() called when music is stopped. "
          "This probably means we haven't yet started the music. "
          "For example, the game was started with sound off.",
        );
        await _playFirstSongInPlaylist();
      case PlayerState.playing:
        _log.warning(
          'resumeMusic() called when music is playing. '
          'Nothing to do.',
        );
      case PlayerState.completed:
        _log.warning(
          'resumeMusic() called when music is completed. '
          "Music should never be 'completed' as it's either not playing "
          "or looping forever.",
        );
        await _playFirstSongInPlaylist();
      default:
        _log.warning('Unhandled PlayerState: ${_musicPlayer.state}');
    }
  }

  void _soundsOnHandler() {
    for (final player in _sfxPlayers) {
      if (player.state == PlayerState.playing) {
        player.stop();
      }
    }
  }

  void _startMusic() {
    _log.info('starting music');
    _ensureMusicPlaying();
  }

  Future<void> _ensureMusicPlaying() async {
    if (_musicPlayer.state == PlayerState.playing) {
      await _applyMusicVolume();
      return;
    }
    await _playFirstSongInPlaylist();
  }

  void _stopAllSound() {
    if (_musicPlayer.state == PlayerState.playing) {
      _musicPlayer.pause();
    }
    for (final player in _sfxPlayers) {
      player.stop();
    }
  }

  void _stopMusic() {
    _log.info('Stopping music');
    if (_musicPlayer.state == PlayerState.playing) {
      _musicPlayer.pause();
    }
  }
}
