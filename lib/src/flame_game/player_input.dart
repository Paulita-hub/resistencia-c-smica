class PlayerInput {
  bool left = false;
  bool right = false;
  bool jumpHeld = false;
  bool attackHeld = false;

  double get axisX {
    var value = 0.0;
    if (left) value -= 1;
    if (right) value += 1;
    return value;
  }

  void clear() {
    left = false;
    right = false;
    jumpHeld = false;
    attackHeld = false;
  }
}
