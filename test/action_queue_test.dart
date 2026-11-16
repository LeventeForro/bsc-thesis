import 'package:flutter_test/flutter_test.dart';
import 'package:szakdolgozat/game/action_queue.dart';
import 'package:szakdolgozat/game/entity_component.dart';

class DummyEntity implements EntityComponent {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------
// MOCK Akció az ütemező logika ellenőrzésére
// ---------------------------------------------------------
class MockAction extends EntityAction {
  bool _isDone = false;
  int startCalls = 0;
  double elapsed = 0.0;

  @override
  bool get isDone => _isDone;

  @override
  void start(dynamic entity) {
    startCalls++;
  }

  @override
  void update(dynamic entity, double dt) {
    elapsed += dt;
  }

  void finish() {
    _isDone = true;
  }
}

// ---------------------------------------------------------
// TESZTEK
// ---------------------------------------------------------
void main() {
  group('Action Queue és Command Pattern Tesztek', () {
    late ActionQueue queue;

    final dummyEntity = DummyEntity();

    setUp(() {
      queue = ActionQueue();
    });

    test('Az akciók szigorúan sorban (szekvenciálisan) hajtódnak végre', () {
      final action1 = MockAction();
      final action2 = MockAction();

      queue.add(action1);
      queue.add(action2);

      expect(queue.isEmpty, false);

      // 1. Frissítés: Az első akciót kiveszi a sorból és elindítja
      queue.update(dummyEntity, 0.1);
      expect(action1.startCalls, 1);
      expect(action2.startCalls, 0);

      // 2. Frissítés: Az első akció fut tovább
      queue.update(dummyEntity, 0.1);
      expect(action1.elapsed, 0.2);
      expect(action2.startCalls, 0);

      // 3. Az első akció végrehajtása befejeződik!
      action1.finish();
      queue.update(dummyEntity, 0.1);

      // 4. Következő frissítés: A sornak automatikusan indítania kell a következőt!
      queue.update(dummyEntity, 0.1);
      expect(action2.startCalls, 1);
    });

    test('DelayAction pontosan a megadott ideig várakoztatja a sort', () {
      final delayAction = DelayAction(1.0);
      queue.add(delayAction);

      queue.update(dummyEntity, 0.5);
      expect(delayAction.isDone, false);
      expect(queue.isEmpty, false);

      queue.update(dummyEntity, 0.5);
      expect(delayAction.isDone, true);

      queue.update(dummyEntity, 0.1);
      expect(queue.isEmpty, true);
    });

    test('CallbackAction azonnal lefut és befejezetté (isDone) válik', () {
      bool wasCalled = false;
      final callbackAction = CallbackAction(() {
        wasCalled = true;
      });

      queue.add(callbackAction);

      queue.update(dummyEntity, 0.1);

      expect(wasCalled, true);
      expect(callbackAction.isDone, true);
    });

    test('A clear() metódus azonnal kiüríti a várakozási sort', () {
      queue.add(MockAction());
      queue.add(MockAction());
      queue.add(MockAction());

      expect(queue.isEmpty, false);

      queue.clear();

      expect(queue.isEmpty, true);
    });
  });
}
