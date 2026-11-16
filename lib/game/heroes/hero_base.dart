// A karakterek absztrakt alaposztálya.
// Ez a fájl határozza meg a játékos által irányítható karakterek közös interfészét,
// beleértve a statisztikákat, a vizuális konfigurációt és a képességek kezelését.

import '../../models/skill_model.dart';
import '../battle_game.dart';
import '../entity_component.dart';

/// Minden hős alaposztálya, amely összefogja a közös tulajdonságokat és elvárásokat.
abstract class HeroBase {
  String get id;
  String get name;
  String get description;

  /// Alap statisztikák (vitality, strength, intellect, agility, luck) gyűjteménye.
  Map<String, int> get baseStats;

  /// A hős vizuális megjelenéséért és animációs fájljaiért felelős konfiguráció.
  EntityConfig get entityConfig;

  /// A hős egyedi képességei, az akciópont költség (1-4) alapján indexelve.
  Map<int, Skill> get skills;

  /// Összeköti a logikai képességhasználatot a vizuális Flame animációkkal és effektekkel.
  void triggerSkillVisuals(int cost, BattleGame game);
}
