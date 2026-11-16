import 'hero_base.dart';
import 'knight.dart';
import 'archer.dart';
import 'necromancer.dart';

/// A játékban elérhető hősök központi regisztere.
class HeroRegistry {
  /// Az összes hős példányának statikus tárolása az azonosítójuk (classId) alapján.
  static final Map<String, HeroBase> _heroes = {
    'knight': Knight(),
    'archer': Archer(),
    'necromancer': Necromancer(),
  };

  /// Megkeresi és visszaadja a megadott azonosítójú hőst.
  /// Ismeretlen azonosító esetén alapértelmezésben a Lovagot adja vissza.
  static HeroBase getHero(String classId) {
    return _heroes[classId] ?? _heroes['knight']!;
  }

  /// Visszaadja az összes regisztrált hős listáját a választómenük feltöltéséhez.
  static List<HeroBase> getAllHeroes() {
    return _heroes.values.toList();
  }
}
