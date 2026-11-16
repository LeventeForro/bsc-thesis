// Ez a fájl a mérkőzés utáni összegző képernyőért (MatchHistoryScreen) felel.
// Megjeleníti a kör statisztikáit (pontosság, helyes válaszok száma) és
// egy részletes listát a kérdésekről, ahol a játékos visszanézheti a hibáit.

import 'package:flutter/material.dart';
import '../models/card_model.dart';

class MatchHistoryScreen extends StatelessWidget {
  /// A mérkőzés eseményeinek listája.
  /// Minden elem tartalmazza a kérdés kártyát és a válasz helyességét.
  final List<Map<String, dynamic>> history;

  const MatchHistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text('MATCH SUMMARY',
            style: TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 2,
              fontSize: 18,
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Kilépés gomb: azonnali visszatérés az előző képernyőre
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('EXIT',
                style: TextStyle(
                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statisztikai modul (Pontosság % és Helyes/Összes számláló)
          _buildStatHeader(),

          // Görgethető lista a kérdés-válasz párosokról
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final bool isCorrect = item['is_correct'] ?? false;
                final QuizCard card = item['card'];

                return _buildHistoryCard(card, isCorrect);
              },
            ),
          ),

          // Alsó navigációs gomb a biztonsági zónán belül
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('BACK TO MENU',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kiszámítja és megjeleníti az összesített körstatisztikákat.
  Widget _buildStatHeader() {
    int correctCount = history.where((e) => e['is_correct'] == true).length;
    double percentage =
        history.isEmpty ? 0 : (correctCount / history.length) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("ACCURACY", "${percentage.toStringAsFixed(0)}%"),
          _statItem("CORRECT", "$correctCount / ${history.length}"),
        ],
      ),
    );
  }

  /// RPG stílusú statisztikai adatpont megjelenítése.
  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Létrehoz egy vizuális elemet egy kérdéshez.
  /// A [ExpansionTile] segítségével a helyes megoldás alapértelmezetten rejtett.
  Widget _buildHistoryCard(QuizCard card, bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isCorrect
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        iconColor: isCorrect ? Colors.greenAccent : Colors.redAccent,
        collapsedIconColor: isCorrect ? Colors.greenAccent : Colors.redAccent,
        leading: Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? Colors.greenAccent : Colors.redAccent,
        ),
        title: Text(
          card.question,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isCorrect ? "Correct answer" : "Review needed",
          style: TextStyle(
              color: isCorrect
                  ? Colors.greenAccent.withOpacity(0.7)
                  : Colors.redAccent.withOpacity(0.7),
              fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // A kiterjesztett részben jelenik meg a konkrét megoldás
          _buildCorrectAnswerSection(card),
        ],
      ),
    );
  }

  /// Megformázza a helyes választ a kártya típusa (feleletválasztós, párosítós, stb.) alapján.
  Widget _buildCorrectAnswerSection(QuizCard card) {
    String answerText = "";

    if (card is MultipleChoiceCard) {
      answerText = card.options[card.correctIndex];
    } else if (card is MultipleSelectCard) {
      answerText = card.correct.map((i) => card.options[i]).join(", ");
    } else if (card is ShortAnswerCard) {
      answerText = card.answers.join(" / ");
    } else if (card is MatchingCard) {
      answerText = card.pairs.entries
          .map((entry) => "${entry.key} ➞ ${entry.value}")
          .join("\n");
    } else {
      answerText = "Check original deck for details.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10),
        const Text("THE CORRECT ANSWER WAS:",
            style: TextStyle(
                color: Colors.white54, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(answerText,
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
