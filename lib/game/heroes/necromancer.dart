// A Nekromanta hős osztálya, amely az intelligenciára és a sötét mágiára épít.
// Kezeli a speciális Y-tengelyi eltolásokat az animációk alatt, valamint a rituálékkal kombinált mozgási szekvenciákat.

import 'hero_base.dart';
import '../../models/skill_model.dart';
import '../battle_game.dart';
import 'package:flame/game.dart';
import '../entity_component.dart';
import '../action_queue.dart';

class Necromancer extends HeroBase {
  @override
  String get id => 'necromancer';
  @override
  String get name => 'NECROMANCER';
  @override
  String get description => 'Master of intellect and dark arts.';

  /// Alapstatisztikák: az intelligencia a meghatározó, alacsony fizikai erő mellett.
  @override
  Map<String, int> get baseStats => {
        'vitality': 10,
        'strength': 4,
        'intellect': 13,
        'agility': 6,
        'luck': 7,
      };

  /// A Nekromanta képességkészlete: a rontások és a sötét paktumok logikája.
  @override
  Map<int, Skill> get skills => {
        1: Skill(
            name: "Léleknyíl",
            animation: EntityState.attack,
            formula: (s) => 10.0 + (s['intel']! * 0.8),
            delayMs: 1520,
            description: "Alap témadás. Egy kisméretű varázslabdát"),
        2: Skill(
          name: "Sötét Paktum",
          animation: EntityState.spawn,
          formula: (s) => 0.0,
          delayMs: 0,
          description: "HP-ért cserébe sebzés bónusz.",
        ),
        3: Skill(
          name: "Gyengítő Rontás",
          animation: EntityState.walk,
          formula: (s) => 15.0 + (s['intel']! * 1.2),
          delayMs: 1000,
          description: "Odafut, megsebzi és legyengíti az ellenfelet.",
        ),
        4: Skill(
          name: "Végzetes Átok",
          animation: EntityState.walk,
          formula: (s) => 25.0 + (s['intel']! * 4.0),
          delayMs: 2940,
          description: "Védelmet zúzó átok és garantált kritikus csapás.",
        ),
      };

  /// Vizuális akciók indítása a kiválasztott képesség költsége alapján.
  @override
  void triggerSkillVisuals(int cost, BattleGame game) {
    switch (cost) {
      case 1:
        game.triggerNecroBasicAttack();
        break;
      case 2:
        game.triggerNecroDarkPact();
        break;
      case 3:
        game.triggerNecroSkill3();
        break;
      case 4:
        game.triggerNecroSkill4();
        break;
      default:
        game.triggerNecroBasicAttack();
    }
  }

  /// A karakter vizuális konfigurációja, beleértve a speciális eltolási (offset) értékeket.
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Necromancer',
        idlePath: 'animations/necromancer/idle.png',
        idleFrames: 50,
        idleStep: 0.1,
        idleSize: Vector2(96, 96),
        walkPath: 'animations/necromancer/walk.png',
        walkFrames: 10,
        walkStep: 0.1,
        walkSize: Vector2(96, 96),
        attackPath: 'animations/necromancer/attack.png',
        attackFrames: 47,
        attackStep: 0.04,
        attackSize: Vector2(128, 128),
        hitPath: 'animations/necromancer/hit.png',
        hitFrames: 9,
        hitStep: 0.1,
        hitSize: Vector2(96, 96),
        deathPath: 'animations/necromancer/death.png',
        deathFrames: 52,
        deathStep: 0.1,
        deathSize: Vector2(96, 96),
        jumpPath: 'animations/necromancer/jump.png',
        jumpFrames: 12,
        jumpStep: 0.08,
        jumpSize: Vector2(96, 96),
        spawnPath: 'animations/necromancer/spawn.png',
        spawnFrames: 20,
        spawnStep: 0.05,
        spawnSize: Vector2(128, 96),
        spawnOffSetY: -40.0,
        attackOffSetY: -45.0,
        sizeModifier: 1.22,
        xPos: 0.26,
        yPos: 1.21,
      );
}

/// A Nekromanta egyedi mozgásait és rituáléit vezérlő Mixin.
mixin NecromancerAbilities on FlameGame {
  BattleGame get _g => this as BattleGame;

  /// Alap támadás lejátszása ideiglenes magassági korrekcióval (attackOffSetY).
  void triggerNecroBasicAttack() {
    final ch = _g.character;
    final double originalY = ch.position.y;

    ch.actionQueue.clear();
    ch.actionQueue.add(CallbackAction(() {
      ch.position.y -= ch.config.attackOffSetY;
    }));

    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));

    ch.actionQueue.add(CallbackAction(() {
      ch.position.y = originalY;
      ch.playState(EntityState.idle);
    }));
  }

  /// Sötét paktum: rituális animáció eltolt magassággal, majd egy önhibás találat (hit) jelzése.
  void triggerNecroDarkPact() {
    final ch = _g.character;
    final double originalY = ch.position.y;

    ch.actionQueue.clear();
    ch.actionQueue.add(CallbackAction(() {
      ch.position.y += ch.config.spawnOffSetY;
    }));

    ch.actionQueue.add(PlayAnimationAction(EntityState.spawn));

    ch.actionQueue.add(CallbackAction(() {
      ch.position.y = originalY;
    }));

    ch.actionQueue.add(PlayAnimationAction(EntityState.hit));

    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
    }));
  }

  /// Belső segédfüggvény: lerohanás az ellenfélhez, rituálé elvégzése, majd visszavonulás.
  void _queueWalkAndSpawn() {
    final ch = _g.character;
    final homePos = ch.position.clone();
    final attackPos = Vector2(_g.enemy.position.x - 60.0, ch.position.y);

    ch.actionQueue.clear();
    ch.actionQueue
        .add(MoveAction(attackPos, speed: 600, moveState: EntityState.walk));

    ch.actionQueue.add(CallbackAction(() {
      ch.position.y += ch.config.spawnOffSetY;
    }));

    ch.actionQueue.add(PlayAnimationAction(EntityState.spawn));

    ch.actionQueue.add(CallbackAction(() {
      ch.position.y = homePos.y;
      ch.flipHorizontallyAroundCenter();
    }));

    ch.actionQueue
        .add(MoveAction(homePos, speed: 600, moveState: EntityState.walk));

    ch.actionQueue.add(CallbackAction(() {
      ch.flipHorizontallyAroundCenter();
    }));
  }

  /// 3-as skill: Séta és rituálé végrehajtása, majd alaphelyzetbe állás.
  void triggerNecroSkill3() {
    _queueWalkAndSpawn();
    final ch = _g.character;
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
      ch.isMovingToAttack = false;
    }));
  }

  /// 4-es skill: A rituálét követően egy bónusz támadó animációt is lejátszik extra magassági korrekcióval.
  void triggerNecroSkill4() {
    _queueWalkAndSpawn();
    final ch = _g.character;
    ch.actionQueue.add(CallbackAction(() {
      ch.position.y -= ch.config.attackOffSetY;
    }));
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));
    ch.actionQueue.add(CallbackAction(() {
      ch.position.y += ch.config.attackOffSetY;
      ch.playState(EntityState.idle);
      ch.isMovingToAttack = false;
    }));
  }
}
