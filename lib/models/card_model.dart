// A kvízkártyák adatmodelljeinek megvalósítása.
// Ez a fájl tartalmazza az absztrakt alaposztályt és a konkrét kártyatípusokat
// (feleletválasztós, többszörös kijelölés, párosítás, rövid válasz).
// A rendszer a Factory tervezési mintát használja a JSON adatok feldolgozásához.

abstract class QuizCard {
  final String id;
  final String question;
  final String type;
  int order;

  QuizCard({
    required this.id,
    required this.question,
    required this.type,
    required this.order,
  });

  /// Absztrakt metódus az objektum Map (JSON) formátumba alakításához.
  Map<String, dynamic> toMap();

  /// Factory metódus, amely a "type" mező alapján a megfelelő alosztályt példányosítja.
  factory QuizCard.fromMap(Map<String, dynamic> map, String docId) {
    final type = map['type'] as String;

    switch (type) {
      case 'multiple_choice':
        return MultipleChoiceCard.fromMap(map, docId);
      case 'multiple_select':
        return MultipleSelectCard.fromMap(map, docId);
      case 'matching':
        return MatchingCard.fromMap(map, docId);
      case 'short_answer':
        return ShortAnswerCard.fromMap(map, docId);
      default:
        throw Exception('Ismeretlen kártyatípus: $type');
    }
  }
}

/// [MultipleChoiceCard] - Egyetlen helyes választ tartalmazó kártyatípus.
class MultipleChoiceCard extends QuizCard {
  final List<String> options;
  final int correctIndex;

  MultipleChoiceCard({
    required super.id,
    required super.question,
    required super.order,
    required this.options,
    required this.correctIndex,
  }) : super(type: 'multiple_choice');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'order': order,
      'options': options,
      'correct_index': correctIndex,
    };
  }

  factory MultipleChoiceCard.fromMap(Map<String, dynamic> map, String docId) {
    return MultipleChoiceCard(
      id: docId,
      question: map['question'] ?? '',
      order: map['order'] ?? 0,
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correct_index'] ?? 0,
    );
  }
}

/// [MultipleSelectCard] - Olyan kártyatípus, ahol több helyes válasz is kijelölhető.
class MultipleSelectCard extends QuizCard {
  final List<int> correct;
  final List<String> options;

  MultipleSelectCard({
    required super.id,
    required super.question,
    required super.order,
    required this.correct,
    required this.options,
  }) : super(type: 'multiple_select');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'order': order,
      'correct': correct,
      'options': options,
    };
  }

  factory MultipleSelectCard.fromMap(Map<String, dynamic> map, String docId) {
    return MultipleSelectCard(
      id: docId,
      question: map['question'] ?? '',
      order: map['order'] ?? 0,
      options: List<String>.from(map['options'] ?? []),
      correct: List<int>.from(map['correct'] ?? []),
    );
  }
}

/// [MatchingCard] - Párosítós feladat, amely kulcs-érték párokat tartalmaz.
class MatchingCard extends QuizCard {
  final Map<String, String> pairs;

  MatchingCard({
    required super.id,
    required super.question,
    required super.order,
    required this.pairs,
  }) : super(type: 'matching');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'order': order,
      'pairs': pairs
    };
  }

  factory MatchingCard.fromMap(Map<String, dynamic> map, String docId) {
    return MatchingCard(
      id: docId,
      question: map['question'] ?? '',
      order: map['order'] ?? 0,
      pairs: Map<String, String>.from(map['pairs'] ?? {}),
    );
  }
}

/// [ShortAnswerCard] - Kifejtős kérdés, ahol a bemenetet a megadott válaszlistával hasonlítjuk össze.
class ShortAnswerCard extends QuizCard {
  final List<String> answers;

  ShortAnswerCard({
    required super.id,
    required super.question,
    required super.order,
    required this.answers,
  }) : super(type: 'short_answer');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'order': order,
      'answers': answers
    };
  }

  factory ShortAnswerCard.fromMap(Map<String, dynamic> map, String docId) {
    return ShortAnswerCard(
      id: docId,
      question: map['question'] ?? '',
      order: map['order'] ?? 0,
      answers: List<String>.from(map['answers'] ?? []),
    );
  }
}
