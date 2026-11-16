// Ez a szolgáltatás felelős a kártyapaklik és kérdések helyi (offline) tárolásáért.
// A SharedPreferences csomagot használja az adatok perzisztens mentéséhez,
// lehetővé téve a játékot hálózati kapcsolat nélkül is.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';

class LocalDeckService {
  // Kulcsok az adatok azonosításához a helyi tárhelyen
  static const String _decksKey = 'offline_decks'; // A paklik listájának kulcsa
  static const String _cardsKeyPrefix =
      'offline_cards_'; // Előtag a kártyák egyedi kulcsaihoz

  // --- PAKLI ÉS KÁRTYÁK MENTÉSE OFFLINE ---

  /// Elment egy teljes paklit és a hozzá tartozó összes kártyát a készülékre.
  /// [deck]: A menteni kívánt pakli metaadatai.
  /// [cards]: A paklihoz tartozó kérdések listája.
  Future<void> saveDeckOffline(Deck deck, List<QuizCard> cards) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. LÉPÉS: Meglévő offline paklik listájának lekérése
    List<String> savedDecks = prefs.getStringList(_decksKey) ?? [];

    // 2. LÉPÉS: A pakli adatainak előkészítése
    // Mivel az ID fontos az azonosításhoz, de a toMap() nem tartalmazza, manuálisan rögzítjük
    Map<String, dynamic> deckMap = deck.toMap();
    deckMap['id'] = deck.id;

    // 3. LÉPÉS: JSON formátumba alakítás és mentés a listába
    savedDecks.add(jsonEncode(deckMap));
    await prefs.setStringList(_decksKey, savedDecks);

    // 4. LÉPÉS: A paklihoz tartozó kártyák mentése egy egyedi kulcs alá
    // Példa kulcs: 'offline_cards_xyz123'
    List<String> encodedCards =
        cards.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('$_cardsKeyPrefix${deck.id}', encodedCards);
  }

  // --- OFFLINE PAKLIK BETÖLTÉSE ---

  /// Lekéri az összes készüléken tárolt offline paklit.
  /// Visszatérési érték: A helyileg mentett [Deck] objektumok listája.
  Future<List<Deck>> getOfflineDecks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDecksStr = prefs.getStringList(_decksKey) ?? [];

    return savedDecksStr.map((deckStr) {
      final Map<String, dynamic> map = jsonDecode(deckStr);
      // A mentéskor manuálisan hozzáadott ID kinyerése
      final docId = map['id'] ?? 'ismeretlen_id';
      return Deck.fromMap(map, docId);
    }).toList();
  }

  // --- OFFLINE KÁRTYÁK BETÖLTÉSE EGY ADOTT PAKLIHOZ ---

  /// Lekéri egy konkrét paklihoz tartozó összes kártyát a helyi tárhelyről.
  /// [deckId]: A pakli egyedi azonosítója, ami alapján a kártyákat keressük.
  Future<List<QuizCard>> getOfflineCards(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    // A prefix használatával keressük meg a specifikus pakli kártyáit
    List<String> savedCardsStr =
        prefs.getStringList('$_cardsKeyPrefix$deckId') ?? [];

    return savedCardsStr.map((cardStr) {
      final Map<String, dynamic> map = jsonDecode(cardStr);
      final docId = map['id'] ?? 'ismeretlen_card_id';
      // A kártya típusától függően (MultipleChoice, Matching, stb.) példányosítunk
      return QuizCard.fromMap(map, docId);
    }).toList();
  }

  // --- OFFLINE PAKLI TÖRLÉSE ---

  /// Eltávolítja a megadott paklit és az összes hozzá tartozó kártyát a készülékről.
  /// [deckId]: A törlendő pakli azonosítója.
  Future<void> deleteOfflineDeck(String deckId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. LÉPÉS: Pakli eltávolítása a központi listából
    List<String> savedDecksStr = prefs.getStringList(_decksKey) ?? [];
    savedDecksStr.removeWhere((deckStr) {
      final map = jsonDecode(deckStr);
      return map['id'] == deckId;
    });

    // Frissített lista mentése
    await prefs.setStringList(_decksKey, savedDecksStr);

    // 2. LÉPÉS: A paklihoz rendelt összes kártya végleges törlése a tárhelyről
    await prefs.remove('$_cardsKeyPrefix$deckId');
  }
}
