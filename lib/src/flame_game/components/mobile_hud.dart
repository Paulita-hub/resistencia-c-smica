import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';

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

  late final HorizontalJoystickComponent joystick;
  late final HudButtonComponent jumpButton;
  HudButtonComponent? attackButton;
  HudButtonComponent? useButton;

  @override
  Future<void> onLoad() async {
    final backgroundSprite = await game.loadSprite(backgroundPath);
    final knobSprite = await game.loadSprite(knobPath);
    final jumpSprite = await game.loadSprite(jumpPath);
    final attackSprite = await game.loadSprite(attackPath);
    final itemSprite = await game.loadSprite(itemPath);

    final compact = game.size.y < 520;
    final joyBg = compact ? 88.0 : 112.0;
    final joyKnob = compact ? 44.0 : 56.0;
    final jumpSize = compact ? 62.0 : 76.0;
    final attackSize = compact ? 56.0 : 68.0;

    joystick = HorizontalJoystickComponent(
      knob: SpriteComponent(
        sprite: knobSprite,
        size: Vector2.all(joyKnob),
      ),
      background: SpriteComponent(
        sprite: backgroundSprite,
        size: Vector2.all(joyBg),
      ),
      margin: EdgeInsets.only(left: compact ? 20 : 36, bottom: compact ? 16 : 24),
      priority: _hudPriority,
    );

    jumpButton = _actionButton(
      sprite: jumpSprite,
      label: 'Saltar',
      size: jumpSize,
      margin: EdgeInsets.only(right: compact ? 18 : 28, bottom: compact ? 14 : 24),
      onPressed: () => game.input.hudJump = true,
      onReleased: () => game.input.hudJump = false,
    );

    attackButton = _actionButton(
      sprite: attackSprite,
      label: 'Atacar',
      size: attackSize,
      margin: EdgeInsets.only(
        right: compact ? 88 : 118,
        bottom: compact ? 16 : 28,
      ),
      onPressed: game.tapAttack,
    );

    // Tercer botón del cluster (Usar objeto). Sin mecánica propia todavía.
    useButton = _actionButton(
      sprite: itemSprite,
      label: 'Usar',
      size: 64,
      margin: const EdgeInsets.only(right: 58, bottom: 112),
      onPressed: game.useItem,
    );

    await game.camera.viewport.add(joystick);
    await game.camera.viewport.add(jumpButton);
    if (game.canAttack) {
      await game.camera.viewport.add(attackButton!);
    }
    if (game.canUseItem) {
      await game.camera.viewport.add(useButton!);
    }
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
    return HudButtonComponent(
      button: SpriteComponent(sprite: sprite, size: buttonSize),
      buttonDown: SpriteComponent(
        sprite: sprite,
        size: buttonSize,
      )..opacity = 0.55,
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
    if (!joystick.isMounted) return;
    game.input.joystickX = joystick.relativeDelta.x;
  }

  @override
  void onRemove() {
    game.input.joystickX = 0;
    game.input.hudJump = false;
    joystick.removeFromParent();
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
