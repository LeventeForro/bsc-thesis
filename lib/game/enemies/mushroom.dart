// A Mushroom ellenfél megvalósítása.
// Egy lassú, tank típusú karakter, amely kiemelkedően magas életerővel rendelkezik.
// Különlegessége, hogy sebzése nem az erejéből, hanem a szívósságából (HP) fakad.

import 'package:flame/components.dart';
import 'enemy_base.dart';
import '../entity_component.dart';

class Mushroom extends EnemyBase {
  @override
  String get id => 'mushroom';
  @override
  String get name => "BLOOD MUSHROOM";

  // Alap statisztikák (1. szinten) - magas bázis életerő
  @override
  int get baseHPStat => 8;
  @override
  int get baseStr => 5;
  @override
  int get baseInt => 5;
  @override
  int get baseAgy => 2;
  @override
  int get baseLuck => 3;

  /// Szintlépéskor kapott pontok elosztása: elsősorban az életerőt növeli.
  @override
  void scaleStats(int pLevel) {
    int bonusPoints = (pLevel - 1) * 2;
    currentHp += bonusPoints;
    currentStr += (bonusPoints ~/ 2);
  }

  /// Maximális életerő számítása extra 1.5x szorzóval a tank szerepkör miatt.
  @override
  int get maxHealth =>
      fixedMaxHealth ?? ((currentHp * 5 + (currentLvl * 2)) * 1.2).round();

  /// Egyedi sebzésmechanika: a sebzés az aktuális HP statisztikától függ.
  @override
  double get baseRawDamage => 3.0 + (currentHp * 0.5);

  @override
  List<EnemyAttack> get attacks => [
        EnemyAttack(
            attackName: "SPORE CLOUD",
            dmgScale: 1.0,
            animationState: EntityState.attack),
        EnemyAttack(
            attackName: "POISON TOUCH",
            dmgScale: 1.3,
            animationState: EntityState.melee),
        EnemyAttack(
            attackName: "MUSHROOM SLAM",
            dmgScale: 1.7,
            animationState: EntityState.spawn),
      ];

  /// Regenerációs érték meghatározása a szívósság alapján.
  int get regenerationValue => (currentHp / 2).round();

  /// Támadásválasztás a játékos kombója alapján.
  @override
  EnemyAttack chooseAttack(int playerCombo) {
    if (playerCombo <= 2) return attacks[0];
    if (playerCombo == 3) return attacks[1];
    return attacks[2];
  }

  /// Sebzésszámítás: a játékos életereje (vitality) csökkenti a kapott sebet.
  /// A gomba típusú ellenfél nem tud kritikus találatot okozni.
  @override
  EnemyDamageResult calculateDamage(
      EnemyAttack attack, Map<String, int> playerStats) {
    double rawDmg = baseRawDamage * attack.dmgScale;

    double playerVit = (playerStats['vitality'] ?? 1).toDouble();
    int finalDmg = (rawDmg - playerVit / 2.0).round().clamp(1, 999);

    return EnemyDamageResult(finalDmg, false);
  }

  /// Flame motor animációs és megjelenítési konfigurációja.
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Mushroom',
        idlePath: 'animations/Mushroom/Idle.png',
        idleFrames: 4,
        idleStep: 0.15,
        idleSize: Vector2(150, 150),
        walkPath: 'animations/Mushroom/Run.png',
        walkFrames: 8,
        walkStep: 0.10,
        walkSize: Vector2(150, 150),
        attackPath: 'animations/Mushroom/Attack1.png',
        attackFrames: 8,
        attackStep: 0.08,
        attackSize: Vector2(150, 150),
        meleePath: 'animations/Mushroom/Attack2.png',
        meleeFrames: 8,
        meleeStep: 0.08,
        meleeSize: Vector2(150, 150),
        spawnPath: 'animations/Mushroom/Attack3.png',
        spawnFrames: 11,
        spawnStep: 0.08,
        spawnSize: Vector2(150, 150),
        hitPath: 'animations/Mushroom/Take Hit.png',
        hitFrames: 4,
        hitStep: 0.10,
        hitSize: Vector2(150, 150),
        deathPath: 'animations/Mushroom/Death.png',
        deathFrames: 4,
        deathStep: 0.15,
        deathSize: Vector2(150, 150),
        sizeModifier: 1.40,
        xPos: 0.74,
        yPos: 0.57,
      );
}
