// Az összes elérhető ellenségtípus központi nyilvántartója (Registry) és gyártója (Factory).
//
// Felelős az új szörnyek példányosításáért és a véletlenszerű sorsolásért.

import 'dart:math';
import 'enemy_base.dart';
import 'skeleton.dart';
import 'goblin.dart';
import 'flying_eye.dart';
import 'mushroom.dart';

/// Az ellenfelek központi regisztere. Gyár (Factory) mintát használ a példányosításhoz.
class EnemyRegistry {
  static final Random _rng = Random();

  /// A regisztrált szörnyek és a hozzájuk tartozó gyárfüggvények (amik legyártják a példányt).
  static final Map<String, EnemyBase Function()> _factories = {
    'skeleton': () => Skeleton(),
    'goblin': () => Goblin(),
    'flyingEye': () => FlyingEye(),
    'mushroom': () => Mushroom(),
  };

  /// Véletlenszerűen sorsol egy szörnyet a regisztráltak közül, a játékos szintjéhez igazítva.
  static EnemyBase getRandomEnemy(int playerLevel) {
    final ids = _factories.keys.toList();
    final randomId = ids[_rng.nextInt(ids.length)];

    return getEnemyById(randomId, playerLevel: playerLevel);
  }

  /// Legyárt egy specifikus szörnyet az ID-ja (pl. 'goblin') alapján.
  /// Biztonsági okokból, ha ismeretlen ID-t kap, egy Gombát (mushroom) ad vissza.
  static EnemyBase getEnemyById(String id,
      {int playerLevel = 1, Map<String, int>? fixedStats}) {
    // Gyár lekérése (vagy alapértelmezett, ha nem létezik az id)
    final factory = _factories[id] ?? _factories['mushroom']!;

    // A konkrét szörny-objektum létrehozása
    final enemy = factory();

    // A statok és a maximális életerő felskálázása a játékos szintjéhez
    enemy.initialize(playerLevel, fixedStats: fixedStats);

    return enemy;
  }
}
