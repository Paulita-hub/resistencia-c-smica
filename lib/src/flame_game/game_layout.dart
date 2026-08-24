import 'package:flame/components.dart';

/// Lienzo lógico del juego: celular horizontal Full HD (1920×1080).
///
/// Tamaños pensados para pulgar (Apple 44pt, Material 48dp ≈ 9 mm) y para
/// que el personaje ocupe ~15–20% del lado corto, las medialunas ~80–100 px
/// y las plataformas no se pierdan.
class GameLayout {
  static const width = 1920.0;
  static const height = 1080.0;

  static Vector2 get resolution => Vector2(width, height);

  /// El mapa viejo usaba 48 px; en Full HD el escenario se veía miniatura.
  static const tileSize = 96.0;

  /// ~15–20% del lado corto (1080) una vez encajado el mapa.
  static const playerWidth = 128.0;

  /// El nivel 2 hace más zoom (mapa más bajo); se achica para verse como el 1.
  static double playerWidthFor(int level) => level == 2 ? 96.0 : playerWidth;

  /// Collectible. Mismo tamaño en todos los niveles.
  static const coinWidth = 48.0;

  static double coinWidthFor(int level) => coinWidth;

  /// Grosor mínimo de plataforma (si el PNG es una tira fina).
  static const platformMinHeight = 44.0;

  /// Joystick y acciones: 9–12 mm en un celular 5–6", pulgares a los costados.
  static const joystick = 220.0;
  static const joystickKnob = 110.0;
  static const jumpButton = 248.0;
  static const attackButton = 232.0;

  static const gravity = 3600.0;
  static const jumpSpeed = -1520.0;
  static const moveSpeed = 460.0;
}
