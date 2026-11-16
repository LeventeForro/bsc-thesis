// Ez a szolgáltatás felelős a Firebase Firestore adatbázissal való kommunikációért.
// Kezeli a felhasználói adatokat, a paklik és kártyák életciklusát,
// valamint az XP-számítást és a játékbeli haladás (Story mode) mentését.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart'; // A debugPrint használatához

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. FELHASZNÁLÓ KEZELÉS ---

  /// Új felhasználói profil mentése vagy meglévő frissítése.
  /// [user]: A menteni kívánt UserModel objektum.
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Valós idejű adatfolyamot (Stream) biztosít a felhasználó adataihoz.
  /// Ezzel a UI automatikusan frissül, ha például változik a szint vagy az XP.
  Stream<UserModel> getUserStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .where((snapshot) => snapshot.exists)
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) throw Exception("Felhasználói adatok nem találhatók");
      return UserModel.fromMap(data, snapshot.id);
    });
  }

  // --- 2. PAKLI (DECK) KEZELÉS ---

  /// Létrehoz egy új paklit a központi 'decks' kollekcióban.
  /// Visszatér az automatikusan generált dokumentum azonosítóval.
  Future<String> createDeck(Deck deck) async {
    try {
      DocumentReference docRef =
          await _db.collection('decks').add(deck.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Lekéri az összes publikus paklit a közösségi könyvtár számára.
  /// A találatokat a létrehozás ideje szerint csökkenő sorrendbe rendezi.
  Stream<List<Deck>> getPublicDecks() {
    return _db
        .collection('decks')
        .where('is_public', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Deck.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- 3. KÁRTYA (CARD) KEZELÉS ---

  /// Hozzáad egy kérdéskártyát egy adott pakli 'cards' alkollekciójához.
  /// [increaseCount]: Ha true, a pakli 'card_count' mezőjét is növeli.
  Future<void> addCardToDeck(String deckId, QuizCard card,
      {bool increaseCount = true}) async {
    try {
      await _db
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .add(card.toMap());

      if (increaseCount) {
        await _db.collection('decks').doc(deckId).update({
          'card_count': FieldValue.increment(1),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lekéri egy adott pakli összes kártyáját a mentett sorrendjükben.
  Stream<List<QuizCard>> getCardsForDeck(String deckId) {
    return _db
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuizCard.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- 4. RPG LOGIKA (SZINTLÉPÉS) ---

  /// XP hozzáadása a felhasználóhoz és a szintlépési logika kezelése.
  /// Kiszámolja, hogy az új XP mennyiség eléri-e a következő szint küszöbét.
  /// [uid]: A felhasználó azonosítója.
  /// [xpEarned]: A szerzett tapasztalati pont.
  Future<String> addXpToUser(String uid, int xpEarned) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      final snapshot =
          await userRef.get(const GetOptions(source: Source.serverAndCache));
      if (!snapshot.exists) return "Hiba: Felhasználó nem található";

      final data = snapshot.data() as Map<String, dynamic>;
      int currentXp = data['total_xp'] ?? 0;
      int currentLevel = data['level'] ?? 1;
      int statPoints = data['statPoints'] ?? 0;

      int newXp = currentXp + xpEarned;
      int xpNeededForNextLevel =
          currentLevel * 100; // Skálázási formula (Level * 100)
      bool leveledUp = false;

      // Ciklus a többszörös szintlépés kezelésére (ha pl. egy Boss-ért sok XP jár)
      while (newXp >= xpNeededForNextLevel) {
        newXp -= xpNeededForNextLevel;
        currentLevel++;
        statPoints += 3; // Minden szintlépésnél 3 fejleszthető pont jár
        xpNeededForNextLevel = currentLevel * 100;
        leveledUp = true;
      }

      // Adatok frissítése az adatbázisban
      userRef.update({
        'total_xp': newXp,
        'level': currentLevel,
        'statPoints': statPoints,
      });

      return leveledUp ? "SZINTLÉPÉS! LEVEL $currentLevel" : "+$xpEarned XP.";
    } catch (e) {
      return "Hiba az XP mentésekor.";
    }
  }

  /// Frissíti a pakli metaadatait (cím, leírás, láthatóság).
  Future<void> updateDeck(Deck deck) async {
    await _db.collection('decks').doc(deck.id).update({
      'title': deck.title,
      'description': deck.description,
      'is_public': deck.isPublic,
      'card_count': deck.cardCount,
    });
  }

  /// Törli a paklihoz tartozó összes kártyát.
  /// Hasznos a pakli teljes újraszerkesztésekor.
  Future<void> deleteAllCardsInDeck(String deckId) async {
    final cardsRef = _db.collection('decks').doc(deckId).collection('cards');
    final snapshot = await cardsRef.get();

    for (DocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // --- 5. SZTORI / HALADÁS KEZELÉS ---

  /// Elmenti, hogy a felhasználó sikeresen teljesített egy tananyagot (Subject).
  /// [subjectId]: A teljesített téma egyedi azonosítója.
  Future<void> addCompletedSubject(String uid, String subjectId) async {
    try {
      await _db.collection('users').doc(uid).set({
        'completedSubjects': FieldValue.arrayUnion([subjectId])
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Hiba a pálya mentésekor: $e");
    }
  }

  /// Lekéri a felhasználó által már teljesített témakörök listáját.
  Future<List<String>> getCompletedSubjects(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('completedSubjects')) {
        return List<String>.from(doc.data()!['completedSubjects']);
      }
      return [];
    } catch (e) {
      debugPrint("Hiba a pályák lekérésekor: $e");
      return [];
    }
  }
}
