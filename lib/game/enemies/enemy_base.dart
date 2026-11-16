// Az ellenfelek alaposztálya és a harci számításokhoz használt adatstruktúrák.
// Kezeli a statok szintfüggő skálázódását és a sebzéskiosztást.

import 'dart:math';
import '../battle_engine.dart';
import '../entity_component.dart';

/// Egy adott ellenséges támadás adatai.
class EnemyAttack {
  final String attackName;
  final double dmgScale; // Sebzésszorzó (alapsebzés * dmgScale)
  final EntityState animationState;
  final double armorPenPercent; // Páncéltörés mértéke (0.0 - 1.0)

  EnemyAttack({
    required this.attackName,
    required this.dmgScale,
    required this.animationState,
    this.armorPenPercent = 0.0,
  });
}

/// Egy támadás végeredménye.
class EnemyDamageResult {
  final int damage;
  final bool isCrit;

  EnemyDamageResult(this.damage, this.isCrit);
}

/// Az összes ellenfél ősosztálya.
abstract class EnemyBase {
  static final Random _rng = Random();

  String get id;
  String get name;

  // Alap statok (1-es szinten)
  int get baseHPStat;
  int get baseStr;
  int get baseInt;
  int get baseAgy;
  int get baseLuck;

  // Aktuális, játékoshoz skálázott statok
  int currentHp = 0;
  int currentStr = 0;
  int currentInt = 0;
  int currentAgy = 0;
  int currentLuck = 0;
  int currentLvl = 1;

  EntityConfig get entityConfig;
  List<EnemyAttack> get attacks;

  int? fixedMaxHealth; // fix HP a story miatt

  /// Inicializálja az alap statokat a megadott játékosszint alapján.
  void initialize(int playerLevel, {Map<String, int>? fixedStats}) {
    currentLvl = playerLevel;

    if (fixedStats != null) {
      // FIX STATOK BEÁLLÍTÁSA (STORY)
      currentHp = fixedStats['hp'] ?? baseHPStat;
      currentStr = fixedStats['str'] ?? baseStr;
      currentInt = fixedStats['intel'] ?? baseInt;
      currentAgy = fixedStats['agy'] ?? baseAgy;
      currentLuck = fixedStats['luck'] ?? baseLuck;
      fixedMaxHealth = fixedStats['maxHealth'];
    } else {
      // DINAMIKUS SKÁLÁZÁS (Custom / AI mód)
      currentHp = baseHPStat;
      currentStr = baseStr;
      currentInt = baseInt;
      currentAgy = baseAgy;
      currentLuck = baseLuck;
      scaleStats(playerLevel);
    }
  }

  int get maxHealth => fixedMaxHealth ?? (currentHp * 5 + (currentLvl * 10));

  /// Szintfüggő stat növekedés, amit a leszármazottakban kell implementálni.
  void scaleStats(int pLevel);

  double get baseRawDamage;

  /// Véletlenszerű támadást választ a listából.
  EnemyAttack chooseAttack(int playerCombo) {
    return attacks[_rng.nextInt(attacks.length)];
  }

  /// Kiszámolja, kitér-e a szörny. Alapértelmezésben nem térnek ki.
  bool tryDodge(int playerLevel, String playerClass) => false;

  /// Kiszámolja a játékosnak okozott tényleges sebzést a védelem és páncéltörés figyelembevételével.
  EnemyDamageResult calculateDamage(
      EnemyAttack attack, Map<String, int> playerStats) {
    double rawDmg = baseRawDamage * attack.dmgScale;

    // Védelem (mitigation) kiszámítása és a páncéltörés érvényesítése
    double mitigation = BattleEngine.getMitigation(id, playerStats);
    mitigation *= (1.0 - attack.armorPenPercent);

    // Végső sebzés, ami legalább 1 kell hogy legyen
    int finalDmg = (rawDmg * (1.0 - mitigation)).round().clamp(1, 999);

    return EnemyDamageResult(finalDmg, false);
  }

  /// A szörnyet érő sebzés módosítása (pl. specifikus ellenállás vagy immunitás esetén).
  double calculateIncomingDamage(double rawDamage, String playerClass) =>
      rawDamage;
}
