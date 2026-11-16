// Az entitások (hősök és ellenségek) vizuális megjelenítéséért és mozgásáért felelős alaprendszer.
// Tartalmazza a konfigurációs adatokat (EntityConfig) és a Flame komponenst (EntityComponent),
// amely az Action Queue segítségével kezeli a komplex harci szekvenciákat és a pixel-art megjelenítést.

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';

// Az entitás mozgásait és animációs sorozatait vezérlő akciókezelő
import 'action_queue.dart';

/// [EntityConfig] - Statikus adatmodell, amely az összes vizuális paramétert tartalmazza
/// egy adott karakterhez (pl. fájl elérési utak, képkockák száma, eltolások).
class EntityConfig {
  final String name;

  // Alapvető animációs útvonalak és adatok
  final String idlePath;
  final int idleFrames;
  final double idleStep;
  final Vector2 idleSize;

  final String walkPath;
  final int walkFrames;
  final double walkStep;
  final Vector2 walkSize;

  final String attackPath;
  final int attackFrames;
  final double attackStep;
  final Vector2 attackSize;

  final String hitPath;
  final int hitFrames;
  final double hitStep;
  final Vector2 hitSize;

  final String deathPath;
  final int deathFrames;
  final double deathStep;
  final Vector2 deathSize;

  // Opcionális képességek és állapotok (null-olhatóak, ha az adott karakter nem rendelkezik velük)
  final String? defendPath;
  final int? defendFrames;
  final double? defendStep;
  final Vector2? defendSize;

  final String? jumpPath;
  final int? jumpFrames;
  final double? jumpStep;
  final Vector2? jumpSize;

  final String? rollPath;
  final int? rollFrames;
  final double? rollStep;
  final Vector2? rollSize;

  final String? meleePath;
  final int? meleeFrames;
  final double? meleeStep;
  final Vector2? meleeSize;

  final String? spawnPath;
  final int? spawnFrames;
  final double? spawnStep;
  final Vector2? spawnSize;

  // Megjelenítési finomhangolók (pixel-art karakterek eltérő méreteihez)
  final double sizeModifier; // Globális méretszorzó
  final double xPos; // Alapértelmezett vízszintes pozíció (százalékban)
  final double yPos; // Alapértelmezett függőleges pozíció (százalékban)
  final double attackOffSetY; // Y eltolás támadás közben
  final double attackOffSetX; // X eltolás támadás közben
  final double attackScaleModifier;
  final double hitScaleModifier;
  final double deathScaleModifier;
  final double spawnOffSetY; // Y eltolás idézés (spawn) közben

  const EntityConfig({
    required this.name,
    required this.idlePath,
    required this.idleFrames,
    required this.idleStep,
    required this.idleSize,
    required this.walkPath,
    required this.walkFrames,
    required this.walkStep,
    required this.walkSize,
    required this.attackPath,
    required this.attackFrames,
    required this.attackStep,
    required this.attackSize,
    required this.hitPath,
    required this.hitFrames,
    required this.hitStep,
    required this.hitSize,
    required this.deathPath,
    required this.deathFrames,
    required this.deathStep,
    required this.deathSize,
    this.defendPath,
    this.defendFrames,
    this.defendStep,
    this.defendSize,
    this.jumpPath,
    this.jumpFrames,
    this.jumpStep,
    this.jumpSize,
    this.rollPath,
    this.rollFrames,
    this.rollStep,
    this.rollSize,
    this.meleePath,
    this.meleeFrames,
    this.meleeStep,
    this.meleeSize,
    this.spawnPath,
    this.spawnFrames,
    this.spawnStep,
    this.spawnSize,
    required this.sizeModifier,
    required this.xPos,
    required this.yPos,
    this.attackOffSetY = 0.0,
    this.attackOffSetX = 0.0,
    this.attackScaleModifier = 1.0,
    this.hitScaleModifier = 1.0,
    this.deathScaleModifier = 1.0,
    this.spawnOffSetY = 0.0,
  });
}

/// [EntityState] - A karakter lehetséges állapotainak (animációinak) listája.
enum EntityState {
  idle,
  walk,
  attack,
  hit,
  death,
  defend,
  jump,
  roll,
  melee,
  spawn,
}

