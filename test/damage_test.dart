import 'package:flutter_test/flutter_test.dart';
import 'package:szakdolgozat/game/heroes/archer.dart';
import 'package:szakdolgozat/game/heroes/knight.dart';
import 'package:szakdolgozat/game/heroes/necromancer.dart';
import 'package:szakdolgozat/game/enemies/flying_eye.dart';
import 'package:szakdolgozat/game/enemies/goblin.dart';
import 'package:szakdolgozat/game/enemies/skeleton.dart';
import 'package:szakdolgozat/game/enemies/mushroom.dart';

void main() {
  // --- HŐSÖK ---

  group('Archer Class Unit Tesztek', () {
    late Archer archer;

    setUp(() {
      archer = Archer();
    });

    test('Alap statisztikák betöltése', () {
      final stats = archer.baseStats;
      expect(stats['vitality'], 8);
      expect(stats['strength'], 5);
      expect(stats['agility'], 15);
    });

    test('Képességek (Skills) sebzésének ellenőrzése', () {
      final testStats = {'str': 10, 'agi': 10};

      // 1. Képesség: 10.0 + (agi * 0.6) -> 10 + 6 = 16.0
      expect(archer.skills[1]!.formula(testStats), 16.0);

      // 2. Képesség: Nem sebez -> 0.0
      expect(archer.skills[2]!.formula(testStats), 0.0);

      // 3. Képesség: 4.0 + (agi * 0.3) -> 4 + 3 = 7.0
      expect(archer.skills[3]!.formula(testStats), 7.0);

      // 4. Képesség: 20.0 + (agi * 3.0) + (str * 1.5) -> 20 + 30 + 15 = 65.0
      expect(archer.skills[4]!.formula(testStats), 65.0);
    });
  });

  group('Knight Class Unit Tesztek', () {
    late Knight knight;

    setUp(() {
      knight = Knight();
    });

    test('Alap statisztikák betöltése', () {
      final stats = knight.baseStats;
      expect(stats['vitality'], 15);
      expect(stats['strength'], 12);
      expect(stats['intellect'], 3);
    });

    test('Képességek (Skills) sebzésének ellenőrzése', () {
      // Fix értékek a matematika teszteléséhez
      final testStats = {'str': 10, 'agi': 10, 'luck': 10};

      // 1. Képesség: 10.0 + (str * 0.5) -> 10 + 5 = 15.0
      expect(knight.skills[1]!.formula(testStats), 15.0);

      // 2. Képesség: Nem sebez -> 0.0
      expect(knight.skills[2]!.formula(testStats), 0.0);

      // 3. Képesség: 8.0 + (str * 0.5) + (agi * 0.8) -> 8 + 5 + 8 = 21.0
      expect(knight.skills[3]!.formula(testStats), 21.0);

      // 4. Képesség: (str * 2.5) + (luck * 1.2) -> 25 + 12 = 37.0
      expect(knight.skills[4]!.formula(testStats), 37.0);
    });
  });

  group('Necromancer Class Unit Tesztek', () {
    late Necromancer necro;

    setUp(() {
      necro = Necromancer();
    });

    test('Alap statisztikák betöltése', () {
      final stats = necro.baseStats;
      expect(stats['vitality'], 10);
      expect(stats['intellect'], 13);
      expect(stats['strength'], 4);
    });

    test('Képességek (Skills) sebzésének ellenőrzése', () {
      // Fix értékek a matematika teszteléséhez
      final testStats = {'intel': 10};

      // 1. Képesség: 10.0 + (intel * 0.8) -> 10 + 8 = 18.0
      expect(necro.skills[1]!.formula(testStats), 18.0);

      // 2. Képesség: Nem sebez -> 0.0
      expect(necro.skills[2]!.formula(testStats), 0.0);

      // 3. Képesség: 15.0 + (intel * 1.2) -> 15 + 12 = 27.0
      expect(necro.skills[3]!.formula(testStats), 27.0);

      // 4. Képesség: 25.0 + (intel * 4.0) -> 25 + 40 = 65.0
      expect(necro.skills[4]!.formula(testStats), 65.0);
    });
  });

  // --- ELLENFELEK ---

  group('Ellenfelek (Enemies) Unit Tesztek', () {
    test('Flying Eye sebzés kalkuláció és mágia ellenállás', () {
      final flyingEye = FlyingEye();
      // Fix értékek a matematika teszteléséhez
      flyingEye.currentInt = flyingEye.baseInt; // 13
      flyingEye.currentLuck = flyingEye.baseLuck;

      // 0. Támadás (1.0x szorzó): 6.0 + (13 * 1.6) = 26.8
      final attack = flyingEye.attacks[0];
      final playerStats = {'intellect': 10};

      // Játékos intellektusa csökkenti a sebzést: 26.8 - (10 / 2) = 21.8 -> kerekítve 22
      final result = flyingEye.calculateDamage(attack, playerStats);
      if (!result.isCrit) {
        expect(result.damage, 22);
      }
    });

    test('Goblin fizikai sebzés és kombó-reakció', () {
      final goblin = Goblin();
      // Fix értékek a matematika teszteléséhez
      goblin.currentAgy = goblin.baseAgy; // 12
      goblin.currentLuck = goblin.baseLuck;

      // 3-as kombónál az 1.5x szorzójú támadást (SNEAKY SLASH) választja
      final selectedAttack = goblin.chooseAttack(3);
      expect(selectedAttack.attackName, "SNEAKY SLASH");

      // Alapsebzés: 5.0 + (12 * 1.2) = 19.4
      // Támadás szorzóval: 19.4 * 1.5 = 29.1
      final playerStats = {'agility': 8};

      // Játékos agilitása csökkenti: 29.1 - (8 / 2) = 25.1 -> kerekítve 25
      final result = goblin.calculateDamage(selectedAttack, playerStats);

      if (!result.isCrit) {
        expect(result.damage, 25);
      }
    });

    test('Mushroom tank tulajdonságok és sebzés elnyelés', () {
      final mushroom = Mushroom();
      // Fix értékek a matematika teszteléséhez
      mushroom.currentHp = mushroom.baseHPStat; // 8
      mushroom.currentLvl = 1;

      // Max HP: ((8 * 5 + (1 * 2)) * 1.2).round() -> (42 * 1.2) = 50.4 -> 50
      expect(mushroom.maxHealth, 50);

      // Alapsebzés: 3.0 + (8 * 0.5) = 7.0
      final attack = mushroom.attacks[0];
      final playerStats = {'vitality': 20};

      // Játékos vitalitása csökkenti: 7.0 - (20 / 2) = -3.0 -> minimum értékre clampelve: 1
      final result = mushroom.calculateDamage(attack, playerStats);
      expect(result.damage, 1);
      expect(result.isCrit, false); // Gomba nem okozhat kritikus találatot
    });

    test('Skeleton csontpajzs mechanika', () {
      final skeleton = Skeleton();
      // Fix értékek a matematika teszteléséhez
      skeleton.currentStr = skeleton.baseStr; // 12

      // Csontpajzs fizikai védelme: strength / 2 -> 12 / 2 = 6.0
      const incomingPhysicalDamage = 20.0;
      // Kapott fizikai sebzés: 20.0 - 6.0 = 14.0
      final mitigatedDamage =
          skeleton.calculateIncomingDamage(incomingPhysicalDamage, 'knight');
      expect(mitigatedDamage, 14.0);

      // Mágikus támadás ellen a csontpajzs nem véd, marad 20.0
      const incomingMagicDamage = 20.0;
      final fullDamage =
          skeleton.calculateIncomingDamage(incomingMagicDamage, 'necromancer');
      expect(fullDamage, 20.0);
    });
  });
}
