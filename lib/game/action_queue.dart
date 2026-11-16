// Az entitások (hősök és ellenségek) mozgásait és cselekedeteit sorba rendező rendszer.
// Lehetővé teszi komplex animációs szekvenciák (pl. odaszalad, üt, visszaugrik)
// egyszerű, egymás utáni végrehajtását anélküli, hogy a kód átláthatatlanná válna.

import 'package:flame/components.dart';
import 'entity_component.dart';

/// Minden entitás-akció közös őse.
abstract class EntityAction {
  bool get isDone; // Jelzi a Queue-nak, hogy az akció befejeződött.
  void start(
      EntityComponent entity); // Az akció indulásakor hívódik meg egyszer.
  void update(EntityComponent entity,
      double dt); // Minden képkockánál frissíti az akciót.
}

/// 1. Akció: Az entitás elmozgatása egy megadott pontra meghatározott sebességgel.
class MoveAction extends EntityAction {
  final Vector2 target;
  final double speed;
  final EntityState moveState;
  bool _isDone = false;

  MoveAction(this.target,
      {this.speed = 400.0, this.moveState = EntityState.walk});

  @override
  bool get isDone => _isDone;

  @override
  void start(EntityComponent entity) {
    entity.playState(moveState); // Átváltás séta/mozgás animációra.
    entity.isMovingToAttack = true;
  }

  @override
  void update(EntityComponent entity, double dt) {
    final dirVec = target - entity.position;
    final dist = dirVec.length;

    // Ha a távolság kisebb, mint amit egy lépéssel megtenne, megérkeztünk.
    if (dist < speed * dt) {
      entity.position = target.clone();
      _isDone = true;
    } else {
      dirVec.normalize();
      entity.position += dirVec * speed * dt;
    }
  }
}

/// 2. Akció: Egy animáció egyszeri lejátszása a végéig.
class PlayAnimationAction extends EntityAction {
  final EntityState state;
  bool _isDone = false;

  PlayAnimationAction(this.state);

  @override
  bool get isDone => _isDone;

  @override
  void start(EntityComponent entity) {
    entity.playState(state);
    final ticker = entity.animationTickers?[state];

    if (ticker != null) {
      ticker.reset();
      // Feliratkozás az animáció végére: amint kész, az akció is kész.
      ticker.onComplete = () {
        _isDone = true;
        ticker.onComplete = null;
      };
    } else {
      _isDone =
          true; // Biztonsági elágazás: ha nincs ticker, ne akadjon meg a sor.
    }
  }

  @override
  void update(EntityComponent entity, double dt) {}
}

/// 3. Akció: Egyedi függvény (callback) azonnali lefuttatása.
/// Hasznos pl. sebzés levonásához, hang lejátszásához vagy Sprite tükrözéséhez a szekvencia közben.
class CallbackAction extends EntityAction {
  final void Function() callback;
  bool _isDone = false;

  CallbackAction(this.callback);

  @override
  bool get isDone => _isDone;

  @override
  void start(EntityComponent entity) {
    callback();
    _isDone = true; // Azonnal végez.
  }

  @override
  void update(EntityComponent entity, double dt) {}
}

/// 4. Akció: Várakozás (szünet) tartása a soron következő akció előtt.
class DelayAction extends EntityAction {
  final double delaySeconds;
  double _timer = 0;

  DelayAction(this.delaySeconds);

  @override
  bool get isDone => _timer >= delaySeconds;

  @override
  void start(EntityComponent entity) {}

  @override
  void update(EntityComponent entity, double dt) {
    _timer += dt;
  }
}

/// Az akciókat kezelő és ütemező menedzser osztály.
class ActionQueue {
  final List<EntityAction> _actions = [];
  EntityAction? _currentAction;

  /// Új akció hozzáadása a sor végére.
  void add(EntityAction action) {
    _actions.add(action);
  }

  /// Sor törlése és az aktuális akció megszakítása.
  void clear() {
    _actions.clear();
    _currentAction = null;
  }

  /// Igaz, ha nincs több végrehajtandó feladat.
  bool get isEmpty => _actions.isEmpty && _currentAction == null;

  /// Frissíti a sort: ha egy akció véget ér, automatikusan indítja a következőt.
  void update(EntityComponent entity, double dt) {
    // Ha nincs futó akció, de van várakozó, indítsuk el a következőt.
    if (_currentAction == null && _actions.isNotEmpty) {
      _currentAction = _actions.removeAt(0);
      _currentAction!.start(entity);
    }

    // Aktuális akció léptetése.
    if (_currentAction != null) {
      _currentAction!.update(entity, dt);

      // Ha az akció befejezte a munkáját, felszabadítjuk a helyet.
      if (_currentAction!.isDone) {
        _currentAction = null;
      }
    }
  }
}
