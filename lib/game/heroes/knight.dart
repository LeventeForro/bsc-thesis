// A Lovag hős karakter implementációja, amely a magas életerőre (Vitality) és fizikai erőre (Strength) fókuszál.
// Ez a fájl kezeli a nehézpáncélos harcmodort, a védekező mechanizmusokat és a komplex, ugrással kombinált támadási szekvenciákat.

import 'hero_base.dart';
import '../../models/skill_model.dart';
import '../battle_game.dart';
import 'package:flame/game.dart';
import '../entity_component.dart';
import '../action_queue.dart';

/// A Lovag karakterosztálya. Fő jellemzője a nagy szívósság és a nehéz fizikai csapások.
class Knight extends HeroBase {
  @override
  String get id => 'knight';
  @override
  String get name => 'KNIGHT';
  @override
  String get description => 'High vitality and physical power.';

  /// Alapstatisztikák: kiemelkedő életerő és fizikai erő.
  @override
  Map<String, int> get baseStats => {
        'vitality': 15,
        'strength': 12,
        'intellect': 3,
        'agility': 5,
        'luck': 5,
      };

  /// A Lovag egyedi képességkészlete és azok matematikai sebzésképletei.
  @override
  Map<int, Skill> get skills => {
        1: Skill(
          name: "Pajzsütés",
          animation: EntityState.attack,
          formula: (s) => 10.0 + (s['str']! * 0.5),
          delayMs: 400,
          description: "Alap támadás. Kis mértékű sebzést okoz",
        ),
        2: Skill(
          name: "Vasakarat",
          animation: EntityState.defend,
          formula: (s) => 0.0,
          delayMs: 0,
          description: "Védelmet ad a következő körre.",
        ),
        3: Skill(
          name: "Steel Charge",
          animation: EntityState.roll,
          formula: (s) => 8.0 + (s['str']! * 0.5) + (s['agi']! * 0.8),
          comboRefund: 1,
          delayMs: 1300,
          description:
              "A lovag 3 csapást mér: egyre nagyobbat üt, növekvő kritikus eséllyel.",
        ),
        4: Skill(
          name: "Égi Ítélet",
          animation: EntityState.jump,
          formula: (s) => (s['str']! * 2.5) + (s['luck']! * 1.2),
          delayMs: 2900,
          description: "A lovag az ellenfél mögé ugrik és hátba támadja azt.",
        ),
      };

  /// A képességponthoz tartozó vizuális effektus és akciósorrend elindítása.
  @override
  void triggerSkillVisuals(int cost, BattleGame game) {
    switch (cost) {
      case 1:
        game.triggerBasicAttack();
        break;
      case 2:
        game.triggerDefensiveStance();
        break;
      case 3:
        game.triggerSteelCharge();
        break;
      case 4:
        game.triggerHeavenlyJudgment();
        break;
      default:
        game.character.playState(EntityState.attack);
    }
  }

  /// A Lovag sprite-jainak, animációs sebességének és harctéri pozíciójának konfigurációja.
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Knight',
        idlePath: 'animations/knight/idle.png',
        idleFrames: 15,
        idleStep: 0.07,
        idleSize: Vector2(64, 64),
        walkPath: 'animations/knight/walk.png',
        walkFrames: 8,
        walkStep: 0.08,
        walkSize: Vector2(96, 64),
        attackPath: 'animations/knight/attack.png',
        attackFrames: 22,
        attackStep: 0.10,
        attackSize: Vector2(144, 64),
        hitPath: 'animations/knight/shield.png',
        hitFrames: 7,
        hitStep: 0.10,
        hitSize: Vector2(96, 64),
        deathPath: 'animations/knight/death.png',
        deathFrames: 15,
        deathStep: 0.05,
        deathSize: Vector2(96, 64),
        defendPath: 'animations/knight/shield.png',
        defendFrames: 7,
        defendStep: 0.10,
        defendSize: Vector2(96, 64),
        jumpPath: 'animations/knight/jump.png',
        jumpFrames: 14,
        jumpStep: 0.08,
        jumpSize: Vector2(144, 64),
        rollPath: 'animations/knight/roll.png',
        rollFrames: 15,
        rollStep: 0.06,
        rollSize: Vector2(180, 64),
        attackOffSetX: 40.0,
        sizeModifier: 0.96,
        xPos: 0.26,
        yPos: 1.10,
      );
}

