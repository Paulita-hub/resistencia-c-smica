class PlayerInput {
  bool left = false;
  bool right = false;
  bool hudJump = false;
  bool keyJump = false;
  bool attackHeld = false;

  /// Eje horizontal del [JoystickComponent] HUD, en [-1, 1].
  double joystickX = 0;

  static const deadzone = 0.2;

  bool get jumpHeld => hudJump || keyJump;

  double get axisX {
    if (joystickX.abs() > deadzone) {
      return joystickX.clamp(-1.0, 1.0);
    }
    var value = 0.0;
    if (left) value -= 1;
    if (right) value += 1;
    return value;
  }

  void clear() {
    left = false;
    right = false;
    hudJump = false;
    keyJump = false;
    attackHeld = false;
    joystickX = 0;
  }
}
