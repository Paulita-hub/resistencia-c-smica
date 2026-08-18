import 'package:flame/components.dart';

/// Mapas de tiles.
///
/// `.` vacío  `X` suelo  `H` hueco (piso roto)  `=` plataforma  `P` jugadora
/// `C` objeto para comer  `W` puerta incorrecta  `D` puerta correcta
/// `A` computadora  `T` computadora tirada  `E` enemigo  `G` meta
class LevelMaps {
  static const tileSize = 48.0;

  /// El piso (ground / broken) ocupa este porcentaje de la altura de pantalla.
  static const floorScreenFraction = 0.25;

  static double floorTopY(List<String> rows) {
    for (var y = 0; y < rows.length; y++) {
      if (rows[y].contains('X') || rows[y].contains('H')) {
        return y * tileSize;
      }
    }
    return rows.length * tileSize;
  }

  static Vector2 mapSizeFor(List<String> rows) {
    final width = rows.first.length * tileSize;
    final floorTop = floorTopY(rows);
    final floorH = floorVisualHeightFor(rows);
    if (floorTop <= 0) {
      return Vector2(width, rows.length * tileSize);
    }
    // Un poco de aire abajo para que el piso no se corte con el borde.
    return Vector2(width, floorTop + floorH + 16);
  }

  static double floorVisualHeightFor(List<String> rows) {
    final floorTop = floorTopY(rows);
    if (floorTop <= 0) return tileSize * 2;
    return floorTop * floorScreenFraction / (1 - floorScreenFraction);
  }

  static List<String> forLevel(int number) {
    return switch (number) {
      1 => _normalize(level1),
      2 => _normalize(level2),
      _ => _normalize(level3),
    };
  }

  static List<String> _normalize(List<String> rows) {
    final width = rows.fold<int>(0, (w, row) => row.length > w ? row.length : w);
    return [for (final row in rows) row.padRight(width, '.')];
  }

  /// Islas de suelo con grietas angostas, como en el gif de referencia.
  static const level1 = [
    '.......C.......C.......C.......C........',
    '.......=.......=.......=.......=........',
    '......==......==......==......==........',
    'P.........W.................D...........',
    'XXXXXXHHXXXXXXHHXXXXXXHHXXXXXXHHXXXXXXXX',
  ];

  /// Piso continuo, computadoras en el suelo y medialunas en el aire.
  static const level2 = [
    '................................................',
    '........C...........C.............C.............',
    '...............C..........C..............C......',
    'P....A......T...........A....T..........A.......',
    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  ];

  static const level3 = [
    '........................................................................',
    '..............C..............C............C.........C...................',
    '............====...........====.........====......=======...............',
    'P.....E........E...........E..............E.....C..............C.....G..',
    'XXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHH',
    'XXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHHXXXXXHHHH',
  ];
}