/// A Lovag egyedi képességeinek animációs logikája az Action Queue rendszer használatával.
mixin KnightAbilities on FlameGame {
  BattleGame get _g => this as BattleGame;

  /// Alapértelmezett támadás: a teljes animáció helyett csak a 9. képkockáig játssza le a sorozatot.
  void triggerBasicAttack() {
    final ch = _g.character;
    ch.actionQueue.clear();

    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.attack);
      final ticker = ch.animationTickers?[EntityState.attack];
      if (ticker != null) {
        ticker.onFrame = (frameIndex) {
          if (frameIndex >= 9) {
            ticker.onFrame = null;
            ch.playState(EntityState.idle);
          }
        };
      }
    }));

    ch.actionQueue.add(DelayAction(0.9));
  }

  /// Védekező tartás: lejátssza a pajzs animációt, majd egy rövid várakozás után visszaáll alaphelyzetbe.
  void triggerDefensiveStance() {
    final ch = _g.character;
    ch.actionQueue.clear();

    ch.actionQueue.add(PlayAnimationAction(EntityState.defend));
    ch.actionQueue.add(DelayAction(1.0));
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
    }));
  }

  /// Roham képesség indítása a támadó animáció segítségével.
  void triggerSteelCharge() {
    final ch = _g.character;
    ch.actionQueue.clear();
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
    }));
  }

  /// Égi Ítélet: Komplex mozgási szekvencia, ahol a lovag átugrik az ellenfél mögé, lecsap, majd visszavonul.
  void triggerHeavenlyJudgment() {
    final ch = _g.character;
    final en = _g.enemy;

    final Vector2 homePos = ch.position.clone();
    final bool originalFacingRight = ch.scale.x > 0;
    final bool isCharOnLeft = ch.position.x < en.position.x;

    final double charVisualWidth =
        (ch.config.idleSize.x) * (ch.config.sizeModifier);
    final double enemyVisualWidth =
        (en.config.idleSize.x) * (en.config.sizeModifier);

    double targetX;
    bool willBeOnLeft;

    if (isCharOnLeft) {
      targetX = en.position.x + enemyVisualWidth + 5.0;
      willBeOnLeft = false;
    } else {
      targetX = en.position.x - charVisualWidth - 5.0;
      willBeOnLeft = true;
    }

    targetX = targetX.clamp(0.0, _g.size.x - charVisualWidth);
    willBeOnLeft = targetX < en.position.x;
    final attackPos = Vector2(targetX, ch.position.y);

    final cfg = ch.config;
    final jumpDuration = (cfg.jumpFrames ?? 14) * (cfg.jumpStep ?? 0.08);
    final double distanceOut = (attackPos - homePos).length;
    final double speedOut =
        distanceOut > 0 ? distanceOut / jumpDuration : 400.0;

    final double distanceBack = (homePos - attackPos).length;
    final double speedBack = distanceBack > 0 ? distanceBack / 0.6 : 400.0;

    ch.actionQueue.clear();

    // 1. Átugrás az ellenfél mögötti pozícióba
    ch.actionQueue.add(
        MoveAction(attackPos, speed: speedOut, moveState: EntityState.jump));

    // 2. Szükség esetén megfordulás a célponton
    ch.actionQueue.add(CallbackAction(() {
      final bool shouldFaceRight = willBeOnLeft;
      if ((ch.scale.x > 0) != shouldFaceRight) {
        ch.flipHorizontallyAroundCenter();
      }
    }));

    // 3. Támadó csapás végrehajtása
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));

    // 4. Gyors visszavonulás az eredeti kezdőhelyre
    ch.actionQueue.add(
        MoveAction(homePos, speed: speedBack, moveState: EntityState.walk));

    // 5. Karakter visszaforgatása és alapállapotba helyezés
    ch.actionQueue.add(CallbackAction(() {
      if ((ch.scale.x > 0) != originalFacingRight) {
        ch.flipHorizontallyAroundCenter();
      }
      ch.playState(EntityState.idle);
      ch.isMovingToAttack = false;
    }));
  }
}
