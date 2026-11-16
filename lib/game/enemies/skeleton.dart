// A Skeleton ellenfél megvalósítása.
// Erős fizikai harcos, aki lassú mozgással, de jelentős sebzéssel és szívóssággal rendelkezik.
// Különlegessége a "Csontpajzs", amely védelmet nyújt a fizikai támadások ellen.

import 'package:flame/components.dart';
import 'dart:math';
import 'enemy_base.dart';
import '../entity_component.dart';

class Skeleton extends EnemyBase {
  @override
  String get id => 'skeleton';
  @override
  String get name => "SKELETON WARRIOR";

  // Alap statisztikák (1. szinten) - fizikai harcosra optimalizálva
  @override
  int get baseHPStat => 5;
  @override
  int get baseStr => 12;
  @override
  int get baseInt => 2;
  @override
  int get baseAgy => 3;
  @override
  int get baseLuck => 3;

  /// Statok skálázása a szintlépéskor: az Erő (Str) és az életerő (HP) dominál.
  @override
  void scaleStats(int pLevel) {
    int bonusPoints = (pLevel - 1) * 2;
    currentStr += bonusPoints;
    currentHp += (bonusPoints ~/ 3);
  }

  /// Maximális életerő kiszámítása a bázis életerő stat alapján.
  @override
  int get maxHealth => fixedMaxHealth ?? currentHp * 6;

  /// A nyers sebzés skálázása a szinttel növekvő fizikai erő alapján.
  @override
  double get baseRawDamage => 8.0 + (currentStr * 1.5);

  @override
  List<EnemyAttack> get attacks => [
        EnemyAttack(
            attackName: "RUSTY SWORD",
            dmgScale: 1.0,
            animationState: EntityState.attack),
        EnemyAttack(
            attackName: "BONE CRUSHER",
            dmgScale: 1.4,
            animationState: EntityState.melee),
        EnemyAttack(
            attackName: "EXECUTION",
            dmgScale: 1.8,
            animationState: EntityState.spawn),
      ];

  /// Támadásválasztás a játékos kombója alapján: bünteti a rontott hosszú sorozatokat.
  @override
  EnemyAttack chooseAttack(int playerCombo) {
    if (playerCombo <= 2) return attacks[0];
    if (playerCombo == 3) return attacks[1];
    return attacks[2];
  }

  /// Sebzésszámítás: a játékos ereje (Str) szolgál fizikai védelemként a támadások ellen.
  @override
  EnemyDamageResult calculateDamage(
      EnemyAttack attack, Map<String, int> playerStats) {
    double rawDmg = baseRawDamage * attack.dmgScale;

    // A játékos ereje csökkenti a fizikai sebzést
    double playerStr = (playerStats['strength'] ?? 1).toDouble();
    int finalDmg = (rawDmg - playerStr / 2.0).round().clamp(1, 999);

    return EnemyDamageResult(finalDmg, false);
  }

  /// Csontpajzs logika: fizikai kasztok (Lovag, Íjász) ellen passzív sebzéscsökkentést kap.
  @override
  double calculateIncomingDamage(double rawDamage, String playerClass) {
    if (playerClass == 'knight' || playerClass == 'archer') {
      double boneShield = currentStr / 2.0;
      return max(1.0, rawDamage - boneShield);
    }
    return rawDamage;
  }

  /// Flame motor animációs és megjelenítési konfigurációja (sprite-ok és pozicionálás).
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Skeleton',
        idlePath: 'animations/Skeleton/Idle.png',
        idleFrames: 4,
        idleStep: 0.15,
        idleSize: Vector2(150, 150),
        walkPath: 'animations/Skeleton/Walk.png',
        walkFrames: 4,
        walkStep: 0.10,
        walkSize: Vector2(150, 150),
        attackPath: 'animations/Skeleton/Attack1.png',
        attackFrames: 8,
        attackStep: 0.08,
        attackSize: Vector2(150, 150),
        meleePath: 'animations/Skeleton/Attack2.png',
        meleeFrames: 8,
        meleeStep: 0.08,
        meleeSize: Vector2(150, 150),
        spawnPath: 'animations/Skeleton/Attack3.png',
        spawnFrames: 6,
        spawnStep: 0.08,
        spawnSize: Vector2(150, 150),
        hitPath: 'animations/Skeleton/Take Hit.png',
        hitFrames: 4,
        hitStep: 0.10,
        hitSize: Vector2(150, 150),
        deathPath: 'animations/Skeleton/Death.png',
        deathFrames: 4,
        deathStep: 0.15,
        deathSize: Vector2(150, 150),
        sizeModifier: 1.40,
        xPos: 0.74,
        yPos: 0.57,
      );
}
