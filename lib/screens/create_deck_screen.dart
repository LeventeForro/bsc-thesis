// Ez a fájl a kártyapaklik létrehozásáért és szerkesztéséért felelős képernyőt (CreateDeckScreen) valósítja meg.
// Kezeli a hálózati kapcsolat állapotát, lehetővé teszi a paklik Online (Firestore) vagy Offline (helyi adatbázis) mentését,
// valamint biztosítja a paklihoz tartozó kérdéskártyák kezelését (hozzáadás, szerkesztés, törlés).

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_deck_service.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'card_editor_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateDeckScreen extends StatefulWidget {
  /// Meghatározza, hogy új paklit hozunk létre (null) vagy egy létezőt szerkesztünk.
  final Deck? existingDeck;

  const CreateDeckScreen({super.key, this.existingDeck});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isPublic =
      true; // Meghatározza, hogy a pakli látható-e mások számára (csak online módban)
  bool _isSaving = false; // Mentési folyamat folyamatban van-e (töltésjelzőhöz)
  bool _isLoadingCards =
      false; // Kártyák betöltése folyamatban van-e (szerkesztés módban)
  bool _hasInternet = true; // Tárolja, hogy van-e aktív internetkapcsolat

  /// A paklihoz aktuálisan hozzárendelt kérdéskártyák listája.
  List<QuizCard> _addedCards = [];

  // RPG vizuális stílus színpaletta konstansok
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  @override
  void initState() {
    super.initState();
    _checkNetwork(); // Indításkor ellenőrizzük a kapcsolatot

    // Ha szerkesztés módban vagyunk, az űrlapot feltöltjük a meglévő adatokkal
    if (widget.existingDeck != null) {
      _titleController.text = widget.existingDeck!.title;
      _descController.text = widget.existingDeck!.description;
      _isPublic = widget.existingDeck!.isPublic;
      _loadExistingCards();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();

    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Megvizsgálja az aktuális hálózati állapotot és frissíti a [_hasInternet] változót.
  Future<void> _checkNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _hasInternet = !connectivityResult.toString().contains('none');
          if (!_hasInternet) {
            _isPublic = false; // Internet nélkül kényszerített privát mód
          }
        });
      }
    } catch (e) {
      // Hiba esetén alapértelmezetten true-t feltételezünk a folyamatosság érdekében
      if (mounted) setState(() => _hasInternet = true);
    }
  }

  /// Szerkesztés esetén lekéri a kártyákat a megfelelő forrásból (Firestore vagy helyi tároló).
  Future<void> _loadExistingCards() async {
    setState(() => _isLoadingCards = true);
    try {
      if (widget.existingDeck!.id.startsWith('offline_')) {
        // --- OFFLINE KÁRTYÁK BETÖLTÉSE ---
        final localCards =
            await LocalDeckService().getOfflineCards(widget.existingDeck!.id);
        setState(() {
          _addedCards = localCards;
        });
      } else {
        // --- ONLINE KÁRTYÁK BETÖLTÉSE (Firestore) ---
        final firestore = FirestoreService();
        final cardsStream = firestore.getCardsForDeck(widget.existingDeck!.id);
        final cardsList = await cardsStream.first;

        setState(() {
          _addedCards = cardsList;
        });
      }
    } catch (e) {
      debugPrint("Hiba a kártyák betöltésekor: $e");
    } finally {
      setState(() => _isLoadingCards = false);
    }
  }

  /// A pakli és kártyáinak mentését végző főfüggvény.
  /// Kezeli az online szinkronizációt vagy az offline mentést a kapcsolat állapotától függően.
  void _saveDeck() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FORGE FAILED: ADD AT LEAST ONE CARD!")),
      );
      return;
    }

    // Biztonsági ellenőrzés közvetlenül mentés előtt
    bool isOnline = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      isOnline = !connectivityResult.toString().contains('none');
    } catch (e) {
      isOnline = true;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthService().currentUser;

      if (isOnline) {
        // ============================================
        // 1. ONLINE MENTÉS (FIREBASE)
        // ============================================
        if (user == null) throw Exception("NO USER LOGGED IN");
        final firestore = FirestoreService();
        String deckId;

        if (widget.existingDeck == null ||
            widget.existingDeck!.id.startsWith('offline_')) {
          // Új online pakli létrehozása (vagy offline-ból való feltöltés)
          final newDeck = Deck(
            id: '',
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            ownerId: user.uid,
            isPublic: _isPublic,
            cardCount: _addedCards.length,
          );
          deckId = await firestore.createDeck(newDeck);

          // Ha sikeres a feltöltés, töröljük a régi offline példányt
          if (widget.existingDeck?.id.startsWith('offline_') ?? false) {
            await LocalDeckService().deleteOfflineDeck(widget.existingDeck!.id);
          }
        } else {
          // Meglévő online pakli adatainak frissítése
          deckId = widget.existingDeck!.id;
          final updatedDeck = Deck(
            id: deckId,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            ownerId: user.uid,
            isPublic: _isPublic,
            cardCount: _addedCards.length,
          );

          await firestore.updateDeck(updatedDeck);
          await firestore.deleteAllCardsInDeck(
              deckId); // Kártyák újraírása a sorrend miatt
        }

        // Kártyák mentése a felhőbe
        for (int i = 0; i < _addedCards.length; i++) {
          final card = _addedCards[i];
          card.order = i;
          await firestore.addCardToDeck(deckId, card);
        }

        // Helyi másolat frissítése/szinkronizálása
        final localSyncDeck = Deck(
          id: deckId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          ownerId: user.uid,
          isPublic: _isPublic,
          cardCount: _addedCards.length,
        );
        await LocalDeckService().saveDeckOffline(localSyncDeck, _addedCards);

        await FirebaseFirestore.instance
            .collection('decks')
            .doc(deckId)
            .update({
          'card_count': _addedCards.length,
        });
      } else {
        // ============================================
        // 2. OFFLINE MENTÉS (HELYI TÁRHELY)
        // ============================================
        String deckId = widget.existingDeck?.id ??
            'offline_${DateTime.now().millisecondsSinceEpoch}';

        final localDeck = Deck(
          id: deckId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          ownerId: user?.uid ?? 'local_user',
          isPublic: false,
          cardCount: _addedCards.length,
        );

        // Kártyák sorrendezése mentés előtt
        for (int i = 0; i < _addedCards.length; i++) {
          _addedCards[i].order = i;
        }

        await LocalDeckService().saveDeckOffline(localDeck, _addedCards);
      }

      // Siker visszajelzés küldése a felhasználónak
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!isOnline
                ? "SAVED OFFLINE (No Connection)"
                : (widget.existingDeck == null
                    ? "NEW DECK FORGED!"
                    : "DECK REINFORCED!")),
            backgroundColor:
                !isOnline ? Colors.orangeAccent : Colors.greenAccent,
          ),
        );

        if (widget.existingDeck == null) {
          // Új pakli esetén űrlap ürítése
          setState(() {
            _titleController.clear();
            _descController.clear();
            _addedCards.clear();
            _isPublic = _hasInternet;
          });
        } else {
          // Szerkesztés után visszalépés
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("ERROR: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Megnyitja a kártyaszerkesztőt új kártya létrehozásához.
  void _openCardEditor() async {
    final QuizCard? newCard = await showDialog<QuizCard>(
      context: context,
      builder: (ctx) => const CardEditorDialog(),
    );

    if (newCard != null) {
      setState(() {
        _addedCards.add(newCard);
      });
    }
  }

  /// Megnyitja a kártyaszerkesztőt egy már létező kártya módosításához.
  void _editCard(int index) async {
    final QuizCard? editedCard = await showDialog<QuizCard>(
      context: context,
      builder: (ctx) => CardEditorDialog(existingCard: _addedCards[index]),
    );

    if (editedCard != null) {
      setState(() {
        _addedCards[index] = editedCard;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // A GestureDetector biztosítja, hogy a képernyő bármely üres pontjára
    // kattintva lekerüljön a fókusz a beviteli mezőkről, és eltűnjön a billentyűzet.
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            widget.existingDeck == null ? "DECK FORGE" : "EDIT QUEST",
            style:
                const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          backgroundColor: panelBg,
          foregroundColor: accentGold,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(2),
            child: Divider(color: borderSide, height: 2, thickness: 2),
          ),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: accentGold, strokeWidth: 2)),
                ),
              )
            else
              IconButton(
                  icon: const Icon(Icons.check_box, color: Colors.greenAccent),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _saveDeck();
                  })
          ],
        ),
        body: _isLoadingCards
            ? const Center(child: CircularProgressIndicator(color: accentGold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("QUEST DETAILS"),
                      const SizedBox(height: 12),
                      _buildPixelTextField(
                        controller: _titleController,
                        label: "DECK TITLE",
                        validator: (val) =>
                            val!.isEmpty ? "TITLE REQUIRED" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildPixelTextField(
                        controller: _descController,
                        label: "DESCRIPTION",
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildPixelSwitch(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: borderSide, thickness: 2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("CARDS (${_addedCards.length})"),
                          _buildCraftButton(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_addedCards.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _addedCards.length,
                          itemBuilder: (context, index) {
                            final card = _addedCards[index];
                            return _buildCardItem(card, index);
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- STÍLUS ÉS UI KOMPONENSEK ---

  /// Szekciófeliratok stílusozott megjelenítése.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5),
    );
  }

  /// RPG stílusú, szögletes beviteli mező létrehozása.
  Widget _buildPixelTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            contentPadding: EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderSide, width: 2),
                borderRadius: BorderRadius.zero),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accentGold, width: 2),
                borderRadius: BorderRadius.zero),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.redAccent, width: 2),
                borderRadius: BorderRadius.zero),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.redAccent, width: 2),
                borderRadius: BorderRadius.zero),
          ),
        ),
      ],
    );
  }

  /// Kapcsoló a publikus/privát állapot váltásához, hálózati figyelmeztetéssel.
  Widget _buildPixelSwitch() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: borderSide, width: 2), color: panelBg),
      child: SwitchListTile(
        title: const Text("PUBLIC DECK",
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        subtitle: !_hasInternet
            ? const Text("NO INTERNET. LOCAL SAVE ONLY.",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold))
            : const Text("VISIBLE IN COMMUNITY LIBRARY",
                style: TextStyle(color: Colors.white38, fontSize: 10)),
        value: _hasInternet ? _isPublic : false,
        activeColor: accentGold,
        activeTrackColor: accentGold.withOpacity(0.3),
        inactiveThumbColor: Colors.white24,
        inactiveTrackColor: Colors.black26,
        onChanged:
            _hasInternet ? (val) => setState(() => _isPublic = val) : null,
      ),
    );
  }

  /// Kártya-létrehozást indító gomb.
  Widget _buildCraftButton() {
    return MaterialButton(
      onPressed: _openCardEditor,
      color: Colors.green.withOpacity(0.2),
      elevation: 0,
      shape: const Border(
          top: BorderSide(color: Colors.greenAccent),
          bottom: BorderSide(color: Colors.greenAccent),
          left: BorderSide(color: Colors.greenAccent),
          right: BorderSide(color: Colors.greenAccent)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, color: Colors.greenAccent, size: 16),
          SizedBox(width: 4),
          Text("CRAFT CARD",
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Üres kártyalista esetén megjelenő információs ablak.
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: borderSide, width: 2)),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white12, size: 40),
          SizedBox(height: 12),
          Text("INVENTORY EMPTY",
              style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          Text("CLICK 'CRAFT CARD' TO START",
              style: TextStyle(
                  color: Colors.white10,
                  fontSize: 10,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  /// Egyedi lista elem megjelenítése egy hozzáadott kártyához.
  Widget _buildCardItem(QuizCard card, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: panelBg, border: Border.all(color: borderSide, width: 2)),
      child: ListTile(
        onTap: () => _editCard(index),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              border: Border.all(color: accentGold), color: Colors.black26),
          child: Center(
              child: Text("${index + 1}",
                  style: const TextStyle(
                      color: accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ),
        title: Text(card.question.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(_getCardTypeLabel(card.type).toUpperCase(),
            style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 9,
                fontFamily: 'monospace')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.white24, size: 18),
                onPressed: () => _editCard(index)),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                onPressed: () => setState(() => _addedCards.removeAt(index))),
          ],
        ),
      ),
    );
  }

  /// Kártyatípus azonosítóhoz tartozó olvasható címke visszaadása.
  String _getCardTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'short_answer':
        return 'Short Answer';
      case 'matching':
        return 'Matching';
      case 'multiple_select':
        return 'Multiple Select';
      default:
        return type;
    }
  }
}
