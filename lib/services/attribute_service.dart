// Ez a szolgáltatás felelős a hősök attribútumainak és harci értékeinek kiszámításáért.
// Meghatározza a maximális életerőt, a kritikus találati esélyt és a beérkező sebzés csökkentését
// a karakterosztály (Knight, Archer, Necromancer) és a kiosztott statisztikai pontok alapján.

import 'dart:math';

class AttributeService {
  // --- KONSTANS ALAPÉRTÉKEK ---

  /// A támadások alapvető sebzése minden egységre.
  static const double baseDamage = 10.0;

  /// Az alap életerő, amelyre a Vitality pontok bónusza rakódik rá.
  static const int baseHp = 30;

  // --- ÉLETERŐ (HP) SZÁMÍTÁSA ---

  /// Kiszámítja a hős maximális életerőpontját.
  /// [characterClass]: A hős kasztja, amely meghatározza a Vitality szorzóját.
  /// [vitality]: A hős Vitality (Állóképesség) attribútumának aktuális szintje.
  static int getMaxHealth(String characterClass, int vitality) {
    // Alapértelmezett szorzó az Íjásznak (Archer: 10x)
    double multiplier = 5;

    // A Lovag kapja a legtöbb HP-t (Knight: 15x), a Necromancer közepesen szívós (12x)
    if (characterClass == 'knight') multiplier = 8;
    if (characterClass == 'necromancer') multiplier = 6;

    // Formula: AlapHP + (Pontok * KasztSzorzó)
    return baseHp + (vitality * multiplier).round();
  }

  // --- KRITIKUS ÜTÉS ESÉLY SZÁMÍTÁSA ---

  /// Meghatározza egy véletlenszerű generálással, hogy a támadás kritikus-e.
  /// [luck]: A hős Szerencse (Luck) statisztikája.
  static bool checkCriticalHit(String characterClass, int luck) {
    // Alapértelmezett szorzó az Íjásznak (Archer: 0.3% / pont)
    double multiplier = 0.003;

    // A Lovagnak kevésbé (0.1%), a Necromancernak közepesen (0.2%) számít a szerencse
    if (characterClass == 'knight') multiplier = 0.001;
    if (characterClass == 'necromancer') multiplier = 0.002;

    double chance = luck * multiplier;

    // Játékegyensúly: Az esély sosem lehet kevesebb 5%-nál és több 60%-nál
    return Random().nextDouble() < chance.clamp(0.05, 0.60);
  }

  // --- BEÉRKEZŐ SEBZÉS SZÁMÍTÁSA ---

  /// Kiszámítja a ténylegesen elszenvedett sebzést a védekezési statisztikák levonása után.
  /// [rawDamage]: Az ellenség által okozott nyers sebzés.
  /// [enemyType]: Meghatározza, hogy milyen típusú védekezést (STR, AGI, INT) kell használni.
  static int calculateDamageTaken({
    required double rawDamage,
    required String playerClass,
    required String enemyType,
    required int str,
    required int agi,
    required int intel,
  }) {
    double resistanceValue = 0;

    // Speciális védekezési logika: Az ellenállás típusa az ellenség támadási formájától függ
    switch (enemyType) {
      case 'knight':
        // Fizikai ütés ellen a Strength (Erő) felel a védelemért
        resistanceValue = str.toDouble();
        break;
      case 'archer':
        // Távolsági lövedékek ellen az Agility (Ügyesség) ad védelmet/kitérést
        resistanceValue = agi.toDouble();
        break;
      case 'necromancer':
        // Mágikus átkok ellen az Intellect (Intelligencia) biztosít ellenállást
        resistanceValue = intel.toDouble();
        break;
    }

    // A sebzéscsökkentés mértéke: az adott ellenállás 50%-a levonódik a nyers sebzésből
    double finalDamage = rawDamage - (resistanceValue / 2);

    // Garantáljuk, hogy a hős legalább 1 sebzést kapjon (ne legyen sebezhetetlen)
    return max(1, finalDamage.round());
  }
}
