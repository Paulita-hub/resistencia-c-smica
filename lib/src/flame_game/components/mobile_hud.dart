import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';

import '../game_layout.dart';
import '../resistencia_game.dart';

/// Controles táctiles fijos en el viewport (no se mueven con la cámara).
///
/// Sprites en `assets/images/hud/controls/`:
/// - joystick_background.png
/// - joystick_knob.png
/// - button_jump.png
/// - button_attack.png
/// - button_item.png
class MobileHud extends Component with HasGameReference<ResistenciaGame> {
  static const backgroundPath = 'hud/controls/joystick_background.png';
  static const knobPath = 'hud/controls/joystick_knob.png';
  static const jumpPath = 'hud/controls/button_jump.png';
  static const attackPath = 'hud/controls/button_attack.png';
  static const itemPath = 'hud/controls/button_item.png';

  static const _hudPriority = 100;

  HorizontalJoystickComponent? joystick;
  late final HudButtonComponent jumpButton;
  HudButtonComponent? attackButton;
  HudButtonComponent? useButton;

  EdgeInsets _safeInsets() {
    final ctx = game.buildContext;
    if (ctx == null || !ctx.mounted) return EdgeInsets.zero;
    final pad = MediaQuery.paddingOf(ctx);
    return pad;
  }

  @override
  Future<void> onLoad() async {
    final jumpSprite = await game.loadSprite(jumpPath);

    final safe = _safeInsets();
    final ui = game.size.y > 0 ? game.size.y / GameLayout.height : 1.0;
    final jumpSize = GameLayout.jumpButton * ui;

    if (game.manualMove) {
      final backgroundSprite = await game.loadSprite(backgroundPath);
      final knobSprite = await game.loadSprite(knobPath);
      final joyBg = GameLayout.joystick * ui;
      final joyKnob = GameLayout.joystickKnob * ui;
      joystick = HorizontalJoystickComponent(
        knob: SpriteComponent(
          sprite: knobSprite,
          size: Vector2.all(joyKnob),
          paint: _joystickPaint(),
        ),
        background: SpriteComponent(
          sprite: backgroundSprite,
          size: Vector2.all(joyBg),
          paint: _joystickPaint(),
        ),
        margin: EdgeInsets.only(
          left: 36 + safe.left,
          bottom: 40 + safe.bottom,
        ),
        priority: _hudPriority,
      );
    }

    jumpButton = _actionButton(
      sprite: jumpSprite,
      label: 'Saltar',
      size: jumpSize,
      margin: EdgeInsets.only(
        right: 28 + safe.right,
        bottom: 36 + safe.bottom,
      ),
      onPressed: () => game.input.hudJump = true,
      onReleased: () => game.input.hudJump = false,
    );

    if (game.canAttack) {
      final attackSprite = await game.loadSprite(attackPath);
      final attackSize = GameLayout.attackButton * ui;
      attackButton = _actionButton(
        sprite: attackSprite,
        label: 'Atacar',
        size: attackSize,
        margin: EdgeInsets.only(
          right: 28 + jumpSize + 20 + safe.right,
          bottom: 48 + safe.bottom,
        ),
        onPressed: game.tapAttack,
      );
    }

    if (game.canUseItem) {
      final itemSprite = await game.loadSprite(itemPath);
      useButton = _actionButton(
        sprite: itemSprite,
        label: 'Usar',
        size: 140,
        margin: EdgeInsets.only(
          right: 48 + safe.right,
          bottom: 36 + jumpSize + 24 + safe.bottom,
        ),
        onPressed: game.useItem,
      );
    }

    if (joystick != null) {
      await game.camera.viewport.add(joystick!);
    }
    await game.camera.viewport.add(jumpButton);
    if (attackButton != null) {
      await game.camera.viewport.add(attackButton!);
    }
    if (useButton != null) {
      await game.camera.viewport.add(useButton!);
    }
  }

  static Paint _joystickPaint() {
    return Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = const ColorFilter.matrix(<double>[
        1, 0, 0, 0, 18,
        0, 1, 0, 0, 18,
        0, 0, 1, 0, 18,
        0, 0, 0, 2.8, 0,
      ]);
  }

  HudButtonComponent _actionButton({
    required Sprite sprite,
    required String label,
    required double size,
    required EdgeInsets margin,
    required void Function() onPressed,
    void Function()? onReleased,
  }) {
    final buttonSize = Vector2.all(size);
    final downSize = buttonSize * 0.86;
    final downOffset = (buttonSize - downSize) / 2 + Vector2(0, size * 0.05);
    return HudButtonComponent(
      button: SpriteComponent(sprite: sprite, size: buttonSize),
      buttonDown: PositionComponent(
        size: buttonSize,
        children: [
          CircleComponent(
            radius: size * 0.5,
            position: buttonSize / 2,
            anchor: Anchor.center,
            paint: Paint()..color = const Color(0x66FFFFFF),
          ),
          SpriteComponent(
            sprite: sprite,
            size: downSize,
            position: downOffset,
            paint: Paint()
              ..colorFilter = const ColorFilter.mode(
                Color(0x88FFFFFF),
                BlendMode.srcATop,
              ),
          ),
        ],
      ),
      margin: margin,
      onPressed: onPressed,
      onReleased: () {
        onReleased?.call();
      },
      onCancelled: () {
        onReleased?.call();
      },
      priority: _hudPriority,
      children: [
        TextComponent(
          text: label,
          anchor: Anchor.center,
          position: buttonSize / 2,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Color(0xCC000000), blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final stick = joystick;
    if (stick == null || !stick.isMounted) return;
    game.input.joystickX = stick.relativeDelta.x;
  }

  @override
  void onRemove() {
    game.input.joystickX = 0;
    game.input.hudJump = false;
    joystick?.removeFromParent();
    jumpButton.removeFromParent();
    attackButton?.removeFromParent();
    useButton?.removeFromParent();
    super.onRemove();
  }
}

/// Joystick de Flame limitado al eje X (correr izquierda/derecha).
class HorizontalJoystickComponent extends JoystickComponent {
  HorizontalJoystickComponent({
    required super.knob,
    required super.background,
    super.margin,
    super.priority,
  });

  @override
  void update(double dt) {
    super.update(dt);
    delta.y = 0;
    knob?.position.y = size.y / 2;
    intensity = knobRadius == 0
        ? 0
        : (delta.x.abs() / knobRadius).clamp(0.0, 1.0);
  }
}
