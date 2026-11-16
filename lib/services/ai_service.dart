// Ez a fájl az AI alapú szolgáltatásokért felelős osztályt (AiService) tartalmazza.
// A Google Gemini modelljeit használja kérdésgenerálásra, adaptív tanulási útvonalak
// kialakítására és a szöveges válaszok szemantikai (tartalmi) ellenőrzésére.

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/card_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  // API KULCS - A Google AI Studio-ból származik (Gemini API eléréshez)
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Egységesített, stabil modell név
  static const String _modelName = 'gemini-2.5-flash';

  // Szigorú angol nyelvű JSON séma és PEDAGÓGIAI SZABÁLYOK
  static const String _jsonSchema = '''
  CRITICAL QUALITY RULES FOR QUIZ CREATION:
  1. FACTUAL ACCURACY: Every question must be 100% factually correct. Double-check your knowledge before creating the answers. Do not hallucinate facts.
  2. UNAMBIGUOUS: Questions must be clear and logical. There must be NO debate about which answer is correct.
  3. PLAUSIBLE DISTRACTORS: Incorrect options must seem plausible to a learner, but must be definitively wrong.
  4. CORRECT INDEXING: You must guarantee that the "correct_index" or "correct" array points to the actual correct answer(s) in the options array (0-indexed).
  5. LANGUAGE: The content itself (questions, options, pairs, answers) MUST BE WRITTEN IN HUNGARIAN!

  You must strictly follow this exact JSON array structure. Do not deviate from these keys.
  [
    {
      "id": "ai_gen_1",
      "type": "multiple_choice",
      "question": "[Hungarian multiple choice question]",
      "order": 1,
      "options": [
        "[Option A]",
        "[Option B]",
        "[Option C]",
        "[Option D]"
      ],
      "correct_index": 1
    },
    {
      "id": "ai_gen_2",
      "type": "multiple_select",
      "question": "[Hungarian multiple select question]",
      "order": 2,
      "options": ["[Option A]", "[Option B]", "[Option C]", "[Option D]", "[Option E]"],
      "correct": [0, 2, 3]
    },
    {
      "id": "ai_gen_3",
      "type": "matching",
      "question": "[Hungarian instruction, e.g., Párosítsd a fogalmakat a jelentésükkel!]",
      "order": 3,
      "pairs": {
        "[Hungarian Concept 1]": "[Hungarian Definition 1]",
        "[Hungarian Concept 2]": "[Hungarian Definition 2]",
        "[Hungarian Concept 3]": "[Hungarian Definition 3]"
      }
    },
    {
      "id": "ai_gen_4",
      "type": "short_answer",
      "question": "[Hungarian question requiring a specific short answer]",
      "order": 4,
      "answers": ["[Hungarian Correct Answer]", "[Alternative correct Hungarian word]"]
    }
  ]
  ''';

  /// Legenerál egy kezdeti kártyacsomagot egy megadott témában.
  Future<List<QuizCard>> generateEndlessQuestions(String topic, int count,
      {void Function(double progress, String status)? onProgress}) async {
    onProgress?.call(0.1, 'Modell inicializálása...');

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        // A Temperature csökkentése a tényszerűség érdekében!
        temperature: 0.2,
      ),
    );

    final prompt = '''
    You are a meticulous and expert educational RPG game quiz creator.
    Generate $count diverse quiz questions about the following topic: "$topic".
    You must use a mix of the following 4 question types: multiple_choice, multiple_select, matching, short_answer.
    
    CRITICAL RULE: All questions, answers, and options MUST BE IN HUNGARIAN LANGUAGE.
    Your response must be a valid JSON array only. Do not write any markdown or conversational text.
    
    $_jsonSchema
    ''';

    try {
      onProgress?.call(
          0.3, 'Kérés küldése az AI-nak (ez eltarthat pár másodpercig)...');
      final response = await model.generateContent([Content.text(prompt)]);

      onProgress?.call(0.8, 'AI válaszának feldolgozása...');
      String responseText = response.text ?? '[]';

      responseText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> jsonList = jsonDecode(responseText);

      List<QuizCard> generatedCards = [];
      for (int i = 0; i < jsonList.length; i++) {
        var cardData = jsonList[i];
        cardData['order'] = i;
        String fakeId = 'ai_gen_${DateTime.now().millisecondsSinceEpoch}_$i';
        generatedCards.add(QuizCard.fromMap(cardData, fakeId));
      }

      onProgress?.call(1.0, 'Kártyák sikeresen létrehozva!');
      return generatedCards;
    } catch (e) {
      onProgress?.call(0.0, 'GENERATION ERROR: ${e.toString()}');
      return [];
    }
  }

  /// Adaptív kérdés generálás a játékos eddigi teljesítménye alapján.
  Future<List<QuizCard>> generateAdaptiveQuestions(
      String topic, List<Map<String, dynamic>> playerHistory,
      {void Function(double progress, String status)? onProgress}) async {
    onProgress?.call(0.1, 'Előzmények elemzése...');

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // Tényszerűség növelése
      ),
    );

    final recentHistory = playerHistory.length > 6
        ? playerHistory.sublist(playerHistory.length - 6)
        : playerHistory;

    String historyText = recentHistory.isEmpty ? "No data yet." : "";
    for (var record in recentHistory) {
      String result = record['is_correct'] ? "CORRECT" : "INCORRECT";
      historyText += "- Question: '${record['question']}' -> Result: $result\n";
    }

    final prompt = '''
    You are an adaptive AI tutor. The player's current topic is: "$topic".
    Here is the player's recent quiz history:
    $historyText
    
    Based on this history, generate 3 NEW questions in JSON format:
    - If a previous answer was INCORRECT: generate an easier, fundamental question about that sub-topic.
    - If a previous answer was CORRECT: generate a harder, more complex question.
    
    CRITICAL RULE: All generated content (questions, answers) MUST BE IN HUNGARIAN LANGUAGE.
    
    $_jsonSchema
    ''';

    try {
      onProgress?.call(0.4, 'Adaptív kérdések generálása...');
      final response = await model.generateContent([Content.text(prompt)]);

      onProgress?.call(0.8, 'Válasz formázása...');
      final String responseText = (response.text ?? '[]')
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> jsonList = jsonDecode(responseText);

      List<QuizCard> generatedCards = [];
      for (int i = 0; i < jsonList.length; i++) {
        var cardData = jsonList[i];
        cardData['order'] = i;
        String fakeId = 'ai_adapt_${DateTime.now().millisecondsSinceEpoch}_$i';
        generatedCards.add(QuizCard.fromMap(cardData, fakeId));
      }

      onProgress?.call(1.0, 'Kész!');
      return generatedCards;
    } catch (e) {
      // Vizuális visszajelzés a felhasználónak, a pontos hibakóddal
      onProgress?.call(0.0, 'ADAPTATION ERROR: ${e.toString()}');
      return [];
    }
  }

  /// AI alapú válaszértékelő szabad szöveges kérdésekhez.
  Future<bool> evaluateShortAnswer(
      String question, List<String> expectedAnswers, String userAnswer) async {
    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, // Az értékelésnél legyünk a legszigorúbbak!
      ),
    );

    final prompt = '''
    Question: "$question"
    Expected keywords/correct answers: $expectedAnswers
    Player's submitted answer: "$userAnswer"
    
    Task: Evaluate if the player's answer is semantically correct based on the expected answers. 
    Minor typos, synonyms, and different word conjugations (especially in Hungarian) are acceptable as long as the core meaning is correct.
    
    Return ONLY this exact JSON format: {"is_correct": true} OR {"is_correct": false}
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final String responseText = response.text ?? '{"is_correct": false}';
      final Map<String, dynamic> jsonMap = jsonDecode(responseText);
      return jsonMap['is_correct'] ?? false;
    } catch (e) {
      return expectedAnswers
          .any((ans) => ans.toLowerCase() == userAnswer.toLowerCase().trim());
    }
  }

  /// Meglévő, felhasználó által készített paklik kiterjesztése hasonló stílusú kérdésekkel.
  Future<List<QuizCard>> extendCustomDeck(String deckTitle,
      String deckDescription, List<Map<String, dynamic>> playerHistory,
      {void Function(double progress, String status)? onProgress}) async {
    onProgress?.call(0.1, 'Pakli adatainak beolvasása...');

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // Tényszerűség növelése
      ),
    );

    final prompt = '''
    The player is using a custom educational deck. 
    Deck Title: "$deckTitle" 
    Deck Description: "$deckDescription".
    
    Generate 3 NEW questions that perfectly match the style, topic, and difficulty of this deck.
    
    CRITICAL RULE: All generated content (questions, answers) MUST BE IN HUNGARIAN LANGUAGE.
    
    $_jsonSchema
    ''';

    try {
      onProgress?.call(0.4, 'Új kérdések kitalálása...');
      final response = await model.generateContent([Content.text(prompt)]);

      onProgress?.call(0.8, 'Kártyák mentése...');
      String responseText = (response.text ?? '[]')
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> jsonList = jsonDecode(responseText);

      List<QuizCard> generatedCards = [];
      for (int i = 0; i < jsonList.length; i++) {
        var cardData = jsonList[i];
        cardData['order'] = i;
        String fakeId = 'ai_ext_${DateTime.now().millisecondsSinceEpoch}_$i';
        generatedCards.add(QuizCard.fromMap(cardData, fakeId));
      }

      onProgress?.call(1.0, 'Pakli sikeresen kiterjesztve!');
      return generatedCards;
    } catch (e) {
      // Vizuális visszajelzés a felhasználónak angolul, a pontos hibakóddal
      onProgress?.call(0.0, 'EXTENSION ERROR: ${e.toString()}');
      return [];
    }
  }
}
