// A kvízkérdések logikai kiértékelője.
// Ez az osztály felelős a különböző kártyatípusok (feleletválasztós, párosítós, kifejtős)
// válaszainak ellenőrzéséért, és az eredmény visszaküldéséért a hősök támadási logikája felé.

import 'package:flutter/widgets.dart';
import '../models/card_model.dart';
import '../services/ai_service.dart';

class QuizController {
  /// Callback függvény, amely a kiértékelés után jelzi a játéknak, hogy a válasz helyes-e.
  final void Function(bool isCorrect) onResult;

  QuizController({required this.onResult});

  /// Feleletválasztós kártya (MultipleChoiceCard) ellenőrzése index alapján.
  void checkMultipleChoice(MultipleChoiceCard card, int idx) {
    onResult(idx == card.correctIndex);
  }

  /// Többszörös választás (MultipleSelectCard) ellenőrzése.
  /// Csak akkor helyes, ha a felhasználó pontosan a jó válaszokat jelölte ki.
  void checkMultipleSelect(MultipleSelectCard card, List<int> selectedIndices) {
    final userSet = selectedIndices.toSet();
    final correctSet = card.correct.toSet();

    onResult(
        userSet.length == correctSet.length && userSet.containsAll(correctSet));
  }

  /// Rövid kifejtős válasz (ShortAnswerCard) ellenőrzése.
  /// Mivel a természetes nyelvi válaszok változatosak lehetnek, egy AI szervizt (AiService)
  /// használunk a szemantikai helyesség eldöntésére.
  Future<void> checkShortAnswer(
    ShortAnswerCard card,
    String input, {
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) async {
    if (input.trim().isEmpty) return;

    onStart(); // UI jelzés a betöltés/elemzés megkezdéséről

    final isCorrect = await AiService().evaluateShortAnswer(
      card.question,
      card.answers,
      input.trim(),
    );

    onEnd(); // UI jelzés az elemzés befejezéséről
    onResult(isCorrect);
  }

  /// Párosítós feladat (MatchingCard) interakcióinak kezelése.
  /// Ez a metódus kezeli a kijelöléseket és folyamatosan figyeli a megoldott párok számát.
  MatchingResult handleMatchingTap({
    required MatchingCard card,
    required String item,
    required bool isLeft,
    required String? selectedLeftItem,
    required Map<String, String> solvedPairs,
  }) {
    // 1. Ellenőrzés: Ha az elem már meg van oldva, ne csináljunk semmit
    if (isLeft && solvedPairs.containsKey(item)) {
      return MatchingResult(
        newSelectedLeft: selectedLeftItem,
        solvedPairs: Map<String, String>.from(solvedPairs),
      );
    }
    if (!isLeft && solvedPairs.containsValue(item)) {
      return MatchingResult(
        newSelectedLeft: selectedLeftItem,
        solvedPairs: Map<String, String>.from(solvedPairs),
      );
    }

    // 2. Bal oldali kijelölés kezelése
    if (isLeft) {
      return MatchingResult(newSelectedLeft: item, solvedPairs: solvedPairs);
    }

    // 3. Ha nincs kijelölt elem balról, nem történhet párosítás
    if (selectedLeftItem == null) {
      return MatchingResult(newSelectedLeft: null, solvedPairs: solvedPairs);
    }

    // 4. Konkrét ellenőrzés
    String expectedValue = card.pairs[selectedLeftItem] ?? "";

    if (expectedValue.trim() == item.trim()) {
      final updated = Map<String, String>.from(solvedPairs)
        ..[selectedLeftItem] = item;

      final isComplete = updated.length == card.pairs.length;

      // Ha az egész kártya sikeresen befejeződött, jelezzük a UI-nak a győzelmet
      if (isComplete) {
        onResult(true);
      }

      return MatchingResult(
        newSelectedLeft: null,
        solvedPairs: updated,
        isComplete: isComplete,
        isCorrect: isComplete ? true : null,
      );
    } else {
      // Hiba esetén nem változtatunk a solvedPairs-en, de jelzünk a UI-nak, hogy helytelen volt a próbálkozás
      onResult(false);

      return MatchingResult(
        newSelectedLeft: null,
        solvedPairs: solvedPairs,
        isCorrect: false,
        isComplete: true,
      );
    }
  }
}

/// A párosítási folyamat aktuális állapotát leíró segédmodell.
class MatchingResult {
  final String? newSelectedLeft; // Az aktuálisan kijelölt elem a bal oldalon
  final Map<String, String> solvedPairs; // A már sikeresen párosított elemek
  final bool isComplete; // Kész-e a teljes kártya
  final bool? isCorrect; // A legutóbbi interakció eredménye (helyes/helytelen)

  const MatchingResult({
    required this.newSelectedLeft,
    required this.solvedPairs,
    this.isComplete = false,
    this.isCorrect,
  });
}
