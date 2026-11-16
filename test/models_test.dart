import 'package:flutter_test/flutter_test.dart';
import 'package:szakdolgozat/models/card_model.dart';
import 'package:szakdolgozat/models/deck_model.dart';

void main() {
  group('Adatmodellek és JSON feldolgozás Tesztek', () {
    test('Deck modell fromMap és toMap teszt', () {
      // Mock JSON adat
      final mockData = {
        'title': 'Szoftvertechnológia',
        'description': 'Alapvető fogalmak',
        'owner_id': 'user123',
        'is_public': true,
        'card_count': 10,
      };

      // 2. JSON -> Dart Object
      final deck = Deck.fromMap(mockData, 'deck_id_1');

      expect(deck.id, 'deck_id_1');
      expect(deck.title, 'Szoftvertechnológia');
      expect(deck.isPublic, true);
      expect(deck.cardCount, 10);

      // 3. Dart Object -> JSON
      final map = deck.toMap();
      expect(map['title'], 'Szoftvertechnológia');
      expect(map.containsKey('created_at'), true);
    });

    test('Feleletválasztós kártya (MultipleChoice) polimorf betöltése', () {
      final mockData = {
        'type': 'multiple_choice',
        'question': 'Mi az a Flutter?',
        'order': 1,
        'options': ['Keretrendszer', 'Játék', 'Adatbázis'],
        'correct_index': 0,
      };

      final card = QuizCard.fromMap(mockData, 'card_1');

      expect(card, isA<MultipleChoiceCard>());

      final mcCard = card as MultipleChoiceCard;
      expect(mcCard.question, 'Mi az a Flutter?');
      expect(mcCard.options.length, 3);
      expect(mcCard.correctIndex, 0);
    });

    test('Párosítós kártya (MatchingCard) betöltése', () {
      final mockData = {
        'type': 'matching',
        'question': 'Párosítsd a fogalmakat!',
        'order': 2,
        'pairs': {
          'Flutter': 'UI Toolkit',
          'Firebase': 'BaaS',
        }
      };

      final card = QuizCard.fromMap(mockData, 'card_2');
      expect(card, isA<MatchingCard>());

      final matchingCard = card as MatchingCard;
      expect(matchingCard.pairs['Flutter'], 'UI Toolkit');
      expect(matchingCard.pairs.length, 2);
    });

    test(
        'Több válaszos kártya (MultipleSelectCard) hiányzó mezőkkel (Fallback teszt)',
        () {
      final mockData = {
        'type': 'multiple_select',
        'options': ['A', 'B', 'C'],
        'correct': [0, 2],
      };

      final card = QuizCard.fromMap(mockData, 'card_3');
      expect(card, isA<MultipleSelectCard>());

      final msCard = card as MultipleSelectCard;
      expect(msCard.order, 0);
      expect(msCard.question, '');
      expect(msCard.correct, [0, 2]);
    });

    test('Rövid válasz kártya (ShortAnswerCard) toMap szerializáció', () {
      final saCard = ShortAnswerCard(
        id: 'card_4',
        question: 'Milyen nyelvet használ a Flutter?',
        order: 4,
        answers: ['Dart', 'dart'],
      );

      final map = saCard.toMap();
      expect(map['type'], 'short_answer');
      expect(map['id'], 'card_4');
      expect(map['answers'], ['Dart', 'dart']);
    });

    test('Ismeretlen kártyatípus kivételt (Exception) dob', () {
      final mockData = {
        'type': 'valami_uj_tipus',
        'question': 'Ez hibára fut?',
      };

      expect(() => QuizCard.fromMap(mockData, 'error_card'), throwsException);
    });
  });
}
