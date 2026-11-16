// A tantárgyak és félévek adatmodelljei.
// Ezek az osztályok strukturálják a "történetmód" (leckekönyv) adatait,
// lehetővé téve a haladás követését és a szintek közötti függőségek kezelését.

class SubjectLevel {
  final String id;
  final String name;
  final String enemyId;
  final String jsonFileName;
  final String enemyQuote;
  bool isCompleted;
  final int xpReward;
  final Map<String, int>? fixedEnemyStats;

  /// Egy tantárgy (szint) adatai: azonosító, név, az adott szint ellensége és a kérdések forrásfájlja.
  SubjectLevel({
    required this.id,
    required this.name,
    required this.enemyId,
    required this.jsonFileName,
    required this.enemyQuote,
    this.isCompleted = false,
    this.xpReward = 50,
    this.fixedEnemyStats,
  });
}

class SemesterData {
  final int number;
  final String title;
  final List<SubjectLevel> subjects;
  bool isUnlocked;

  /// Egy teljes félév adatait összefogó modell, amely tartalmazza az adott félév tantárgyait.
  SemesterData({
    required this.number,
    required this.title,
    required this.subjects,
    this.isUnlocked = false,
  });

  /// Visszaadja a félévben már teljesített tantárgyak számát.
  int get completedSubjects => subjects.where((s) => s.isCompleted).length;

  /// Visszaadja a félévben található összes tantárgy számát.
  int get totalSubjects => subjects.length;
}
