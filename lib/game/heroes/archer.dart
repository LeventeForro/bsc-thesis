// Az Archer hős karakter implementációja.
// Ez a fájl definiálja a karakter statisztikáit, képességeit (Skill),
// vizuális konfigurációját (Sprite-ok és animációk), valamint a speciális
// harci mozgások (Action Queue) logikáját.

import 'hero_base.dart';
import '../../models/skill_model.dart';
import '../battle_game.dart';
import 'package:flame/game.dart';
import '../entity_component.dart';
import '../action_queue.dart';

class Archer extends HeroBase {
  @override
  String get id => 'archer';
  @override
  String get name => 'ARCHER';
  @override
  String get description => 'Unmatched agility and range.';

  /// Az Íjász alap statisztikái, ahol az agilitás (agility) a meghatározó érték.
  @override
  Map<String, int> get baseStats => {
        'vitality': 8,
        'strength': 5,
        'intellect': 4,
        'agility': 15,
        'luck': 8,
      };

  /// A karakter elérhető képességeinek definíciója és sebzésképletei.
  @override
  Map<int, Skill> get skills => {
        1: Skill(
          name: "Gyors Lövés",
          animation: EntityState.attack,
          formula: (s) => 10.0 + (s['agi']! * 0.6),
          delayMs: 400,
          description:
              "Az íjász kilő egy gyors nyilat, ami sebzi az ellenfelet.",
        ),
        2: Skill(
          name: "Hátráló Kitérés",
          animation: EntityState.roll,
          formula: (s) => 0.0,
          delayMs: 0,
          description: "Megnöveli a kitérést.",
        ),
        3: Skill(
          name: "Záporozó Nyilak",
          animation: EntityState.jump,
          formula: (s) => 4.0 + (s['agi']! * 0.3),
          comboRefund: 1,
          delayMs: 800,
          description: "Az íjász 3 nyilat lő ki, egyre nagyobb sebzéssel.",
        ),
        4: Skill(
          name: "Páncéltörő Támadás",
          animation: EntityState.melee,
          formula: (s) => 20.0 + (s['agi']! * 3.0) + (s['str']! * 1.5),
          delayMs: 800,
          description: "Páncéltörő csapás és villámgyors pörgetés.",
        ),
      };

  /// Meghívja a megfelelő vizuális effektust a képesség költsége alapján.
  @override
  void triggerSkillVisuals(int cost, BattleGame game) {
    switch (cost) {
      case 1:
        game.triggerGyorsLoves();
        break;
      case 2:
        game.triggerArcherDodgeBuff();
        break;
      case 3:
        game.triggerZaporozoNyilak();
        break;
      case 4:
        game.triggerPanceltoroTamadas();
        break;
      default:
        game.character.playState(EntityState.attack);
    }
  }

  /// Az Íjász karakter sprite-lapjainak elérési útja és animációs paraméterei.
  @override
  EntityConfig get entityConfig => EntityConfig(
        name: 'Archer',
        idlePath: 'animations/archer/idle.png',
        idleFrames: 8,
        idleStep: 0.10,
        idleSize: Vector2(128, 128),
        walkPath: 'animations/archer/walk.png',
        walkFrames: 8,
        walkStep: 0.10,
        walkSize: Vector2(128, 128),
        attackPath: 'animations/archer/attack.png',
        attackFrames: 14,
        attackStep: 0.08,
        attackSize: Vector2(180, 128),
        hitPath: 'animations/archer/dash.png',
        hitFrames: 14,
        hitStep: 0.10,
        hitSize: Vector2(128, 128),
        deathPath: 'animations/archer/death.png',
        deathFrames: 24,
        deathStep: 0.10,
        deathSize: Vector2(128, 128),
        rollPath: 'animations/archer/dash.png',
        rollFrames: 14,
        rollStep: 0.10,
        rollSize: Vector2(128, 128),
        jumpPath: 'animations/archer/jump.png',
        jumpFrames: 12,
        jumpStep: 0.08,
        jumpSize: Vector2(128, 128),
        meleePath: 'animations/archer/melee.png',
        meleeFrames: 28,
        meleeStep: 0.08,
        meleeSize: Vector2(128, 128),
        attackOffSetX: 0.0,
        sizeModifier: 1.70,
        xPos: 0.26,
        yPos: 1.50,
      );
}

/// Az Íjász egyedi képességeit megvalósító Mixin, amely az Action Queue-t használja.
mixin ArcherAbilities on FlameGame {
  BattleGame get _g => this as BattleGame;

  /// Egyszerű lövés animáció és alapállapotba való visszaállás.
  void triggerGyorsLoves() {
    final ch = _g.character;
    ch.actionQueue.clear();
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
    }));
  }

  /// Kitérési (gurulás) animáció indítása a képkockák száma alapján számolt ideig.
  void triggerArcherDodgeBuff() {
    final ch = _g.character;
    final cfg = ch.config;
    final duration = (cfg.rollFrames ?? 15) * (cfg.rollStep ?? 0.1);

    ch.actionQueue.clear();
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.roll);
    }));
    ch.actionQueue.add(DelayAction(duration));
    ch.actionQueue.add(CallbackAction(() {
      ch.playState(EntityState.idle);
    }));
  }

  /// Három darab, felgyorsított támadó animáció egymás utáni lejátszása.
  void triggerZaporozoNyilak() {
    final ch = _g.character;
    final double originalStep = ch.config.attackStep;

    ch.actionQueue.clear();

    // Animáció felgyorsítása a belső frame-ek időközének harmadolásával
    ch.actionQueue.add(CallbackAction(() {
      final animation = ch.animations?[EntityState.attack];
      if (animation != null) {
        for (final frame in animation.frames) {
          frame.stepTime = originalStep / 3.0;
        }
      }
    }));

    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));
    ch.actionQueue.add(PlayAnimationAction(EntityState.attack));

    // Sebesség visszaállítása
    ch.actionQueue.add(CallbackAction(() {
      final animation = ch.animations?[EntityState.attack];
      if (animation != null) {
        for (final frame in animation.frames) {
          frame.stepTime = originalStep;
        }
      }
      ch.playState(EntityState.idle);
    }));
  }

  /// Komplex közelharci támadás: odaszalad az ellenfélhez, támad, majd visszavonul.
  void triggerPanceltoroTamadas() {
    final ch = _g.character;
    final homePos = ch.position.clone();
    final attackPos = Vector2(_g.enemy.position.x - 60.0, ch.position.y);

    final double distanceIn = (attackPos - homePos).length;
    final double speedIn = distanceIn > 0 ? distanceIn / 0.5 : 400.0;

    final double distanceOut = (homePos - attackPos).length;
    final double speedOut = distanceOut > 0 ? distanceOut / 0.5 : 400.0;

    ch.actionQueue.clear();

    // 1. Odafutás a célhoz
    ch.actionQueue.add(
        MoveAction(attackPos, speed: speedIn, moveState: EntityState.walk));

    // 2. Melee (közelharci) animáció lejátszása
    ch.actionQueue.add(PlayAnimationAction(EntityState.melee));

    // 3. Karakter megfordítása a visszatéréshez
    ch.actionQueue.add(CallbackAction(() {
      ch.flipHorizontallyAroundCenter();
    }));

    // 4. Visszafutás az eredeti helyre
    ch.actionQueue
        .add(MoveAction(homePos, speed: speedOut, moveState: EntityState.walk));

    // 5. Irány visszaállítása és alapállapot
    ch.actionQueue.add(CallbackAction(() {
      ch.flipHorizontallyAroundCenter();
      ch.playState(EntityState.idle);
    }));
  }
}
