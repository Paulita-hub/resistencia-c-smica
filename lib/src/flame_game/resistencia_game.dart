import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../level_selection/levels.dart';
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
import 'components/player.dart';
import 'components/sector_door.dart';
import 'components/solid_block.dart';
import 'components/starfield.dart';
import 'level_maps.dart';
import 'player_input.dart';

class ResistenciaGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
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
  static const clicksToResist = 8;
  int energy = startingEnergy;
  int monsterEnergy = energySlots;
  int lives = 3;
  bool inBattle = false;
  int attackCharge = 0;
  int pulseClicks = 0;
  bool started = false;
  bool finished = false;
  bool gameOver = false;
  bool _won = false;
  String hint = '';
  final hud = ValueNotifier<int>(0);
  double _cameraX = 0;

  /// Nivel 2: el jugador elige avanzar o retroceder. El 1 sigue en auto-run.
  bool get manualMove => level.number == 2;

  static const hudOverlay = 'hud';
  static const controlsOverlay = 'controls';
  static const gameOverOverlay = 'gameOver';
  static const playOverlay = 'play';
  static const pauseOverlay = 'pause';

  @override
  Future<void> onLoad() async {
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
    }
  }

  void _setupCamera() {
    if (size.x <= 0 || size.y <= 0 || mapSize.y <= 0) return;
    camera.stop();
    camera.setBounds(null);
    camera.viewfinder.anchor = Anchor.topLeft;
    // Toda la altura del mapa entra en pantalla: el piso queda abajo, visible.
    camera.viewfinder.zoom = size.y / mapSize.y;
    _scrollCameraX();
  }

  void _scrollCameraX([double dt = 0]) {
    final zoom = camera.viewfinder.zoom;
    if (zoom.isNaN || zoom <= 0) return;
    final viewW = size.x / zoom;
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
    }
  }

  bool get monsterReady {
    for (final child in world.children.whereType<FlyingMonster>()) {
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
    energy = level.number == 2 ? energySlots : startingEnergy;
    monsterEnergy = energySlots;
    inBattle = false;
    attackCharge = 0;
    pulseClicks = 0;
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

    world.add(
      GroundLayer(
        position: Vector2(0, floorTop),
        size: Vector2(mapSize.x, floorHeight),
      ),
    );

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
              ),
            );
          case 'C':
            final onFloor =
                y + 1 < rows.length &&
                (rows[y + 1][x] == 'X' || rows[y + 1][x] == 'H');
            world.add(
              Coin(
                position: onFloor
                    ? Vector2(topLeft.x + tile / 2, floorTop - 4)
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
    }
    world.add(InstructionBubble());
  }

  void collectCoin() {
    coins += 1;
    if (energy < energySlots) energy += 1;
    audio.playSfx(SfxType.coin);
    hint = level.number == 2
        ? 'La medialuna recarga tu energía'
        : 'Ahora buscá la puerta correcta';
    hud.value++;
  }

  void beginBattle() {
    if (finished || gameOver || !started) return;
    inBattle = true;
    pulseClicks = 0;
  }

  void tapAttack() {
    if (!started || finished || gameOver || !manualMove) return;
    player.flashAttack();
    if (!monsterReady) return;
    attackCharge++;
    if (inBattle) pulseClicks++;
    audio.playSfx(SfxType.buttonTap);
    if (attackCharge >= clicksPerHit) {
      attackCharge = 0;
      monsterEnergy = (monsterEnergy - 1).clamp(0, energySlots);
      hud.value++;
      audio.playSfx(SfxType.stomp);
      if (monsterEnergy <= 0) {
        reachGoal();
      }
    }
  }

  void resolveBattle() {
    if (!inBattle || finished || gameOver) return;
    inBattle = false;
    if (pulseClicks >= clicksToResist) {
      return;
    }
    energy = (energy - 1).clamp(0, energySlots);
    hud.value++;
    audio.playSfx(SfxType.hurt);
    player.invulnerableTime = 0.55;
    if (energy <= 0) {
      hypnotizePlayer();
    }
  }

  void resolveHypnosisPulse() {
    resolveBattle();
  }

  void hypnotizePlayer() {
    if (finished || gameOver) return;
    finished = true;
    inBattle = false;
    player.velocity.setZero();
    player.startHypnotized();
    hint = 'Te hipnotizaron';
    hud.value++;
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
        (level.number == 2 ? 'Te hipnotizaron' : 'Te trabaste con una plataforma');
    hud.value++;
    if (!alreadyFinished) audio.playSfx(SfxType.hurt);
    pauseEngine();
    overlays.add(gameOverOverlay);
  }

  void hurtPlayer() {
    if (finished || player.invulnerableTime > 0) return;
    lives -= 1;
    hud.value++;
    audio.playSfx(SfxType.hurt);
    if (lives <= 0) {
      gameOver = true;
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
    overlays.add(controlsOverlay);
    hud.value++;
  }

  void restartLevel() {
    lives = 3;
    started = false;
    input.clear();
    overlays.remove(gameOverOverlay);
    overlays.remove(pauseOverlay);
    overlays.remove(controlsOverlay);
    resumeEngine();
    _loadLevel();
    _setupCamera();
    overlays.add(playOverlay);
    hud.value++;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!started || finished || gameOver) return;
    if (manualMove) {
      tapAttack();
    } else {
      input.jumpHeld = true;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    input.jumpHeld = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    input.jumpHeld = false;
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
    input.jumpHeld =
        keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
    if (manualMove && event is KeyDownEvent) {
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
