import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../level_selection/levels.dart';
import 'components/chainsaw_monster.dart';
import 'components/circuit_background.dart';
import 'components/coin.dart';
import 'components/computer_prop.dart';
import 'components/enemy.dart';
import 'components/flying_monster.dart';
import 'components/goal.dart';
import 'components/ground_strip.dart';
import 'components/hole_pit.dart';
import 'components/instruction_bubble.dart';
import 'components/level_background.dart';
import 'components/mobile_hud.dart';
import 'components/player.dart';
import 'components/sector_door.dart';
import 'components/solid_block.dart';
import 'components/starfield.dart';
import 'level_maps.dart';
import 'player_input.dart';

class ResistenciaGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  ResistenciaGame({
    required this.level,
    required this.audio,
    required this.onWon,
  });

  final GameLevel level;
  final AudioController audio;
  final void Function(int coins) onWon;

  final input = PlayerInput();

  late Vector2 mapSize;
  late Vector2 spawnPoint;
  late Player player;

  int coins = 0;
  static const energySlots = 5;
  static const startingEnergy = 3;
  static const clicksPerHit = 12;
  int energy = startingEnergy;
  int monsterEnergy = energySlots;
  int lives = 3;
  bool inBattle = false;
  int attackCharge = 0;
  bool started = false;
  bool finished = false;
  bool gameOver = false;
  bool _won = false;
  String hint = '';
  final hud = ValueNotifier<int>(0);
  double _cameraX = 0;

  /// Nivel 2 y 3: el jugador elige avanzar o retroceder. El 1 sigue en auto-run.
  bool get manualMove => level.number == 2 || level.number == 3;
  bool get canAttack => level.number == 2 || level.number == 3;

  /// Tercer botón HUD (Usar objeto). No hay ítem usable todavía.
  bool get canUseItem => false;

  MobileHud? mobileHud;

  static const hudOverlay = 'hud';
  static const gameOverOverlay = 'gameOver';
  static const playOverlay = 'play';
  static const pauseOverlay = 'pause';
  static const winOverlay = 'win';

  double get viewWidth => size.x;
  double get viewHeight => size.y;

  @override
  Future<void> onLoad() async {
    camera.viewport = MaxViewport();
    await _loadBackdrop();
    _loadLevel();
    _setupCamera();
    overlays.add(hudOverlay);
    overlays.add(playOverlay);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _setupCamera();
      if (started && !gameOver && !_won && mobileHud != null) {
        _showMobileHud();
      }
    }
  }

  void _setupCamera() {
    if (size.x <= 0 || size.y <= 0 || mapSize.y <= 0) return;
    camera.stop();
    camera.setBounds(null);
    camera.viewfinder.anchor = Anchor.topLeft;
    // Toda la altura del mapa entra en el lienzo 1920×1080: el piso queda abajo.
    camera.viewfinder.zoom = size.y / mapSize.y;
    _scrollCameraX();
  }

  void _scrollCameraX([double dt = 0]) {
    final zoom = camera.viewfinder.zoom;
    if (zoom.isNaN || zoom <= 0) return;
    final viewW = viewWidth / zoom;
    final maxX = max(0.0, mapSize.x - viewW);
    if (started && !finished && !gameOver && !manualMove) {
      _cameraX += Player.moveSpeed * dt;
    } else if (!started || manualMove) {
      _cameraX = player.x + player.size.x / 2 - viewW * 0.35;
    }
    camera.viewfinder.position = Vector2(_cameraX.clamp(0, maxX), 0);
  }

  void _failIfLeftBehind() {
    if (!started || finished || gameOver || manualMove) return;
    if (level.number == 3 && (!player.onGround || player.fallingOut)) return;
    if (player.x + player.size.x < camera.viewfinder.position.x - 4) {
      failLevel();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isLoaded) {
      _scrollCameraX(dt);
      _failIfLeftBehind();
      if (level.number == 2 &&
          started &&
          !gameOver &&
          !_won &&
          energy <= 0 &&
          !player.hypnotized) {
        hypnotizePlayer();
      }
    }
  }

  bool get monsterReady {
    for (final child in world.children.whereType<FlyingMonster>()) {
      return child.appeared;
    }
    for (final child in world.children.whereType<ChainsawMonster>()) {
      return child.appeared;
    }
    return false;
  }

  Future<void> _loadBackdrop() async {
    final path = 'levels/${level.number}/background.png';
    try {
      await images.load(path);
      camera.backdrop.add(LevelBackground(path));
    } catch (_) {
      camera.backdrop.add(
        level.number == 1 ? CircuitBackground() : Starfield(),
      );
    }
  }

  void _loadLevel() {
    world.removeAll(world.children.toList());
    coins = 0;
    energy = level.number >= 2 ? energySlots : startingEnergy;
    monsterEnergy = energySlots;
    inBattle = false;
    attackCharge = 0;
    finished = false;
    gameOver = false;
    _won = false;
    _cameraX = 0;
    hint = '';

    final rows = LevelMaps.forLevel(level.number);
    final tile = LevelMaps.tileSize;
    mapSize = LevelMaps.mapSizeFor(rows);
    final floorHeight = LevelMaps.floorVisualHeightFor(rows);
    final floorTop = LevelMaps.floorTopY(rows);
    spawnPoint = Vector2(tile, floorTop);

    if (LevelMaps.hasFloor(rows)) {
      world.add(
        GroundLayer(
          position: Vector2(0, floorTop),
          size: Vector2(mapSize.x, floorHeight),
        ),
      );
    }

    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final cell = rows[y][x];
        final topLeft = Vector2(x * tile, y * tile);
        switch (cell) {
          case 'X':
            world.add(SolidBlock(position: topLeft, size: Vector2.all(tile)));
          case 'H':
            final startsRun =
                (x == 0 || rows[y][x - 1] != 'H') &&
                (y == 0 || rows[y - 1][x] != 'H');
            if (startsRun) {
              var width = 0;
              while (x + width < rows[y].length && rows[y][x + width] == 'H') {
                width++;
              }
              world.add(
                HolePit(
                  position: topLeft,
                  size: Vector2(width * tile, floorHeight),
                ),
              );
            }
          case '=':
            world.add(
              SolidBlock(
                position: topLeft,
                size: Vector2.all(tile),
                platform: true,
                oneWay: true,
              ),
            );
          case 'C':
            final onFloor =
                y + 1 < rows.length &&
                (rows[y + 1][x] == 'X' || rows[y + 1][x] == 'H');
            final onPlatform =
                y + 1 < rows.length && rows[y + 1][x] == '=';
            world.add(
              Coin(
                position: onFloor
                    ? Vector2(topLeft.x + tile / 2, floorTop - 4)
                    : onPlatform
                    ? Vector2(
                        topLeft.x + tile / 2,
                        (y + 1) * tile - tile * 0.45,
                      )
                    : topLeft + Vector2.all(tile / 2),
              ),
            );
          case 'A':
            world.add(
              ComputerProp(
                position: Vector2(topLeft.x + tile / 2, floorTop + 2),
                asset: 'levels/${level.number}/computadora.png',
              ),
            );
          case 'T':
            world.add(
              ComputerProp(
                position: Vector2(topLeft.x + tile / 2, floorTop + 2),
                asset: 'levels/${level.number}/computadora_tirada.png',
              ),
            );
          case 'E':
            world.add(Enemy(position: Vector2(topLeft.x, topLeft.y + tile)));
          case 'G':
            world.add(
              Goal(position: Vector2(topLeft.x + tile / 2, topLeft.y + tile)),
            );
          case 'D':
            world.add(
              SectorDoor(
                position: Vector2(topLeft.x + tile / 2, topLeft.y + tile),
                label: 'SECTOR SABER',
                isCorrect: true,
                color: const Color(0xFFD946A8),
              ),
            );
          case 'W':
            world.add(
              SectorDoor(
                position: Vector2(topLeft.x + tile / 2, topLeft.y + tile),
                label: 'SECTOR ECONOMÍA',
                isCorrect: false,
                color: const Color(0xFF3B82F6),
              ),
            );
          case 'P':
            spawnPoint = Vector2(topLeft.x, topLeft.y + tile);
        }
      }
    }

    player = Player(position: spawnPoint.clone());
    world.add(player);
    if (level.number == 2) {
      world.add(FlyingMonster());
    } else if (level.number == 3) {
      world.add(ChainsawMonster());
    }
    world.add(InstructionBubble());
  }

  void collectCoin() {
    coins += 1;
    if (energy < energySlots) energy += 1;
    audio.playSfx(SfxType.coin);
    hint = level.number >= 2
        ? 'La medialuna recarga tu energía'
        : 'Ahora buscá la puerta correcta';
    hud.value++;
  }

  void beginBattle() {
    if (finished || gameOver || !started) return;
    inBattle = true;
  }

  void useItem() {
    if (!canUseItem) return;
    tapAttack();
  }

  void tapAttack() {
    if (!started || finished || gameOver || !canAttack) return;
    player.flashAttack();
    if (!monsterReady) {
      audio.playSfx(SfxType.buttonTap);
      return;
    }
    if (level.number == 3) {
      for (final monster in world.children.whereType<ChainsawMonster>()) {
        if (!monster.appeared || monster.dying) continue;
        monster.stun();
      }
    }
    attackCharge++;
    audio.playSfx(SfxType.buttonTap);
    if (attackCharge >= clicksPerHit) {
      attackCharge = 0;
      monsterEnergy = (monsterEnergy - 1).clamp(0, energySlots);
      hud.value++;
      audio.playSfx(SfxType.stomp);
      if (monsterEnergy <= 0) {
        if (level.number == 3) {
          _onChainsawMonsterDefeated();
        } else {
          reachGoal();
        }
      }
    }
  }

  void _onChainsawMonsterDefeated() {
    for (final monster in world.children.whereType<ChainsawMonster>()) {
      monster.defeat();
    }
    _spawnLibraCorpExit();
    hint = '¡Lo venciste! Tocá la máquina Libra Corp';
    hud.value++;
  }

  void _spawnLibraCorpExit() {
    if (world.children.whereType<Goal>().isNotEmpty) return;
    final tile = LevelMaps.tileSize;
    final y = tile * 6;
    final startX = mapSize.x - tile * 8;
    for (var i = 0; i < 4; i++) {
      world.add(
        SolidBlock(
          position: Vector2(startX + i * tile, y),
          size: Vector2.all(tile),
          platform: true,
        ),
      );
    }
    world.add(Goal(position: Vector2(startX + tile * 2, y)));
  }

  void resolveBattle() {
    if (!inBattle || finished || gameOver) return;
    inBattle = false;
    energy = (energy - 1).clamp(0, energySlots);
    hud.value++;
    audio.playSfx(SfxType.hurt);
    if (energy <= 0) {
      hypnotizePlayer();
      return;
    }
    player.invulnerableTime = 0.55;
  }

  void laserHitPlayer() {
    if (finished || gameOver || player.fallingOut || player.hypnotized) return;
    if (player.invulnerableTime > 0) return;
    energy = (energy - 1).clamp(0, energySlots);
    hud.value++;
    audio.playSfx(SfxType.hurt);
    if (energy <= 0) {
      fallOffMap();
      return;
    }
    player.invulnerableTime = 0.8;
  }

  void fallOffMap() {
    if (gameOver || _won || player.fallingOut) return;
    finished = true;
    player.startFallingOut();
    audio.playSfx(SfxType.hurt);
  }

  void onFallFinished() {
    failLevel(message: 'Caíste');
  }

  void hypnotizePlayer() {
    if (gameOver || _won || player.hypnotized) return;
    finished = true;
    inBattle = false;
    energy = 0;
    hud.value++;
    player.startHypnotized();
    audio.playSfx(SfxType.hurt);
  }

  void onHypnotizedFinished() {
    failLevel(message: 'Te hipnotizaron');
  }

  void enterDoor(SectorDoor door) {
    if (_won || finished || gameOver) return;
    if (!door.isCorrect) {
      hint = 'SECTOR ECONOMÍA no abre';
      hud.value++;
      audio.playSfx(SfxType.buttonTap);
      return;
    }
    if (coins < 1) {
      hint = 'Comé una medialuna para abrir SECTOR SABER';
      hud.value++;
      audio.playSfx(SfxType.buttonTap);
      return;
    }
    if (door.opening) return;
    hint = 'SECTOR SABER se abre';
    hud.value++;
    finished = true;
    player.velocity.setZero();
    door.open();
  }

  void failLevel({String? message}) {
    if (gameOver) return;
    final alreadyFinished = finished;
    gameOver = true;
    finished = true;
    hint = message ??
        (level.number == 2
            ? 'Te hipnotizaron'
            : level.number == 3
            ? 'Caíste'
            : 'Te trabaste con una plataforma');
    hud.value++;
    if (!alreadyFinished) audio.playSfx(SfxType.hurt);
    _hideMobileHud();
    pauseEngine();
    overlays.add(gameOverOverlay);
  }

  void hurtPlayer() {
    if (level.number == 3) {
      laserHitPlayer();
      return;
    }
    if (finished || player.invulnerableTime > 0) return;
    lives -= 1;
    hud.value++;
    audio.playSfx(SfxType.hurt);
    if (lives <= 0) {
      gameOver = true;
      _hideMobileHud();
      pauseEngine();
      overlays.add(gameOverOverlay);
      return;
    }
    player.invulnerableTime = 1.4;
    player.position = spawnPoint.clone();
    player.velocity.setZero();
  }

  void reachGoal() {
    if (_won || gameOver) return;
    _won = true;
    finished = true;
    audio.playSfx(SfxType.congrats);
    _hideMobileHud();
    pauseEngine();
    overlays.add(winOverlay);
    onWon(coins);
  }

  void pauseGame() {
    if (gameOver || _won || overlays.isActive(pauseOverlay)) return;
    pauseEngine();
    overlays.add(pauseOverlay);
  }

  void resumeGame() {
    overlays.remove(pauseOverlay);
    if (!gameOver) resumeEngine();
  }

  void beginRun() {
    if (started || gameOver) return;
    started = true;
    world.children.whereType<InstructionBubble>().toList().forEach(
      (bubble) => bubble.removeFromParent(),
    );
    overlays.remove(playOverlay);
    _showMobileHud();
    hud.value++;
  }

  void _showMobileHud() {
    mobileHud?.removeFromParent();
    mobileHud = MobileHud();
    camera.viewport.add(mobileHud!);
  }

  void _hideMobileHud() {
    mobileHud?.removeFromParent();
    mobileHud = null;
  }

  void restartLevel() {
    lives = 3;
    started = false;
    input.clear();
    overlays.remove(gameOverOverlay);
    overlays.remove(pauseOverlay);
    overlays.remove(winOverlay);
    _hideMobileHud();
    resumeEngine();
    _loadLevel();
    _setupCamera();
    overlays.add(playOverlay);
    hud.value++;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (manualMove) {
      input.left =
          keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
          keysPressed.contains(LogicalKeyboardKey.keyA);
      input.right =
          keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
          keysPressed.contains(LogicalKeyboardKey.keyD);
    } else {
      input.left = false;
      input.right = false;
    }
    input.keyJump =
        keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
    if (canAttack && event is KeyDownEvent) {
      final attackKey =
          event.logicalKey == LogicalKeyboardKey.keyJ ||
          event.logicalKey == LogicalKeyboardKey.keyF ||
          event.logicalKey == LogicalKeyboardKey.keyK ||
          event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight;
      if (attackKey) tapAttack();
    }
    return KeyEventResult.handled;
  }
}
