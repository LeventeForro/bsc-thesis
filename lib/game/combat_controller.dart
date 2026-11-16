// A harci logika központi vezérlője.
// Ez az osztály kezeli a hősök és ellenségek közötti interakciókat,
// a sebzésszámítást, a különleges képességek hatásait és az állapotváltozásokat.

import 'dart:math';
import '../game/heroes/hero_registry.dart';
import '../game/enemies/enemy_base.dart';

class CombatController {
  // --- AKTUÁLIS ÁLLAPOTOK (STATE) ---
  int playerMaxHealth;
  int playerHealth;
  int enemyHealth;
  EnemyBase currentEnemy;

  final String playerClass;
  final Map<String, int> playerStats;

  // --- AKTÍV BUFFOK, DEBUFFOK ÉS MECHANIKÁK ---
  int darkPactTurns = 0; // Necromancer: sebzésnövelő körök száma
  double darkPactMultiplier = 1.0;
  int armorBreakTurns = 0; // Íjász: páncéltörés időtartama
  double activeShield = 0.0; // Lovag: aktív pajzs mértéke
  double activeDodgeChance = 0.0; // Íjász: kitérési esély
  int dodgeCharges = 0; // Íjász: hátralévő kitérési lehetőségek
  int weakenTurns = 0; // Necromancer: ellenfél gyengítése
  int necroCurseTurns = 0; // Necromancer: átok időtartama
  bool isEffigyActive = false; // Necromancer: aktív bábu (védelem)

  CombatController({
    required this.playerMaxHealth,
    required this.playerHealth,
    required this.enemyHealth,
    required this.currentEnemy,
    required this.playerClass,
    required this.playerStats,
  });

  /// Új ellenfél példányosítása és életerejének inicializálása.
  void spawnNextEnemy(EnemyBase newEnemy) {
    currentEnemy = newEnemy;
    enemyHealth = newEnemy.maxHealth;
  }

  /// Az ellenfél gyógyítása, figyelembe véve a maximális életerő korlátot.
  void healEnemy(int amount) {
    enemyHealth = (enemyHealth + amount).clamp(0, currentEnemy.maxHealth);
  }

  /// A kör végén lefutó logika, amely csökkenti az aktív státuszhatások időtartamát.
  void advanceTurn() {
    if (armorBreakTurns > 0) armorBreakTurns--;
    if (weakenTurns > 0) weakenTurns--;
    if (necroCurseTurns > 0) necroCurseTurns--;
  }

