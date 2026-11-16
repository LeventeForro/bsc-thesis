// Ez a fájl a Könyvtár (LibraryScreen) képernyőért felel.
// Kezeli a publikus paklik böngészését (Firestore), a paklik letöltését offline használatra (LocalDeckService),
// valamint a felhasználó saját paklijainak szinkronizált megjelenítését és törlését.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_screen.dart';
import '../models/deck_model.dart';
import 'create_deck_screen.dart';
import '../services/local_deck_service.dart';
import '../services/firestore_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  /// Az aktuálisan kiválasztott fül indexe (0: Publikus, 1: Letöltött, 2: Saját).
  int _currentTab = 0;

  /// A készüléken tárolt paklik listája a gyors eléréshez.
  List<Deck> _localDecks = [];

  /// A letöltött paklik azonosítóinak halmaza a UI állapotjelzőihez (pl. letöltött ikon).
  Set<String> _localDeckIds = {};

  /// Jelzi, ha éppen folyamatban van egy letöltés, megakadályozva a többszöri kattintást.
  bool _isDownloading = false;

  /// A keresőmező beviteli vezérlője.
  final TextEditingController _searchController = TextEditingController();

  /// Az aktuális keresési kifejezés (kisbetűsítve a könnyebb szűrésért).
  String _searchQuery = "";

  // RPG/Pixel Art vizuális stílus konstansai
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  @override
  void initState() {
    super.initState();
    _loadLocalDecks(); // Helyi adatok betöltése inicializáláskor
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Betölti a készülék belső tárhelyéről az összes offline elérhető paklit.
  Future<void> _loadLocalDecks() async {
    final decks = await LocalDeckService().getOfflineDecks();
    if (mounted) {
      setState(() {
        _localDecks = decks;
        _localDeckIds = decks.map((d) => d.id).toSet();
      });
    }
  }

  /// Letölt egy publikus paklit a hozzá tartozó összes kártyával együtt offline használatra.
  Future<void> _downloadPublicDeck(Deck deck) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      // 1. Kártyák stream lekérése a felhőből
      final cardsStream = FirestoreService().getCardsForDeck(deck.id);
      final cards = await cardsStream.first;

      // 2. Mentés a helyi adatbázisba
      await LocalDeckService().saveDeckOffline(deck, cards);
      await _loadLocalDecks(); // UI frissítése az új adatokkal

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("DECK DOWNLOADED SUCCESSFULLY!"),
              backgroundColor: Colors.greenAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("DOWNLOAD FAILED: $e"),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Pakli törlése: [onlyLocal] esetén csak a telefonról, egyébként a felhőből is eltávolítja.
  Future<void> _deleteDeck(String deckId, {required bool onlyLocal}) async {
    // RPG stílusú megerősítő ablak
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: panelBg,
            shape: Border.all(color: Colors.redAccent, width: 4),
            title: const Text("DELETE DECK",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            content: Text(
                onlyLocal
                    ? "Are you sure you want to remove this downloaded deck from your device?"
                    : "Are you sure you want to destroy this deck completely? This action is permanent.",
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'monospace')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("[ CANCEL ]",
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("[ DELETE ]",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      if (onlyLocal || deckId.startsWith('offline_')) {
        // Csak a helyi tárolóból való törlés
        await LocalDeckService().deleteOfflineDeck(deckId);
      } else {
        // Teljes törlés mindenhonnan (Helyi + Firestore)
        await LocalDeckService().deleteOfflineDeck(deckId);
        await FirebaseFirestore.instance
            .collection('decks')
            .doc(deckId)
            .delete();
      }

      await _loadLocalDecks(); // Lista frissítése
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("DECK REMOVED!"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ERROR: $e"), backgroundColor: Colors.red));
      }
    }
  }

  /// Összeállítja a paklik listáját a választott fül (_currentTab) és a forrás (Firestore/Local) alapján.
  Widget _buildDeckList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String myUid = currentUser?.uid ?? '';

    // --- 0. PUBLIKUS FÜL: Minden közösségi pakli a felhőből ---
    if (_currentTab == 0) {
      final query = FirebaseFirestore.instance
          .collection('decks')
          .where('is_public', isEqualTo: true);
      return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorText();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoader();
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmptyText("NO COMMUNITY DECKS FOUND");

          var decks = docs
              .map((doc) =>
                  Deck.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Keresési szűrés a publikus paklik között
          if (_searchQuery.isNotEmpty) {
            decks = decks
                .where((d) => d.title.toLowerCase().contains(_searchQuery))
                .toList();
            if (decks.isEmpty) {
              return _buildEmptyText("NO MATCHING DECKS FOUND");
            }
          }

          return _buildListView(decks,
              isDownloadedTab: false, isMyDecksTab: false);
        },
      );
    }
    // --- 1. LETÖLTÖTT FÜL: Helyi tárolóban lévő, másoktól származó paklik ---
    else if (_currentTab == 1) {
      var downloadedDecks = _localDecks
          .where((d) => d.ownerId != myUid && d.ownerId != 'local_user')
          .toList();

      if (downloadedDecks.isEmpty) {
        return _buildEmptyText("NO DOWNLOADED DECKS");
      }

      // Keresési szűrés a letöltött paklik között
      if (_searchQuery.isNotEmpty) {
        downloadedDecks = downloadedDecks
            .where((d) => d.title.toLowerCase().contains(_searchQuery))
            .toList();
        if (downloadedDecks.isEmpty) {
          return _buildEmptyText("NO MATCHING DECKS FOUND");
        }
      }

      return _buildListView(downloadedDecks,
          isDownloadedTab: true, isMyDecksTab: false);
    }
    // --- 2. SAJÁT PAKLIK FÜL: Online és Offline saját paklik összefésülése ---
    else {
      final query = FirebaseFirestore.instance
          .collection('decks')
          .where('owner_id', isEqualTo: myUid);
      return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, firestoreSnapshot) {
          if (firestoreSnapshot.hasError) return _buildErrorText();

          List<Deck> onlineDecks = [];
          if (firestoreSnapshot.hasData) {
            onlineDecks = firestoreSnapshot.data!.docs
                .map((doc) =>
                    Deck.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();
          }

          List<Deck> localMyDecks = _localDecks
              .where((d) => d.ownerId == myUid || d.ownerId == 'local_user')
              .toList();

          // Unifikálás: Az azonos ID-jú paklik közül az online verziót részesítjük előnyben
          final Map<String, Deck> mergedDecks = {};
          for (var deck in localMyDecks) {
            mergedDecks[deck.id] = deck;
          }
          for (var deck in onlineDecks) {
            mergedDecks[deck.id] = deck;
          }

          var allMyDecks = mergedDecks.values.toList();

          if (firestoreSnapshot.connectionState == ConnectionState.waiting &&
              allMyDecks.isEmpty) return _buildLoader();
          if (allMyDecks.isEmpty) {
            return _buildEmptyText("YOU HAVE NO DECKS YET");
          }

          // Keresési szűrés a saját paklik között
          if (_searchQuery.isNotEmpty) {
            allMyDecks = allMyDecks
                .where((d) => d.title.toLowerCase().contains(_searchQuery))
                .toList();
            if (allMyDecks.isEmpty) {
              return _buildEmptyText("NO MATCHING DECKS FOUND");
            }
          }

          return _buildListView(allMyDecks,
              isDownloadedTab: false, isMyDecksTab: true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A GestureDetector biztosítja, hogy a képernyő bármely üres pontjára
    // kattintva a keresősávról lekerüljön a fókusz, és eltűnjön a billentyűzet.
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: bgDark,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 16),
                child: Text("DECK LIBRARY",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
              ),

              // KERESŐSÁV MEGJELENÍTÉSE
              _buildSearchBar(),

              // Tab vezérlő sor
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildTabButton("PUBLIC", 0),
                    const SizedBox(width: 8),
                    _buildTabButton("DOWNLOADS", 1),
                    const SizedBox(width: 8),
                    _buildTabButton("MY DECKS", 2),
                  ],
                ),
              ),
              const Divider(
                  color: borderSide, thickness: 2, indent: 16, endIndent: 16),
              Expanded(child: _buildDeckList()),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI SEGÉDELEMEK ---

  // KERESŐSÁV WIDGET
  /// Felépíti a szöveges keresőmezőt, ami valós időben frissíti a lista tartalmát.
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: "SEARCH DECKS...",
          hintStyle:
              const TextStyle(color: Colors.white24, fontFamily: 'monospace'),
          prefixIcon: const Icon(Icons.search, color: accentGold),
          // Törlés gomb (X) csak akkor jelenik meg, ha van beírt szöveg
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: true,
          fillColor: panelBg,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: borderSide, width: 2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: accentGold, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() =>
      const Center(child: CircularProgressIndicator(color: accentGold));

  Widget _buildErrorText() => const Center(
      child: Text("ERROR LOADING DATA",
          style: TextStyle(color: Colors.redAccent)));

  Widget _buildEmptyText(String text) => Center(
      child: Text(text,
          style: const TextStyle(
              color: Colors.white24, fontSize: 14, fontFamily: 'monospace')));

  /// Létrehoz egy stílusos tab-gombot a fenti választóhoz.
  Widget _buildTabButton(String label, int index) {
    bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentGold : Colors.black26,
            border: Border.all(
                color: isSelected ? accentGold : borderSide, width: 2),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
        ),
      ),
    );
  }

  /// Megjeleníti a paklikat tartalmazó listát a harci stílusú kártyákkal.
  Widget _buildListView(List<Deck> decks,
      {required bool isDownloadedTab, required bool isMyDecksTab}) {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        final isOfflineOnly =
            deck.id.startsWith('offline_'); // Csak helyben létező pakli
        final isAlreadyDownloaded =
            _localDeckIds.contains(deck.id); // Már le van töltve a felhőből
        final isMyDeck = deck.ownerId == myUid || deck.ownerId == 'local_user';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: panelBg,
              border: Border.all(
                  color: isOfflineOnly ? Colors.orangeAccent : borderSide,
                  width: 2)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                if (isOfflineOnly)
                  const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.wifi_off,
                          color: Colors.orangeAccent, size: 16)),
                Expanded(
                    child: Text(deck.title.toUpperCase(),
                        style: TextStyle(
                            color: isOfflineOnly
                                ? Colors.orangeAccent
                                : accentGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold))),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(deck.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text("CARDS: ${deck.cardCount}",
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace')),
              ],
            ),
            trailing: _buildTrailingActions(deck, isDownloadedTab, isMyDecksTab,
                isAlreadyDownloaded, isMyDeck),
            onTap: () async {
              // Pakli elindítása a harci képernyőn
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          GameScreen(deck: deck, title: deck.title)));
              if (mounted) {
                _loadLocalDecks(); // Helyi állapot frissítése visszalépéskor
              }
            },
          ),
        );
      },
    );
  }

  /// Összeállítja a sor végi akciógombokat (Letöltés, Szerkesztés, Törlés) a kontextus alapján.
  Widget _buildTrailingActions(Deck deck, bool isDownloadedTab,
      bool isMyDecksTab, bool isAlreadyDownloaded, bool isMyDeck) {
    List<Widget> actions = [];

    if (_currentTab == 0) {
      // PUBLIC TAB
      if (isMyDeck) {
        actions.add(
            const Icon(Icons.play_arrow_outlined, color: accentGold, size: 32));
      } else if (isAlreadyDownloaded) {
        actions.add(
            const Icon(Icons.offline_pin, color: Colors.greenAccent, size: 28));
      } else {
        actions.add(_isDownloading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Colors.blueAccent, strokeWidth: 2))
            : _buildActionButton(Icons.download, Colors.blueAccent,
                () => _downloadPublicDeck(deck)));
      }
    } else if (_currentTab == 1) {
      // DOWNLOADED TAB
      actions.add(
          const Icon(Icons.play_arrow_outlined, color: accentGold, size: 28));
      actions.add(const SizedBox(width: 16));
      actions.add(_buildActionButton(Icons.delete_outline, Colors.orangeAccent,
          () => _deleteDeck(deck.id, onlyLocal: true)));
    } else if (_currentTab == 2) {
      // MY DECKS TAB
      actions.add(_buildActionButton(Icons.edit, Colors.blueAccent, () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreateDeckScreen(existingDeck: deck)));
        if (mounted) _loadLocalDecks();
      }));
      actions.add(const SizedBox(width: 8));
      actions.add(_buildActionButton(Icons.delete, Colors.redAccent,
          () => _deleteDeck(deck.id, onlyLocal: false)));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  /// Segédfüggvény egyedi stílusú akciógombok létrehozásához a listaelemekben.
  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            color: Colors.black26),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
