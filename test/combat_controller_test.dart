import 'package:flutter_test/flutter_test.dart';
import 'package:szakdolgozat/game/combat_controller.dart';
import 'package:szakdolgozat/game/enemies/goblin.dart';

void main() {
  group('CombatController Állapotkezelés (State) Unit Tesztek', () {
    late CombatController controller;
    late Map<String, int> mockPlayerStats;
    late Goblin mockGoblin;

    setUp(() {
      // 1. Létrehozunk egy fix statisztikát a játékosnak
      mockPlayerStats = {
        'lvl': 1,
        'vit': 10,
        'str': 10,
        'intel': 10,
        'agi': 10,
        'luck': 10,
      };

      // 2. Létrehozunk és inicializálunk egy ellenfelet a teszthez
      mockGoblin = Goblin();
      mockGoblin.currentHp = mockGoblin.baseHPStat;
      mockGoblin.currentAgy = mockGoblin.baseAgy;
      mockGoblin.currentLuck = mockGoblin.baseLuck;

      // 3. Példányosítjuk a vezérlőt tiszta lappal minden teszt előtt
      controller = CombatController(
        playerMaxHealth: 100,
        playerHealth: 100,
        enemyHealth: mockGoblin.maxHealth,
        currentEnemy: mockGoblin,
        playerClass: 'knight',
        playerStats: mockPlayerStats,
      );
    });

    test(
        'Körök múlásával a buffok és debuffok (Turn counters) pontosan csökkennek',
        () {
      // Beállítunk aktív körökhöz kötött effekteket
      controller.armorBreakTurns = 2;
      controller.weakenTurns = 1;

      // Szimuláljuk, hogy egy kör eltelt
      controller.advanceTurn();

      // Ellenőrzés: 1-gyel csökkenniük kellett
      expect(controller.armorBreakTurns, 1);
      expect(controller.weakenTurns, 0);

      // Szimuláljuk, hogy még egy kör eltelt
      controller.advanceTurn();

      // Ellenőrzés: A weakenTurns nem mehet mínuszba, marad 0
      expect(controller.armorBreakTurns, 0);
      expect(controller.weakenTurns, 0);
    });

    test(
        'Gyógyítási korlát: a healEnemy nem töltheti az életerőt a maximum fölé',
        () {
      // Szimuláljuk, hogy a Goblin sérült (levonunk 10 HP-t)
      controller.enemyHealth = mockGoblin.maxHealth - 10;
      expect(controller.enemyHealth, mockGoblin.maxHealth - 10);

      // Gyógyítjuk 50-nel (ami jóval a maxHealth fölé vinné)
      controller.healEnemy(50);

      // Ellenőrzés: A HP pontosan a maxHealth értéken (maximumon) kell megálljon a .clamp miatt
      expect(controller.enemyHealth, mockGoblin.maxHealth);
    });

    test(
        'Védekező mechanika: A lovag pajzsa (activeShield) felfogja a sebzést, majd lenullázódik',
        () {
      // A lovag pajzsa pl. 30%-ot (0.3) véd
      controller.activeShield = 0.3;

      // Szimuláljuk, hogy az ellenfél (Goblin) rátámad a játékosra 0-s kombónál
      final attackResult = controller.executeEnemyAttack(0);

      // Ellenőrzés 1: Az activeShield-nek a találat után azonnal 0.0-ra kell állnia
      expect(controller.activeShield, 0.0);

      // Ellenőrzés 2: A játékos életerejének csökkennie kellett (mert kapott sebzést)
      expect(controller.playerHealth < 100, true);

      // Ellenőrzés 3: A visszatérő eredményben lévő sebzés értéke nem lehet null
      expect(attackResult['damage'] != null, true);
    });
  });
}
