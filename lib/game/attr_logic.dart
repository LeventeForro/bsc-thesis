// A harcrendszer matematikai alapjait és az attribútumok (statok) logikáját tartalmazó segédosztály.
// Ez a fájl felelős a sebzés, a kritikus találat esélye és a szintfüggő skálázódás kiszámításáért.

import 'dart:math';

class AttrLogic {
  /// Szintfüggő skálázási szorzó meghatározása.
  /// Segít abban, hogy a tulajdonságok hatása a szint növekedésével arányosan csökkenjen (diminishing returns).
  static double getScalingFactor(int statValue, int level, double multiplier) {
    if (level <= 0) level = 1;
    return (statValue / (level * 1.5)) * multiplier;
  }

  /// Kritikus ütés esélyének meghatározása a szerencse (luck) és a szint alapján.
  /// Az esélyt egy 5% és 50% közötti tartományba korlátozza.
  static bool isCriticalHit(int luck, int level) {
    double chance = (luck / (level * 5)).clamp(0.05, 0.50);
    return Random().nextDouble() < chance;
  }

  /// A végső sebzés kiszámítása a támadó bónuszai, a védő ellenállása és a kritikus szorzó alapján.
  static int calculateFinalDamage({
    required int baseDamage,
    required double attackerBonus,
    required double defenderResist,
    bool isCrit = false,
  }) {
    // A védekezés (resist) legfeljebb a sebzés 80%-át képes elnyelni.
    double rawDamage =
        (baseDamage + attackerBonus) * (1.0 - defenderResist.clamp(0, 0.8));

    // Kritikus találat esetén a sebzés értéke megduplázódik.
    if (isCrit) rawDamage *= 2.0;

    return rawDamage.round();
  }
}
