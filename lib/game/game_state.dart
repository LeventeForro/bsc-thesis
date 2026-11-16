// A játékmenet-állapot menedzser megvalósítása.
// Ez az osztály felelős a Flutter UI és a Flame játékmotor közötti kommunikációért,
// a hősök és ellenségek akcióinak időzítéséért, valamint a harci ciklus vezérléséért.

import 'package:flutter/material.dart';
import '../game/battle_game.dart';
import '../game/combat_controller.dart';
import '../game/enemies/enemy_base.dart';
import '../game/enemies/enemy_registry.dart';
import '../game/enemies/mushroom.dart';
import '../game/heroes/hero_registry.dart';
import '../game/entity_component.dart';

class GameStateManager {
  final BattleGame battleGame; // A Flame alapú játékmotor
  final CombatController combatController; // A matematikai harci logika

  // Callback függvények a UI frissítéséhez és az események jelzéséhez
  final void Function(void Function()) setState;
  final void Function(bool win) onGameEnd;
  final void Function() onNextQuestion;

  // Harci változók
  int playerHealth;
  int enemyHealth;
  int defeatedMonsters;
  int currentCombo;
  bool isAttacking;
  int playerLevel;
  String characterClass;
  int maxHealth;

  // Aktív módosítók (Buffok)
  double activeShield;
  double activeDodgeChance;
  int dodgeCharges;
  int darkPactTurns;
  double darkPactMultiplier;

  bool isQuestionsFinished = false;
  final bool isStoryMode;

  GameStateManager({
    required this.battleGame,
    required this.combatController,
    required this.setState,
    required this.onGameEnd,
    required this.onNextQuestion,
    required this.playerHealth,
    required this.enemyHealth,
    required this.defeatedMonsters,
    required this.currentCombo,
    required this.characterClass,
    required this.playerLevel,
    required this.maxHealth,
    this.isAttacking = false,
    this.activeShield = 0.0,
    this.activeDodgeChance = 0.0,
    this.dodgeCharges = 0,
    this.darkPactTurns = 0,
    this.darkPactMultiplier = 1.0,
    this.isStoryMode = false,
  });

  // --- TÁMADÁS INDÍTÁSA ---

  /// A játékos által választott képesség végrehajtása.
  /// Ellenőrzi a kombó-költséget, levonja a pontokat és szinkronizálja az animációkat a sebzéssel.
  void executeAttack(int cost) {
    if (isAttacking || currentCombo < cost) return;

    final hero = HeroRegistry.getHero(characterClass);
    final skill = hero.skills[cost];
    if (skill == null) return;

    setState(() {
      isAttacking = true;
      // Levonjuk a költséget és hozzáadjuk az esetleges visszatérítést (refund)
      currentCombo = (currentCombo - cost) + skill.comboRefund;
    });

    // Ha a képesség nem támadó, hanem segítő (Buff), azt a speciális kezelő végzi
    if (_tryHandleBuff(cost)) return;

    // Vizuális effektusok indítása a Flame motorban
    hero.triggerSkillVisuals(cost, battleGame);

    // Logikai sebzés kiszámítása a kontrollerrel
    final result = combatController.executePlayerAttack(cost);

    setState(() {
      darkPactTurns = combatController.darkPactTurns;
    });

    // Késleltetés: megvárjuk az animáció "becsapódási" pillanatát a sebzés kiírása előtt
    Future.delayed(Duration(milliseconds: skill.delayMs), () async {
      await _applyPlayerAttackResult(result, cost);
      _checkAfterAttackLifeCycle();
    });
  }

