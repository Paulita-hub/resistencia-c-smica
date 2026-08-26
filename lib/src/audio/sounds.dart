// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.huhsh:
      return const ['hash1.mp3', 'hash2.mp3', 'hash3.mp3'];
    case SfxType.wssh:
      return const [
        'wssh1.mp3',
        'wssh2.mp3',
        'dsht1.mp3',
        'ws1.mp3',
        'spsh1.mp3',
        'hh1.mp3',
        'hh2.mp3',
        'kss1.mp3',
      ];
    case SfxType.buttonTap:
      return const ['ui_button.mp3'];
    case SfxType.congrats:
      return const ['win_level.mp3'];
    case SfxType.erase:
      return const ['fwfwfwfwfw1.mp3', 'fwfwfwfw1.mp3'];
    case SfxType.swishSwish:
      return const ['swishswish1.mp3', 'hh1.mp3', 'hh2.mp3'];
    case SfxType.jump:
      return const ['jump.mp3'];
    case SfxType.coin:
      return const ['kch1.mp3', 'hash1.mp3', 'hash2.mp3'];
    case SfxType.eat:
      return const ['medialuna.mp3'];
    case SfxType.attack:
      return const ['wssh1.mp3', 'dsht1.mp3', 'kss1.mp3', 'ws1.mp3'];
    case SfxType.laser:
      return const ['laser_shot.mp3'];
    case SfxType.defend:
      return const ['spsh1.mp3', 'fwfwfwfw1.mp3', 'sh1.mp3'];
    case SfxType.monsterAttack:
      return const ['wssh2.mp3', 'dsht1.mp3', 'haw1.mp3'];
    case SfxType.hypnoWave:
      return const ['hypno_whoosh.mp3'];
    case SfxType.monsterLaser:
      return const ['monster_laser.mp3'];
    case SfxType.stomp:
      return const ['fwfwfwfwfw1.mp3', 'fwfwfwfw1.mp3'];
    case SfxType.hurt:
      return const [
        'wssh1.mp3',
        'wssh2.mp3',
        'dsht1.mp3',
        'ws1.mp3',
      ];
    case SfxType.lose:
      return const ['lose_level.mp3'];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.huhsh:
      return 0.4;
    case SfxType.wssh:
      return 0.2;
    case SfxType.buttonTap:
      return 1.0;
    case SfxType.congrats:
      return 0.85;
    case SfxType.lose:
      return 0.95;
    case SfxType.erase:
    case SfxType.swishSwish:
    case SfxType.jump:
    case SfxType.stomp:
    case SfxType.hurt:
    case SfxType.attack:
    case SfxType.laser:
    case SfxType.defend:
    case SfxType.monsterAttack:
    case SfxType.hypnoWave:
    case SfxType.monsterLaser:
      return 1.0;
    case SfxType.eat:
      return 1.0;
    case SfxType.coin:
      return 0.75;
  }
}

enum SfxType {
  huhsh,
  wssh,
  buttonTap,
  congrats,
  erase,
  swishSwish,
  jump,
  coin,
  eat,
  attack,
  laser,
  defend,
  monsterAttack,
  hypnoWave,
  monsterLaser,
  stomp,
  hurt,
  lose,
}
