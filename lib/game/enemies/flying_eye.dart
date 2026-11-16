// A Flying Eye ellenfél implementációja.
// Jellemzője a magas intelligencia és mozgékonyság (agility), cserébe viszonylag kevés az életereje.
// Varázssebzést oszt, és képes kitérni a fizikai támadások elől.

import 'package:flame/components.dart';
import 'dart:math';
import 'enemy_base.dart';
import '../entity_component.dart';

class FlyingEye extends EnemyBase {
  @override
  String get id => 'flyingEye';
  @override
  String get name => "ANCIENT WATCHER";

  // Alap statisztikák (1. szinten)
  @override
  int get baseHPStat => 3;
  @override
  int get baseStr => 2;
  @override
  int get baseInt => 13;
  @override
  int get baseAgy => 5;
  @override
  int get baseLuck => 5;

  /// Szintfüggő skálázódás: főleg az Intelligencia és az Agility növekszik.
  @override
  void scaleStats(int pLevel) {
    int bonusPoints = (pLevel - 1) * 2;
    currentInt += bonusPoints;
    currentAgy += (bonusPoints ~/ 2);
  }

  /// Viszonylag alacsony (törékeny) maximális életerő.
  @override
  int get maxHealth => fixedMaxHealth ?? (currentHp * 8 + (currentLvl * 4));

  /// A nyers sebzés kizárólag az Intelligencia alapján skálázódik.
  @override
  double get baseRawDamage => 6.0 + (currentInt * 1.6);

  /// Az ellenfél 3 különböző erejű támadási formája.
  @override
  List<EnemyAttack> get attacks => [
        EnemyAttack(
            attackName: "ATTACK1",
            dmgScale: 1.0,
            animationState: EntityState.attack),
        EnemyAttack(
            attackName: "ATTACK2",
            dmgScale: 1.5,
            animationState: EntityState.melee),
        EnemyAttack(
            attackName: "ATTACK3",
            dmgScale: 2.0,
            animationState: EntityState.spawn),
      ];

  /// A játékos elrontott kombójának hossza alapján büntet:
  /// minél nagyobb volt a kombó, mielőtt rontott, annál erősebbet támad vissza.
  @override
  EnemyAttack chooseAttack(int playerCombo) {
    if (playerCombo <= 2) return attacks[0];
    if (playerCombo == 3) return attacks[1];
    return attacks[2];
  }

  /// Egyedi sebzésszámítás: varázslatot használ, így a játékos intelligenciája
  /// (varázsellenállás) csökkenti a sebzést, nem a fizikai védelem.
  @override
  EnemyDamageResult calculateDamage(
      EnemyAttack attack, Map<String, int> playerStats) {
    double rawDmg = baseRawDamage * attack.dmgScale;

    // Kritikus találat esélyének kiszámítása a szerencse (luck) alapján
    double critChance = (currentLuck * 0.8) / 100.0;
    bool isCrit = Random().nextDouble() < critChance;
    if (isCrit) rawDmg *= 2.0;

    // A játékos intelligenciája felfogja a bejövő mágikus sebzés egy részét
    double playerInt = (playerStats['intellect'] ?? 1).toDouble();
    int finalDmg = (rawDmg - playerInt / 2.0).round().clamp(1, 999);

    return EnemyDamageResult(finalDmg, isCrit);
  }

  /// Kitérési esély számítása.
  /// Csak a fizikai támadók (Lovag, Íjász) elől tud kitérni, a mágikus támadások elől nem.
  @override
  bool tryDodge(int playerLevel, String playerClass) {
    if (playerClass == 'knight' || playerClass == 'archer') {
      double dodgeChance = (currentAgy / 3.0) / 100.0;
      return Random().nextDouble() < dodgeChance;
    }
    return false;
  }

  /// A Flame motorhoz tartozó vizuális beállítások (Sprite-ok, méretek és animációs sebességek).
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Flying Eye',
        // IDLE
        idlePath: 'animations/flyingEye/Flight.png',
        idleFrames: 8,
        idleStep: 0.15,
        idleSize: Vector2(150, 150),
        // WALK
        walkPath: 'animations/flyingEye/Flight.png',
        walkFrames: 8,
        walkStep: 0.10,
        walkSize: Vector2(150, 150),
        // ATTACK1
        attackPath: 'animations/flyingEye/Attack1.png',
        attackFrames: 8,
        attackStep: 0.08,
        attackSize: Vector2(150, 150),
        // ATTACK2
        meleePath: 'animations/flyingEye/Attack2.png',
        meleeFrames: 8,
        meleeStep: 0.08,
        meleeSize: Vector2(150, 150),
        // ATTACK3
        spawnPath: 'animations/flyingEye/Attack3.png',
        spawnFrames: 6,
        spawnStep: 0.08,
        spawnSize: Vector2(150, 150),
        // HIT
        hitPath: 'animations/flyingEye/Take Hit.png',
        hitFrames: 4,
        hitStep: 0.10,
        hitSize: Vector2(150, 150),
        // DEATH
        deathPath: 'animations/flyingEye/Death.png',
        deathFrames: 4,
        deathStep: 0.15,
        deathSize: Vector2(150, 150),
        // Egyéb megjelenési beállítások (eltolások a játéktéren)
        sizeModifier: 1.40,
        xPos: 0.74,
        yPos: 0.57,
      );
}