  /// A hősök védekező vagy erősítő képességeinek (buff) logikai megvalósítása.
  bool _tryHandleBuff(int cost) {
    // LOVAG: Pajzs (Sebzéscsökkentés a Vitality alapján)
    if (characterClass == 'knight' && cost == 2) {
      final vit = combatController.playerStats['vit'] ?? 1;
      setState(() {
        activeShield = (vit / (playerLevel * 2)).clamp(0.1, 0.6);
        combatController.activeShield = activeShield;
      });
      battleGame.triggerDefensiveStance();
      Future.delayed(
          const Duration(milliseconds: 1500), _checkAfterAttackLifeCycle);
      return true;
    }

    // ÍJÁSZ: Kitérés (Agility alapú esély a támadás elkerülésére)
    if (characterClass == 'archer' && cost == 2) {
      final agi = combatController.playerStats['agi'] ?? 1;
      setState(() {
        activeDodgeChance = (0.1 + (agi / (playerLevel * 100))).clamp(0.1, 0.7);
        dodgeCharges = 3;
        combatController.activeDodgeChance = activeDodgeChance;
        combatController.dodgeCharges = dodgeCharges;
      });
      battleGame.triggerArcherDodgeBuff();
      Future.delayed(
          const Duration(milliseconds: 1500), _checkAfterAttackLifeCycle);
      return true;
    }

    // NEKROMANTA: Sötét Paktum (HP feláldozása extra sebzőerőért)
    if (characterClass == 'necromancer' && cost == 2) {
      final intel = combatController.playerStats['intel'] ?? 1;
      final selfDmg = (maxHealth * 0.15).round().clamp(1, maxHealth);
      combatController.playerHealth -= selfDmg;
      setState(() {
        playerHealth = combatController.playerHealth;
        darkPactTurns = 3;
        darkPactMultiplier = 1.4 + (intel / 100).clamp(0.0, 0.3);
        combatController.darkPactTurns = darkPactTurns;
        combatController.darkPactMultiplier = darkPactMultiplier;
      });
      battleGame
        ..updatePlayerHealth(playerHealth)
        ..showDamage(selfDmg, isPlayer: true)
        ..triggerNecroDarkPact();
      Future.delayed(
          const Duration(milliseconds: 1500), _checkAfterAttackLifeCycle);
      return true;
    }

    return false;
  }

  /// A támadás során keletkezett sebzések és találati animációk megjelenítése.
  Future<void> _applyPlayerAttackResult(
      Map<String, dynamic> result, int cost) async {
    // Ha az ellenfél kitért a támadás elől
    if (result['isDodged'] == true) {
      battleGame.showDamage(0, isPlayer: false, dodged: true);
      battleGame.enemy.playState(EntityState.hit);
      return;
    }

    final hits = result['hits'] as List? ?? [];
    final hitDelay = characterClass == 'archer' ? 150 : 350;

    // Sorozattámadások kezelése (több sebzésszám egymás után)
    for (int i = 0; i < hits.length; i++) {
      final hit = hits[i];
      setState(() => enemyHealth -= (hit['damage'] as int));

      battleGame
        ..updateEnemyHealth(enemyHealth)
        ..showDamage(hit['damage'], isPlayer: false, isCrit: hit['isCrit']);

      if ((hit['damage'] as int) > 0) battleGame.triggerEnemyHit();

      if (i < hits.length - 1) {
        await Future.delayed(
            Duration(milliseconds: hit['delayAfter'] ?? hitDelay));
      }
    }

    setState(() => enemyHealth = combatController.enemyHealth);
    if (result['isDead'] == true) battleGame.triggerEnemyDeath();

    // Animációs lecsengési idő beállítása képességenként
    int finishDelay = 800;
    if (characterClass == 'archer' && cost == 4) finishDelay = 1500;
    if (characterClass == 'necromancer' && cost == 4) finishDelay = 2000;
    await Future.delayed(Duration(milliseconds: finishDelay));
  }

  /// Ellenőrzi az ellenség állapotát támadás után. Kezeli a halált és az új ellenfél behívását.
  void _checkAfterAttackLifeCycle() {
    if (enemyHealth <= 0) {
      defeatedMonsters++;

      // Ha Story mód akkor vége a játéknak.
      if (isStoryMode) {
        onGameEnd(true);
        return;
      }

      // Nekromanta passzív: ölés után megmarad/frissül a bónusz sebzés
      if (characterClass == 'necromancer' && darkPactTurns > 0) {
        combatController.darkPactTurns++;
        setState(() {
          darkPactTurns = combatController.darkPactTurns;
        });
      }

      // Játék vége ellenőrzése
      if (isQuestionsFinished && currentCombo == 0) {
        setState(() => isAttacking = false);
        onGameEnd(true);
      } else {
        // Új véletlenszerű ellenfél generálása a regiszterből
        final newEnemy = EnemyRegistry.getRandomEnemy(playerLevel);
        combatController.spawnNextEnemy(newEnemy);

        setState(() {
          enemyHealth = combatController.enemyHealth;
          isAttacking = false;
        });

        // Flame motor frissítése az új szörny adataival
        battleGame.spawnNewEnemyConfig(newEnemy.entityConfig, enemyHealth);
        battleGame.updateEnemyHealth(enemyHealth);
      }
    } else {
      setState(() => isAttacking = false);
      if (isQuestionsFinished && currentCombo == 0) onGameEnd(true);
    }
  }

