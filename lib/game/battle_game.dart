// A játék fő motorja (FlameGame), amely összefogja a harci logikát, a vizuális elemeket és az animációkat.
// Felelős a hősök és ellenségek képességeinek (Mixin-ek), a projektilek, az életerő-csíkok
// és a sebzés-szövegek koordinálásáért a képernyőn.

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors, FilterQuality;
import 'package:flutter/widgets.dart';
import 'entity_component.dart';
import '../widgets/health_bar.dart';
import '../widgets/damage_text.dart';
import '../game/heroes/hero_registry.dart';
import '../game/projectile_config.dart';
import '../game/heroes/knight.dart';
import '../game/heroes/archer.dart';
import '../game/heroes/necromancer.dart';
import '../game/enemies/goblin.dart';

class BattleGame extends FlameGame
    with
        KnightAbilities,
        ArcherAbilities,
        NecromancerAbilities,
        GoblinAbilities {
  final int playerMaxHealth;
  final int enemyMaxHealth;
  final String playerClass;
  final EntityConfig initialEnemyConfig;

  late EntityComponent character;
  late EntityComponent enemy;
  late HealthBarComponent playerBar;
  late HealthBarComponent enemyBar;
  late SpriteComponent bgComponent;

  BattleGame({
    required this.playerMaxHealth,
    required this.enemyMaxHealth,
    required this.initialEnemyConfig,
    this.playerClass = 'knight',
  });

  @override
  Color backgroundColor() => const Color(0xFF2A3B41);

  /// A játék indításakor betölti a hátteret, inicializálja az életerő-csíkokat,
  /// létrehozza a hőst és az ellenséget, majd beállítja a pixel art megjelenítést.
  @override
  Future<void> onLoad() async {
    bgComponent = SpriteComponent(
        sprite: await loadSprite('backgrounds/background2.jpg'));
    add(bgComponent);

    playerBar = HealthBarComponent(
      position: Vector2.zero(),
      size: Vector2.zero(),
      max: playerMaxHealth,
      barColor: Colors.greenAccent,
    );
    enemyBar = HealthBarComponent(
      position: Vector2.zero(),
      size: Vector2.zero(),
      max: enemyMaxHealth,
      barColor: Colors.redAccent,
    );
    add(playerBar);
    add(enemyBar);

    character =
        EntityComponent(config: HeroRegistry.getHero(playerClass).entityConfig);

    character.paint.filterQuality = FilterQuality.none;
    character.paint.isAntiAlias = false;

    enemy = EntityComponent(config: initialEnemyConfig, isEnemy: true);
    enemy.paint.filterQuality = FilterQuality.none;
    enemy.paint.isAntiAlias = false;

    add(character);
    add(enemy);

    _applyLayout(size);
  }

  /// Kezeli a képernyő átméretezését, biztosítva az elemek helyes pozícióját.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _applyLayout(size);
  }

  /// Kiszámítja és beállítja a UI elemeket.
  void _applyLayout(Vector2 canvas) {
    final bgSpriteSize = bgComponent.sprite!.originalSize;

    final scaleX = canvas.x / bgSpriteSize.x;
    final scaleY = canvas.y / bgSpriteSize.y;

    double zoomFactor = 1.3;
    final scale = max(scaleX, scaleY) * zoomFactor;

    bgComponent.size = bgSpriteSize * scale;

    double posX = (canvas.x - bgComponent.size.x) / 2;

    double posY = (canvas.y - bgComponent.size.y) *
        0.9; // Próbáld 0.3 és 0.5 között állítani

    bgComponent.position = Vector2(posX, posY);

    // Az életerő-csíkok maradnak a helyükön
    final barW = canvas.x * 0.40;
    final barH = canvas.y * 0.12;
    final barY = canvas.y * 0.84;
    playerBar
      ..size = Vector2(barW, barH)
      ..position = Vector2(canvas.x * 0.05, barY);
    enemyBar
      ..size = Vector2(barW, barH)
      ..position = Vector2(canvas.x * 0.55, barY);
  }

  /// Lecseréli az aktuális ellenséget egy újra, frissítve annak életerő-adatait és konfigurációját.
  void spawnNewEnemyConfig(EntityConfig newConfig, int newMaxHealth) {
    enemyBar.initHealth(newMaxHealth);
    enemy.removeFromParent();

    enemy = EntityComponent(config: newConfig, isEnemy: true);
    enemy.paint.filterQuality = FilterQuality.none;
    enemy.paint.isAntiAlias = false;

    add(enemy);
  }

  /// Frissíti a játékos életerő-csíkjának aktuális értékét.
  void updatePlayerHealth(int current) => playerBar.setHealth(current);

  /// Frissíti az ellenség életerő-csíkjának aktuális értékét.
  void updateEnemyHealth(int current) => enemyBar.setHealth(current);

  // Animációvezérlő metódusok az entitások különböző állapotaihoz
  void triggerCharacterAttack() => character.playState(EntityState.attack);
  void triggerEnemyAttack() => enemy.playState(EntityState.attack);
  void triggerCharacterHit() => character.playState(EntityState.hit);
  void triggerEnemyHit() => enemy.playState(EntityState.hit);
  void triggerCharacterDeath() => character.playState(EntityState.death);
  void triggerEnemyDeath() => enemy.playState(EntityState.death);

  /// Létrehoz egy lövedéket (Projectile), amely az ellenségtől a hős felé tart.
  void spawnProjectile(ProjectileConfig config,
      {required Vector2 startOffset}) {
    final start = Vector2(
      enemy.position.x + startOffset.x,
      enemy.position.y + startOffset.y,
    );
    final target = Vector2(character.position.x, character.position.y - 20);
    add(ProjectileComponent(
      config: config,
      position: start,
      target: target,
      onHit: () => triggerCharacterHit(),
    ));
  }

  /// Megjeleníti a lebegő sebzés-szöveget (vagy 'MISS' feliratot) a megfelelő entitás felett.
  /// Kezeli a színeket a kritikus találatokhoz és véletlenszerű eltolást használ az átláthatóságért.
  void showDamage(
    int amount, {
    required bool isPlayer,
    bool isCrit = false,
    bool dodged = false,
    Color baseColor = Colors.white,
  }) {
    final text = dodged ? 'MISS' : amount.toString();
    Color color = baseColor;
    if (baseColor == Colors.white) {
      color = isPlayer
          ? Colors.redAccent
          : (isCrit ? const Color(0xFFFFD700) : Colors.white);
    }

    final rng = Random();
    final offsetX = (rng.nextDouble() - 0.5) * 60;
    final offsetY = (rng.nextDouble() - 0.5) * 40;

    final pos = isPlayer
        ? Vector2(
            character.position.x + offsetX, character.position.y - 50 + offsetY)
        : Vector2(enemy.position.x + offsetX, enemy.position.y - 50 + offsetY);

    add(DamageTextComponent(
        text: text, position: pos, baseColor: color, isCrit: isCrit));
  }
}
