// Az Leckekönyv képernyő megvalósítása.
// Ez a komponens felelős a felhasználó haladásának megjelenítéséért, a félévek
// zárolásának kezeléséért és a tantárgyakhoz tartozó vizsgák (játékmenet) elindításáért.

import 'package:flutter/material.dart';
import 'story_model.dart';
import 'story_registry.dart';
import '../../screens/game_screen.dart';
import '../../models/card_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  List<SemesterData> semesters = [];
  bool isLoading = true; // Jelzi, amíg a hálózati adatok betöltődnek

  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color accentGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadProgress(); // Induláskor lekérjük a teljesített tárgyakat
  }

  /// Betölti a felhasználó haladását a Firestore-ból és feloldja a féléveket.
  Future<void> _loadProgress() async {
    final baseSemesters = StoryRegistry.getUniversityStory();
    List<String> completedSubjects = [];

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Felhő alapú szinkronizáció a FirestoreService segítségével
      completedSubjects =
          await FirestoreService().getCompletedSubjects(user.uid);
    }

    setState(() {
      for (int i = 0; i < baseSemesters.length; i++) {
        final semester = baseSemesters[i];

        // Tantárgyak állapotának frissítése (kipipálás)
        for (var subject in semester.subjects) {
          if (completedSubjects.contains(subject.id)) {
            subject.isCompleted = true;
          }
        }

        // Félév zárolásának feloldása: az első mindig elérhető, a többi csak
        // akkor, ha az előző félév minden tárgya teljesítve van.
        if (i == 0) {
          semester.isUnlocked = true;
        } else {
          final previousSemester = baseSemesters[i - 1];
          semester.isUnlocked = (previousSemester.completedSubjects ==
              previousSemester.totalSubjects);
        }
      }

      semesters = baseSemesters;
      isLoading = false;
    });
  }

  /// Tantárgy elindítása: kártyák betöltése, keverése és navigáció a harci képernyőre.
  void _startSubject(SubjectLevel subject) async {
    try {
      // JSON alapú tananyag betöltése
      List<QuizCard> loadedCards =
          await StoryLoader.loadSubjectCards(subject.jsonFileName);

      if (loadedCards.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("A vizsga kérdései üresek!"),
              backgroundColor: Colors.orange),
        );
        return;
      }

      // Véletlenszerű 12 kérdés kiválasztása a teszthez
      loadedCards.shuffle();
      int questionsToTake = loadedCards.length > 12 ? 12 : loadedCards.length;
      List<QuizCard> selectedCards = loadedCards.take(questionsToTake).toList();

      if (!mounted) return;

      // Átlépés a harci (játék) képernyőre
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            title: subject.name,
            predefinedCards: selectedCards,
            fixedEnemyId: subject.enemyId,
            maxQuestionsLimit: selectedCards.length,
            storySubjectId: subject.id,
            enemyQuote: subject.enemyQuote,
            storyXpReward: subject.xpReward,
            fixedEnemyStats: subject.fixedEnemyStats,
          ),
        ),
      );

      // Miután a játékos végzett és visszatért, frissítjük a pipákat és zárakat
      _loadProgress();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Ez a tananyag még fejlesztés alatt áll! ($e)"),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('FÉLÉVEK',
            style: TextStyle(
                fontFamily: 'monospace', letterSpacing: 2, color: accentGold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: accentGold),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGold))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: semesters.length,
              itemBuilder: (context, index) {
                final semester = semesters[index];
                return _buildSemesterCard(semester);
              },
            ),
    );
  }

  /// Egy félév kártyájának vizuális felépítése (ExpansionTile a tárgyak elrejtéséhez).
  Widget _buildSemesterCard(SemesterData semester) {
    bool isLocked = !semester.isUnlocked;

    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isLocked ? Colors.white10 : accentGold.withOpacity(0.5),
            width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: isLocked ? Colors.white24 : accentGold,
          iconColor: accentGold,
          leading: Icon(
            isLocked ? Icons.lock : Icons.school,
            color: isLocked ? Colors.white24 : accentGold,
            size: 30,
          ),
          title: Text(
            semester.title,
            style: TextStyle(
              color: isLocked ? Colors.white24 : Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          subtitle: Text(
            isLocked
                ? "Zárolva (Teljesítsd az előző félévet!)"
                : "Teljesítve: ${semester.completedSubjects} / ${semester.totalSubjects}",
            style: TextStyle(
                color: isLocked ? Colors.white10 : Colors.white54,
                fontSize: 12),
          ),
          children: isLocked
              ? [] // Zárolt félév esetén nincsenek lenyitható tantárgyak
              : semester.subjects
                  .map((subject) => _buildSubjectTile(subject))
                  .toList(),
        ),
      ),
    );
  }

  /// Egy tantárgy sorának (ListTile) megjelenítése gombbal és állapotjelzővel.
  Widget _buildSubjectTile(SubjectLevel subject) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Icon(
          subject.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: subject.isCompleted ? Colors.greenAccent : Colors.white38,
        ),
        title: Text(
          subject.name,
          style: TextStyle(
              color: subject.isCompleted ? Colors.white54 : Colors.white,
              fontSize: 14),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: subject.isCompleted ? Colors.white10 : accentGold,
            foregroundColor: subject.isCompleted ? Colors.white : Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _startSubject(subject),
          child: Text(subject.isCompleted ? "ISMÉTLÉS" : "VIZSGA",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
