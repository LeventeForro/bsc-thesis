// A harci mechanizmusok logikai magja.
// Ez a komponens határozza meg a kritikus találatok valószínűségét és a beérkező sebzés
// mérséklését (mitigation) a támadó és a védő osztályfüggő statisztikái alapján.

import 'dart:math';

class BattleEngine {
  /// Kritikus találat esélyének meghatározása a szerencse (luck) stat alapján.
  /// Az esély minimum 5%, maximum 50% lehet.
  static bool isCrit(int luck, int level) {
    double chance = (luck / (level * 5)).clamp(0.05, 0.5);
    return Random().nextDouble() < chance;
  }

  /// Kiszámítja a sebzéscsökkentés mértékét (0.0 - 0.8 tartományban).
  /// A csökkentés alapja a támadó kasztjához rendelt ellentétes védelmi statisztika.
  static double getMitigation(
      String attackerClass, Map<String, dynamic> defenderStats) {
    int statValue = 1;

    // Meghatározzuk, melyik stat véd az adott támadó típus ellen
    if (attackerClass == 'knight') statValue = defenderStats['strength'];
    if (attackerClass == 'archer') statValue = defenderStats['agility'];
    if (attackerClass == 'necromancer') statValue = defenderStats['intellect'];

    // Százalékosítás: minden 10 statpont 1% sebzéscsökkentést jelent, maximum 80%-ig.
    return (statValue / 1000).clamp(0.0, 0.8);
  }
}