/// [EntityComponent] - A hősök és ellenségek vizuális megjelenítéséért felelős osztály.
/// Egy [SpriteAnimationGroupComponent]-et használ, hogy könnyen válthassunk az állapotok között.
class EntityComponent extends SpriteAnimationGroupComponent<EntityState>
    with HasGameRef<FlameGame> {
  final EntityConfig config; // A karakter vizuális beállításai
  final bool
      isEnemy; // Megkülönbözteti, hogy hős vagy ellenség (tükrözés miatt)

  bool isManualMode =
      false; // Ha true, a komponens nem számolja újra automatikusan a pozíciót

  Vector2 targetPos = Vector2.zero(); // A célpozíció a képernyőn
  Vector2 currentOffset = Vector2.zero(); // Dinamikus eltolás
  bool isEntering = true; // Jelzi, ha a karakter épp besétál a képernyőre
  final double walkSpeed = 350.0; // Besétálás sebessége

  bool isMovingToAttack =
      false; // Jelzi, ha a karakter épp egy MoveAction-t hajt végre

  /// A cselekvéssorozatokat (mozgás, animáció, várakozás) kezelő várólista.
  final ActionQueue actionQueue = ActionQueue();

  EntityComponent({
    required this.config,
    this.isEnemy = false,
  }) : super(anchor: isEnemy ? Anchor.center : Anchor.bottomCenter);

  /// A renderelés felülbírálása a pixel-art élesség biztosítása érdekében.
  @override
  void render(Canvas canvas) {
    // Kikapcsoljuk az élsimítást és a filterezést, hogy ne legyen "blurös" a kép skálázáskor.
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    final ticker = animationTickers?[current];
    if (ticker != null) {
      ticker.getSprite().render(
            canvas,
            size: size,
            overridePaint: paint,
          );
    } else {
      super.render(canvas);
    }
  }

  /// Inicializálás: animációk betöltése és állapotok beállítása.
  @override
  Future<void> onLoad() async {
    // Alapértelmezett (kötelező) animációk betöltése
    final anims = <EntityState, SpriteAnimation>{
      EntityState.idle: await _anim(
          config.idlePath, config.idleFrames, config.idleStep, config.idleSize),
      EntityState.walk: await _anim(
          config.walkPath, config.walkFrames, config.walkStep, config.walkSize),
      EntityState.attack: await _anim(config.attackPath, config.attackFrames,
          config.attackStep, config.attackSize,
          loop: false),
      EntityState.hit: await _anim(
          config.hitPath, config.hitFrames, config.hitStep, config.hitSize,
          loop: false),
      EntityState.death: await _anim(config.deathPath, config.deathFrames,
          config.deathStep, config.deathSize,
          loop: false),
    };

    // Opcionális animációk segédfüggvénye: csak akkor adja hozzá, ha van path definiálva.
    Future<void> addOptional(EntityState state, String? path, int? frames,
        double? step, Vector2? size,
        {bool loop = false}) async {
      if (path != null) {
        anims[state] = await _anim(path, frames!, step!, size!, loop: loop);
      }
    }

    await addOptional(EntityState.defend, config.defendPath,
        config.defendFrames, config.defendStep, config.defendSize);
    await addOptional(EntityState.jump, config.jumpPath, config.jumpFrames,
        config.jumpStep, config.jumpSize,
        loop: true);
    await addOptional(EntityState.roll, config.rollPath, config.rollFrames,
        config.rollStep, config.rollSize,
        loop: true);
    await addOptional(EntityState.melee, config.meleePath, config.meleeFrames,
        config.meleeStep, config.meleeSize);
    await addOptional(EntityState.spawn, config.spawnPath, config.spawnFrames,
        config.spawnStep, config.spawnSize);

    animations = anims;

    // Ha ellenség, vízszintesen megfordítjuk (hogy balra nézzen).
    if (isEnemy) flipHorizontally();

    current = EntityState.walk; // Kezdőállapot: sétálva jön be.
  }

  /// Segédfüggvény [SpriteAnimation] objektumok aszinkron betöltéséhez.
  Future<SpriteAnimation> _anim(
      String path, int frames, double step, Vector2 size,
      {bool loop = true}) {
    return gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
          amount: frames, stepTime: step, textureSize: size, loop: loop),
    );
  }

  /// Képernyő átméretezésekor újraszámoljuk az entitás helyét.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isManualMode) {
      // Százalékos pozicionálás az EntityConfig alapján
      targetPos = Vector2(size.x * config.xPos, size.y * config.yPos);

      // Kezdőpozíció beállítása a képernyőn kívülre az első belépéskor
      if (isEntering) {
        final baseH = size.y * config.sizeModifier;
        position.x = isEnemy ? size.x + (baseH * 0.6) : -(baseH * 0.6);
        position.y = targetPos.y;
      }
    }
    _updateTransform();
  }

  /// Játéklogika frissítése minden frame-ben.
  @override
  void update(double dt) {
    super.update(dt);

    // Besétálási animáció/mozgás kezelése
    if (isEntering) {
      final dir = isEnemy ? -1 : 1;
      if ((isEnemy && position.x > targetPos.x) ||
          (!isEnemy && position.x < targetPos.x)) {
        position.x += dir * walkSpeed * dt;
      } else {
        position = targetPos;
        isEntering = false;
        playState(EntityState.idle);
      }
      return;
    }

    // Az ActionQueue frissítése: ha van sorba állított akció, azt itt hajtja végre.
    actionQueue.update(this, dt);
  }

  /// [playState] - Állapotváltó metódus, amely kezeli az animációk resetelését és a visszacsatolásokat.
  void playState(EntityState newState,
      {int startFrame = 0, VoidCallback? onComplete}) {
    if (!animations!.containsKey(newState)) newState = EntityState.idle;
    final ticker = animationTickers?[newState];
    ticker?.reset();

    if (ticker != null) {
      if (onComplete != null) {
        // Egyedi befejező logika (pl. az ActionQueue használja az animáció végének detektálására)
        ticker.onComplete = onComplete;
      } else {
        // Alapértelmezett visszatérés Idle-be, ha nem loopolt animációról van szó (pl. sebződés)
        if (newState != EntityState.death &&
            newState != EntityState.idle &&
            newState != EntityState.walk) {
          ticker.onComplete = () {
            if (!isMovingToAttack && actionQueue.isEmpty) {
              playState(EntityState.idle);
            }
          };
        } else {
          ticker.onComplete = null;
        }
      }
    }

    if (startFrame > 0 && ticker != null) ticker.currentIndex = startFrame;
    current = newState;
    _updateTransform();
  }

  /// [_updateTransform] - Kiszámítja a karakter aktuális méretét és pozícióját.
  /// Fontos: egész számokra kerekítünk, hogy elkerüljük a pixelek "remegését" és elmosódását.
  void _updateTransform() {
    if (gameRef.size.isZero()) return;

    // Alapmagasság kiszámítása a képernyőmagasság és a módosító alapján
    final baseHeight = gameRef.size.y * config.sizeModifier;

    Vector2 textureSize;
    double scaleModifier = 1.0;
    // ignore: unused_local_variable
    Vector2 offset = Vector2.zero();

    // Aktuális állapothoz tartozó adatok kiválasztása
    switch (current) {
      case EntityState.attack:
        textureSize = config.attackSize;
        scaleModifier = config.attackScaleModifier;
        offset = Vector2(config.attackOffSetX, config.attackOffSetY);
        break;
      case EntityState.hit:
        textureSize = config.hitSize;
        scaleModifier = config.hitScaleModifier;
        break;
      case EntityState.death:
        textureSize = config.deathSize;
        scaleModifier = config.deathScaleModifier;
        break;
      case EntityState.walk:
        textureSize = config.walkSize;
        break;
      case EntityState.defend:
        textureSize = config.defendSize ?? config.idleSize;
        break;
      case EntityState.jump:
        textureSize = config.jumpSize ?? config.walkSize;
        break;
      case EntityState.roll:
        textureSize = config.rollSize ?? config.walkSize;
        break;
      case EntityState.melee:
        textureSize = config.meleeSize ?? config.attackSize;
        break;
      case EntityState.spawn:
        textureSize = config.spawnSize ?? config.idleSize;
        offset = Vector2(0.0, config.spawnOffSetY);
        break;
      case EntityState.idle:
      default:
        textureSize = config.idleSize;
    }

    // Skálázási arány meghatározása
    final scale = (baseHeight / config.idleSize.y) * scaleModifier;

    // Pixel-art kerekítés: a méretnek egész pixelnek kell lennie
    int rawSizeX = (textureSize.x * scale).round();
    int rawSizeY = (textureSize.y * scale).round();

    // Páros számra kerekítés, hogy az Anchor (középpont) ne kerüljön fél-pixelre
    if (rawSizeX.isOdd) rawSizeX += 1;
    if (rawSizeY.isOdd) rawSizeY += 1;

    size = Vector2(rawSizeX.toDouble(), rawSizeY.toDouble());

    // Ha nem mozog a karakter, kerekített fix pozícióba pattintjuk
    if (!isEntering && !isMovingToAttack && actionQueue.isEmpty) {
      position = Vector2(
        (targetPos.x + currentOffset.x).roundToDouble(),
        (targetPos.y + currentOffset.y).roundToDouble(),
      );
    }
  }
}