  // --- 1. A JÁTÉKOS TÁMADÁSI LOGIKÁJA ---
  /// Kiszámítja a játékos támadásának eredményét a választott képesség (skillCost) alapján.
  Map<String, dynamic> executePlayerAttack(int skillCost) {
    final hero = HeroRegistry.getHero(playerClass);
    final skill = hero.skills[skillCost];
    if (skill == null) return {'hits': [], 'isDodged': false, 'isDead': false};

    double baseDamage = skill.formula(playerStats);
    final int delay = skill.delayMs;
    final List<Map<String, dynamic>> hits = [];
    final random = Random();

    // Necromancer: Sötét Paktum bónusz érvényesítése
    if (playerClass == 'necromancer' && darkPactTurns > 0) {
      baseDamage *= darkPactMultiplier;
      darkPactTurns--;
    }

    // Kitérés ellenőrzése az ellenség agilitása alapján
    if (currentEnemy.tryDodge(playerStats['lvl']!, playerClass)) {
      return {'hits': [], 'isDodged': true, 'isDead': false, 'delayMs': delay};
    }

    // --- SPECIÁLIS KOMBINÁLT TÁMADÁSOK (LOVAG ÉS ÍJÁSZ 3-AS SKILL) ---
    if ((playerClass == 'knight' || playerClass == 'archer') &&
        skillCost == 3) {
      final damageMultipliers = [
        0.6,
        0.9,
        1.3
      ]; // Növekvő sebzés minden ütésnél
      final critChances = [0.05, 0.15, 0.30]; // Növekvő kritikus esély
      final delaysAfter = [350, 350, 0];

      for (int i = 0; i < 3; i++) {
        double hitDmg = baseDamage * damageMultipliers[i];
        if (armorBreakTurns > 0) hitDmg *= 1.5;
        hitDmg = currentEnemy.calculateIncomingDamage(hitDmg, playerClass);

        final luck = playerStats['luck']! * 0.01;
        final bool isCrit =
            random.nextDouble() < (luck + critChances[i]).clamp(0.0, 0.95);
        if (isCrit) hitDmg *= 1.5;

        final int finalHit = hitDmg.round();
        enemyHealth -= finalHit;
        hits.add({
          'damage': finalHit,
          'isCrit': isCrit,
          'delayAfter': delaysAfter[i]
        });
      }
    }

    // --- ÍJÁSZ 4-ES KÉPESSÉG: PÁNCÉLTÖRŐ KIVÉGZÉS ---
    else if (playerClass == 'archer' && skillCost == 4) {
      // 1. Kezdő nagy csapás
      double bigHitDmg = baseDamage * 0.8;
      bigHitDmg = currentEnemy.calculateIncomingDamage(bigHitDmg, playerClass);
      final bool isCritBig =
          random.nextDouble() < (playerStats['luck']! * 0.01);
      if (isCritBig) bigHitDmg *= 1.5;
      final int finalBigHit = bigHitDmg.round();
      enemyHealth -= finalBigHit;
      hits.add({'damage': finalBigHit, 'isCrit': isCritBig, 'delayAfter': 600});

      armorBreakTurns = 2; // Debuff felhelyezése az ellenfélre

      // 2. Sorozatlövés/vágás (7 gyors találat)
      for (int i = 0; i < 7; i++) {
        double smallHitDmg = baseDamage * 0.15;
        if (armorBreakTurns > 0) smallHitDmg *= 1.5;
        smallHitDmg =
            currentEnemy.calculateIncomingDamage(smallHitDmg, playerClass);
        final bool isCritSmall =
            random.nextDouble() < (playerStats['luck']! * 0.01 + 0.1);
        if (isCritSmall) smallHitDmg *= 1.5;
        final int finalSmallHit = smallHitDmg.round();
        enemyHealth -= finalSmallHit;
        hits.add({
          'damage': finalSmallHit,
          'isCrit': isCritSmall,
          'delayAfter': 100
        });
      }
    }

    // --- NECROMANCER SPECIÁLIS ÁTOK-MECHANIKÁI ---
    else if (playerClass == 'necromancer' && skillCost == 3) {
      double dmg =
          currentEnemy.calculateIncomingDamage(baseDamage, playerClass);
      final bool isCrit = random.nextDouble() < (playerStats['luck']! * 0.01);
      if (isCrit) dmg *= 1.5;
      weakenTurns = 3; // Ellenfél sebzésének csökkentése
      final int finalHit = dmg.round();
      enemyHealth -= finalHit;
      hits.add({'damage': finalHit, 'isCrit': isCrit});
    } else if (playerClass == 'necromancer' && skillCost == 4) {
      necroCurseTurns = 1;
      final bool isCrit = random.nextDouble() <
          (playerStats['luck']! * 0.01 + 0.80); // Szinte garantált kritikus
      if (isCrit) baseDamage *= 1.5;
      final int finalHit = baseDamage.round();
      enemyHealth -= finalHit;
      hits.add({'damage': finalHit, 'isCrit': isCrit});
    }

    // --- ÁLTALÁNOS TÁMADÁSOK KEZELÉSE ---
    else {
      if (armorBreakTurns > 0) baseDamage *= 1.5;
      final bool isCrit =
          random.nextDouble() < (playerStats['luck']! * 0.01).clamp(0.05, 0.5);
      if (isCrit) baseDamage *= 1.5;
      final int finalHit = baseDamage.round();
      enemyHealth -= finalHit;
      hits.add({'damage': finalHit, 'isCrit': isCrit});
    }

    return {
      'hits': hits,
      'isDodged': false,
      'isDead': enemyHealth <= 0,
      'delayMs': delay,
      'comboRefund': skill.comboRefund,
    };
  }

  // --- 2. AZ ELLENSÉG TÁMADÁSI LOGIKÁJA ---
  /// Kezeli az ellenfél válaszcsapását és a játékos különböző védekező mechanizmusait.
  Map<String, dynamic> executeEnemyAttack(int playerCombo) {
    advanceTurn(); // Körök léptetése a buffokhoz

    if (playerClass == 'necromancer' && darkPactTurns > 0) {
      darkPactTurns--;
    }

    final attack = currentEnemy.chooseAttack(playerCombo);
    final result = currentEnemy.calculateDamage(attack, playerStats);
    int finalDamage = result.damage;

    // 1. Necromancer védelem: A bábu elnyeli a teljes sebzést
    if (isEffigyActive) {
      isEffigyActive = false;
      return {
        'damage': 0,
        'isCrit': false,
        'attackName': attack.attackName,
        'animation': attack.animationState,
        'isDead': false,
        'effigyDestroyed': true,
      };
    }

    // 2. Íjász védelem: Kitérési esély (töltetek alapú)
    if (dodgeCharges > 0) {
      final bool dodged = Random().nextDouble() < activeDodgeChance;
      dodgeCharges--;
      if (dodged) {
        return {
          'damage': 0,
          'isCrit': false,
          'attackName': attack.attackName,
          'animation': attack.animationState,
          'isDead': false,
          'playerDodged': true,
        };
      }
    }

    // 3. Lovag védelem: Százalékos pajzs a beérkező ütésre
    if (activeShield > 0) {
      finalDamage = (finalDamage * (1.0 - activeShield)).round();
      activeShield = 0.0; // A pajzs egy ütés után elhasználódik
    }

    playerHealth -= finalDamage;

    return {
      'damage': finalDamage,
      'isCrit': result.isCrit,
      'attackName': attack.attackName,
      'animation': attack.animationState,
      'isDead': playerHealth <= 0,
    };
  }
}
