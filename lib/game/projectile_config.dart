// A távolsági támadások megvalósítása.
// Ez a rendszer kezeli a lövedékek sprite-animációit és a fizikai mozgásukat,
// beleértve a sinusz alapú parabolikus ívszámítást a realisztikusabb röppálya érdekében.

import 'dart:math'; // sin(), pi - a röppálya számításához
import 'package:flame/components.dart';
import '../game/battle_game.dart';
import 'package:flutter/widgets.dart';

/// [ProjectileConfig] - Statikus adatok a lövedék viselkedéséhez.
/// Itt definiálható, hogy egy bomba lassabban és magasabb ívben,
/// míg egy tűzgolyó gyorsan és egyenesebben repüljön.
class ProjectileConfig {
  final String spritePath; // A képfájl elérési útja
  final int frames; // Animációs képkockák száma
  final double stepTime; // Animáció sebessége
  final Vector2 textureSize; // Forráskép mérete
  final Vector2 displaySize; // Megjelenített méret a játékban
  final double speed; // Haladási sebesség
  final double arcHeight; // A röppálya maximum magassága (íveltség)
  final int priority; // Megjelenési sorrend (réteg)

  const ProjectileConfig({
    required this.spritePath,
    required this.frames,
    required this.stepTime,
    required this.textureSize,
    required this.displaySize,
    this.speed = 350.0,
    this.arcHeight = 60.0,
    this.priority = 150,
  });
}

/// [ProjectileConfigs] - Az ellenségtípusok egyedi lövedék-beállításai.
class ProjectileConfigs {
  // Goblin bombája: Nehézkes, alacsony ívű dobás
  static final goblinBomb = ProjectileConfig(
    spritePath: 'animations/Goblin/Bomb_sprite.png',
    frames: 19,
    stepTime: 0.08,
    textureSize: Vector2(100, 100),
    displaySize: Vector2(250, 250),
    arcHeight: 25.0,
  );

  // Csontváz elhajított kardja/csontja: Magasabb, pattogósabb ív
  static final skeletonBone = ProjectileConfig(
    spritePath: 'animations/Skeleton/Sword_sprite.png',
    frames: 8,
    stepTime: 0.07,
    textureSize: Vector2(92, 102),
    displaySize: Vector2(100, 100),
    arcHeight: 40.0,
    speed: 400.0,
  );

  // Repülő szem lövedéke: Villámgyors, minimális ívvel
  static final flyingEyeFireball = ProjectileConfig(
    spritePath: 'animations/flyingEye/projectile_sprite.png',
    frames: 8,
    stepTime: 0.06,
    textureSize: Vector2(48, 48),
    displaySize: Vector2(120, 120),
    arcHeight: 20.0,
    speed: 450.0,
  );

  // Gomba spórája: Lassú, gravitációszerűen hulló lövedék
  static final mushroomSpore = ProjectileConfig(
    spritePath: 'animations/Mushroom/Projectile_sprite.png',
    frames: 8,
    stepTime: 0.09,
    textureSize: Vector2(50, 50),
    displaySize: Vector2(130, 130),
    arcHeight: 90.0,
    speed: 300.0,
  );
}

/// [ProjectileComponent] - A tényleges Flame komponens, amely a mozgást végzi.
class ProjectileComponent extends SpriteAnimationComponent
    with HasGameRef<BattleGame> {
  final ProjectileConfig config;
  final Vector2 target; // A célpont (általában a játékos pozíciója)
  final VoidCallback onHit; // Callback, ami a becsapódáskor hívódik meg

  bool _hasHit = false; // Zászló a többszöri becsapódás elkerülésére
  late double _startY; // Indulási magasság tárolása az ívhez
  late double _totalDistance; // Teljes távolság a progresszió számításához

  ProjectileComponent({
    required this.config,
    required Vector2 position,
    required this.target,
    required this.onHit,
  }) : super(
          position: position,
          size: config.displaySize,
          anchor: Anchor.center,
          priority: config.priority,
        );

  @override
  Future<void> onLoad() async {
    _startY = position.y;
    _totalDistance = (target - position).length;

    // Animáció betöltése
    animation = await gameRef.loadSpriteAnimation(
      config.spritePath,
      SpriteAnimationData.sequenced(
        amount: config.frames,
        stepTime: config.stepTime,
        textureSize: config.textureSize,
        loop: false, // Csak egyszer fut le a becsapódásig
      ),
    );

    // Ha az animáció véget ér a cél elérése előtt (pl. szétrobban a levegőben)
    animationTicker?.onComplete = () {
      if (!_hasHit) {
        _hasHit = true;
        removeFromParent();
        onHit();
      }
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hasHit) return;

    final direction = target - position;
    final distance = direction.length;

    // Mozgatás a célpont felé
    if (distance > config.speed * dt) {
      position.add(direction.normalized() * config.speed * dt);

      // PARABOLIKUS ÍV SZÁMÍTÁSA
      // A progresszió 0.0 (indulás) és 1.0 (becsapódás) között mozog.
      // A sin(progress * pi) egy 0-tól 1-ig tartó görbét ad, ami középen éri el a csúcsot.
      if (config.arcHeight > 0) {
        final progress = 1.0 - (distance / _totalDistance);
        position.y = _startY +
            (target.y - _startY) * progress -
            config.arcHeight * sin(progress * pi);
      }
    } else {
      // BECSAPÓDÁS
      if (!_hasHit) {
        _hasHit = true;
        position = target;
        removeFromParent(); // Törlés a játéktérről
        onHit(); // Hatás (sebzés animáció) kiváltása
      }
    }
  }
}
