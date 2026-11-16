// A kártyapaklikat (Deck) reprezentáló adatmodell.
// Ez az osztály fogja össze a kvízkártyák csoportjait, tárolja a metaadatokat (cím, leírás, tulajdonos),
// és kezeli az adatbázis (pl. Firestore) és az alkalmazás közötti adatátalakítást.

class Deck {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final bool isPublic;
  final int cardCount;

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.isPublic,
    this.cardCount = 0,
  });

  /// Átalakítja a Deck objektumot Map formátumba az adatbázisba történő mentéshez.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'is_public': isPublic,
      'card_count': cardCount,
      // A létrehozás pontos idejének rögzítése a rendezhetőség érdekében
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Factory metódus, amely egy Map (például Firestore dokumentum) alapján hoz létre Deck példányt.
  factory Deck.fromMap(Map<String, dynamic> map, String docId) {
    return Deck(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['owner_id'] ?? '',
      isPublic: map['is_public'] ?? false,
      cardCount: map['card_count'] ?? 0,
    );
  }
}
