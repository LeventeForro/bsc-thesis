// A Goblin ellenség és speciális képességeinek megvalósítása.
// Ez a komponens kezeli a fürge harci stílust, a mozgási szekvenciákat (Action Queue)
// és a távolsági támadások indítását.

import 'dart:math';
import '../battle_game.dart';
import 'enemy_base.dart';
import 'package:flame/game.dart';
import '../entity_component.dart';
import '../projectile_config.dart';
import '../action_queue.dart';

/// A Goblin ellenség osztálya, amely az agilitásra és a gyors támadásokra épít.
class Goblin extends EnemyBase {
  @override
  String get id => 'goblin';
  @override
  String get name => "GOBLIN";

  @override
  int get baseHPStat => 4;
  @override
  int get baseStr => 4;
  @override
  int get baseInt => 3;
  @override
  int get baseAgy => 12;
  @override
  int get baseLuck => 5;

  /// Statok skálázása: kiemelten az agilitás és a szerencse nő, extra HP-t csak ritkábban kap.
  @override
  void scaleStats(int pLevel) {
    int bonusPoints = (pLevel - 1) * 2;
    currentAgy += bonusPoints;
    currentLuck += (bonusPoints ~/ 2);
    currentHp += (pLevel ~/ 4);
  }

  /// Maximális életerő számítása a szint és a bázis HP alapján
  @override
  int get maxHealth => fixedMaxHealth ?? (currentHp * 8);

  /// A sebzés mértéke az agilitás statisztikából adódik.
  @override
  double get baseRawDamage => 5.0 + (currentAgy * 1.2);

  @override
  List<EnemyAttack> get attacks => [
        EnemyAttack(
            attackName: "ALATTOMOS SZÚRÁS",
            dmgScale: 1.2,
            animationState: EntityState.attack),
        EnemyAttack(
            attackName: "SNEAKY SLASH",
            dmgScale: 1.5,
            animationState: EntityState.melee),
        EnemyAttack(
            attackName: "RUSTY BOMB",
            dmgScale: 1.8,
            animationState: EntityState.spawn),
      ];

  /// Kombófüggő támadásválasztás: a játékos hibájának mértékétől függően egyre durvább válaszcsapást ad.
  @override
  EnemyAttack chooseAttack(int playerCombo) {
    if (playerCombo <= 2) return attacks[0];
    if (playerCombo == 3) return attacks[1];
    return attacks[2];
  }

  /// Kitérés esélyének számítása a játékos szintjéhez viszonyítva (magasabb szintű játékost nehezebb kijátszani).
  @override
  bool tryDodge(int playerLevel, String playerClass) {
    double dodgeChance = (currentAgy / (playerLevel * 2)) / 100.0;
    return Random().nextDouble() < dodgeChance;
  }

  /// Sebzésszámítás, ahol a játékos az agilitásával (reflexeivel) tudja mérsékelni a kapott sebet.
  @override
  EnemyDamageResult calculateDamage(
      EnemyAttack attack, Map<String, int> playerStats) {
    double rawDmg = baseRawDamage * attack.dmgScale;

    double critChance = (currentLuck * 0.5) / 100.0;
    bool isCrit = Random().nextDouble() < critChance;
    if (isCrit) rawDmg *= 2.0;

    double playerAgi = (playerStats['agility'] ?? 1).toDouble();
    int finalDmg = (rawDmg - playerAgi / 2.0).round().clamp(1, 999);

    return EnemyDamageResult(finalDmg, isCrit);
  }

  /// Animációk és a sprite megjelenítési paramétereinek (méret, pozíció eltolás) definíciója.
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Goblin',
        idlePath: 'animations/Goblin/Idle.png',
        idleFrames: 4,
        idleStep: 0.15,
        idleSize: Vector2(150, 150),
        walkPath: 'animations/Goblin/Run.png',
        walkFrames: 8,
        walkStep: 0.10,
        walkSize: Vector2(150, 150),
        attackPath: 'animations/Goblin/Attack1.png',
        attackFrames: 8,
        attackStep: 0.08,
        attackSize: Vector2(150, 150),
        meleePath: 'animations/Goblin/Attack2.png',
        meleeFrames: 8,
        meleeStep: 0.07,
        meleeSize: Vector2(150, 150),
        spawnPath: 'animations/Goblin/Attack3.png',
        spawnFrames: 12,
        spawnStep: 0.10,
        spawnSize: Vector2(150, 150),
        hitPath: 'animations/Goblin/Take Hit.png',
        hitFrames: 4,
        hitStep: 0.10,
        hitSize: Vector2(150, 150),
        deathPath: 'animations/Goblin/Death.png',
        deathFrames: 4,
        deathStep: 0.15,
        deathSize: Vector2(150, 150),
        sizeModifier: 1.40,
        xPos: 0.74,
        yPos: 0.57,
      );
}

/// Képességek logikai megvalósítása, amely kezeli a komplex mozgási szekvenciákat és projektileket.
mixin GoblinAbilities on FlameGame {
  BattleGame get _g => this as BattleGame;

  /// Alap támadó animáció sorba állítása.
  void triggerGoblinStab() {
    _g.enemy.actionQueue.clear();
    _g.enemy.actionQueue.add(PlayAnimationAction(EntityState.attack));
  }

  /// Összetett támadási szekvencia: odaszalad a játékoshoz, sebez, megfordul és visszamenekül.
  void triggerGoblinSneakySlash() {
    final en = _g.enemy;
    final homePos = en.position.clone();
    final attackPos = Vector2(_g.character.position.x + 60.0, en.position.y);

    final double distanceIn = (attackPos - homePos).length;
    final double speedIn = distanceIn > 0 ? distanceIn / 0.4 : 400.0;

    final double distanceOut = (homePos - attackPos).length;
    final double speedOut = distanceOut > 0 ? distanceOut / 0.4 : 400.0;

    en.actionQueue.clear();

    // 1. Megközelítés
    en.actionQueue.add(
        MoveAction(attackPos, speed: speedIn, moveState: EntityState.walk));

    // 2. Támadás végrehajtása
    en.actionQueue.add(PlayAnimationAction(EntityState.melee));

    // 3. Megfordulás a visszavonuláshoz
    en.actionQueue.add(CallbackAction(() {
      en.flipHorizontallyAroundCenter();
    }));

    // 4. Visszatérés az eredeti helyre
    en.actionQueue
        .add(MoveAction(homePos, speed: speedOut, moveState: EntityState.walk));

    // 5. Alapállapot visszaállítása
    en.actionQueue.add(CallbackAction(() {
      en.flipHorizontallyAroundCenter();
      en.playState(EntityState.idle);
    }));
  }

  /// Bombadobási animáció elindítása.
  void triggerGoblinBomb() {
    _g.enemy.actionQueue.clear();
    _g.enemy.actionQueue.add(PlayAnimationAction(EntityState.attack));
  }

  /// Különböző típusú távolsági támadások (projektilek) tényleges létrehozása a pályán.
  void triggerGoblinBombThrow() =>
      _g.spawnProjectile(ProjectileConfigs.goblinBomb,
          startOffset: Vector2(-70, -60));

  void triggerSkeletonThrow() =>
      _g.spawnProjectile(ProjectileConfigs.skeletonBone,
          startOffset: Vector2(-50, -40));

  void triggerFlyingEyeFireball() =>
      _g.spawnProjectile(ProjectileConfigs.flyingEyeFireball,
          startOffset: Vector2(-60, 0));

  void triggerMushroomSpore() =>
      _g.spawnProjectile(ProjectileConfigs.mushroomSpore,
          startOffset: Vector2(-40, -50));
}
