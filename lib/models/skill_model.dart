// A hősök által használt aktív és passzív képességek (Skillek) adatmodellje.
// Ez az osztály határozza meg, hogy egy adott képesség milyen animációt vált ki,
// mennyi kombó-pontba kerül, és milyen matematikai képlet alapján számítja a sebzést.

import '../game/entity_component.dart';

/// Függvénytípus definiálása a sebzésképletekhez.
/// A hős aktuális statisztikáit (str, agi, int, stb.) várja bemenetként.
typedef DamageFormula = double Function(Map<String, int> stats);

class Skill {
  final String name; // A képesség megnevezése (pl. "Pajzsütés")
  final EntityState
      animation; // A hozzárendelt vizuális állapot az EntityComponent-ben
  final DamageFormula formula; // A sebzést meghatározó algoritmus
  final int comboCost; // A használathoz szükséges erőforrás (kombó pont)
  final int
      comboRefund; // Sikeres használat után visszakapott pontok (pl. lánctámadásokhoz)
  final int
      delayMs; // Késleltetés: az animáció indulása és a sebzés kiírása közti idő
  final String description; // Felhasználóbarát leírás a képesség hatásáról

  /// Egy hős képességének logikai paramétereit inicializáló konstruktor.
  Skill({
    required this.name,
    required this.animation,
    required this.formula,
    this.comboCost = 0,
    this.comboRefund = 0,
    this.delayMs = 400,
    this.description = "",
  });
}