  // --- ELLENSÉG TÁMADÁSA (ROSSZ VÁLASZ ESETÉN) ---

  /// Az ellenfél visszatámadásának indítása, ha a játékos helytelenül válaszolt.
  void handleWrongAnswer() {
    final result = combatController.executeEnemyAttack(currentCombo);
    setState(() =>
        currentCombo = 0); // Rossz válasz esetén elveszik a felhalmozott kombó

    _playEnemyAnimation(result);

    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        playerHealth = combatController.playerHealth;
        // Védekező értékek frissítése az ütés után
        activeShield = combatController.activeShield;
        dodgeCharges = combatController.dodgeCharges;
        activeDodgeChance = combatController.activeDodgeChance;
        darkPactTurns = combatController.darkPactTurns;
      });

      battleGame.updatePlayerHealth(playerHealth);
      _applyEnemyAttackResult(result);
      _checkEndOfTurnLogic();
    });
  }

  /// Az ellenség típusától függő támadási animációk és projektilek (lövedékek) kezelése.
  void _playEnemyAnimation(Map<String, dynamic> result) {
    final enemyId = combatController.currentEnemy.id;
    final attackName = result['attackName'] as String;
    final animation = result['animation'] as EntityState;

    battleGame.enemy.playState(animation);

    // Projektil időzítések és típusok szörnyenként definiálva
    final Map<String, _ProjectileTrigger> projectiles = {
      'goblin/RUSTY BOMB':
          _ProjectileTrigger(700, () => battleGame.triggerGoblinBombThrow()),
      'skeleton/EXECUTION':
          _ProjectileTrigger(500, () => battleGame.triggerSkeletonThrow()),
      'flyingEye/ATTACK3':
          _ProjectileTrigger(300, () => battleGame.triggerFlyingEyeFireball()),
      'mushroom/MUSHROOM SLAM':
          _ProjectileTrigger(500, () => battleGame.triggerMushroomSpore()),
    };

    final entry = projectiles['$enemyId/$attackName'];
    if (entry != null) {
      Future.delayed(Duration(milliseconds: entry.delayMs), entry.trigger);
    }
  }

  /// Az ellenség támadásának hatása a játékosra (sebzés, kitérés, pajzs).
  void _applyEnemyAttackResult(Map<String, dynamic> result) {
    if (result['effigyDestroyed'] == true) {
      battleGame.showDamage(0, isPlayer: true, baseColor: Colors.purpleAccent);
    } else if (result['playerDodged'] == true) {
      battleGame.showDamage(0, isPlayer: true, dodged: true);
      battleGame.character.playState(EntityState.hit);
    } else {
      battleGame.showDamage(result['damage'],
          isPlayer: true, isCrit: result['isCrit']);
      if ((result['damage'] as int) > 0) battleGame.triggerCharacterHit();
    }

    if (result['isDead'] == true) battleGame.triggerCharacterDeath();
  }

  // --- KÖR VÉGE ÉS KIÉRTÉKELÉS ---

  /// A válasz kiértékelése utáni visszacsatolás és kör végi mechanizmusok (pl. regeneráció).
  void showFeedback(bool isCorrect, {required EnemyBase? mushroomEnemy}) {
    combatController.advanceTurn(); // Körök léptetése a buffokhoz

    setState(() {
      darkPactTurns = combatController.darkPactTurns;
    });

    // Speciális: A Gomba (Mushroom) típusú ellenfelek minden kör végén gyógyulnak
    if (mushroomEnemy is Mushroom) {
      final heal = mushroomEnemy.regenerationValue;
      combatController.healEnemy(heal);
      enemyHealth = combatController.enemyHealth;
      battleGame.updateEnemyHealth(enemyHealth);
      battleGame.showDamage(heal,
          isPlayer: false, isCrit: false, baseColor: Colors.greenAccent);
    }

    if (isCorrect) {
      if (currentCombo < 4) currentCombo++;
      _checkEndOfTurnLogic();
    } else {
      handleWrongAnswer();
    }
  }

  /// Megvizsgálja a játékos állapotát a kör végén, és dönt a folytatásról.
  void _checkEndOfTurnLogic() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (playerHealth <= 0) {
        onGameEnd(false); // Vereség
      } else {
        onNextQuestion(); // Következő kérdés
      }
    });
  }
}

/// Segédosztály a lövedékek (projektilek) időzített indításához.
class _ProjectileTrigger {
  final int delayMs;
  final void Function() trigger;
  const _ProjectileTrigger(this.delayMs, this.trigger);
}
