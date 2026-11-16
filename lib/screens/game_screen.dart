// Ez a fájl felelős a tényleges játékmenet képernyőjéért (GameScreen).
// Kezeli a kártyák betöltését, a harci HUD-ot, az RPG statisztikák szinkronizálását,
// az ellenségek generálását és a kvíz kérdések-válaszok ciklusát.

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame/game.dart';
import 'package:szakdolgozat/game/enemies/enemy_base.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../services/attribute_service.dart';
import '../game/battle_game.dart';
import '../game/game_state.dart';
import '../game/quiz_controller.dart';
import '../widgets/combo_panel.dart';
import '../widgets/question_widgets.dart';
import '../widgets/shield_indicator.dart';
import '../widgets/dodge_indicator.dart';
import '../widgets/dark_pact_indicator.dart';
import '../widgets/game_dialogs.dart';
import '../game/combat_controller.dart';
import '../screens/match_history_screen.dart';
import '../game/enemies/enemy_registry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_deck_service.dart';
import '../widgets/finsih_him.dart';
import '../widgets/enemy_dialogue_overlay.dart';

class GameScreen extends StatelessWidget {
  final Deck? deck; // A játszani kívánt kártyapakli (opcionális)
  final List<QuizCard>?
      predefinedCards; // Előre betöltött kártyák (pl. sztori módnál)
  final String title; // A játékülés címe (pakli neve)
  final int maxQuestionsLimit; // Hány kérdés legyen egy menetben
  final String? fixedEnemyId; // Meghatározott ellenség (Boss fight-hoz)
  final String? storySubjectId; // Tárgy azonosító a leckekönyvhöz
  final String? enemyQuote; // Ellenfél szövege
  final int? storyXpReward; // XP jutalom a Story módhoz
  final Map<String, int>?
      fixedEnemyStats; // Ellenfél statisztikája story módhoz

  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color accentGold = Color(0xFFFFD700);

  const GameScreen({
    super.key,
    this.deck,
    this.predefinedCards,
    required this.title,
    this.maxQuestionsLimit = 10,
    this.fixedEnemyId,
    this.storySubjectId,
    this.enemyQuote,
    this.storyXpReward,
    this.fixedEnemyStats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // A fő játékmenet megjelenítése
          Positioned.fill(child: _buildGameContent()),

          // Globális kilépés gomb (lebegő stílusban
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kiválasztja a megfelelő adatforrást a játék indításához.
  Widget _buildGameContent() {
    if (predefinedCards != null && predefinedCards!.isNotEmpty) {
      return GamePlayArea(
        cards: predefinedCards!,
        deckTitle: title,
        isAiDeck: true,
        maxQuestionsLimit: maxQuestionsLimit,
        storySubjectId: storySubjectId,
        enemyQuote: enemyQuote,
        fixedEnemyId: fixedEnemyId,
        storyXpReward: storyXpReward,
        fixedEnemyStats: fixedEnemyStats,
      );
    }
    if (deck != null) {
      return FutureBuilder<List<QuizCard>>(
        future: _fetchCardsSmartly(deck!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: accentGold));
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('EMPTY DECK OR NO INTERNET.',
                  style: TextStyle(
                      color: Colors.white54, fontFamily: 'monospace')),
            );
          }
          return GamePlayArea(
            cards: snapshot.data!,
            deckTitle: title,
            isAiDeck: false,
            maxQuestionsLimit: maxQuestionsLimit,
            fixedEnemyId: fixedEnemyId,
            storySubjectId: storySubjectId,
            enemyQuote: enemyQuote,
          );
        },
      );
    }
    return const Center(
      child: Text('ERROR: NO CARDS LOADED.',
          style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
    );
  }

  /// Okos kártyaletöltés: prioritás szerint próbálkozik a Firestore-al,
  /// hálózati hiba vagy lassulás esetén a helyi mentéshez (LocalDeckService) nyúl.
  Future<List<QuizCard>> _fetchCardsSmartly(String deckId) async {
    try {
      if (deckId.startsWith('offline_')) {
        return await LocalDeckService().getOfflineCards(deckId);
      }

      bool isOnline = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        isOnline = !connectivityResult.toString().contains('none');
      } catch (_) {
        isOnline = false;
      }

      if (isOnline) {
        try {
          final stream = FirestoreService().getCardsForDeck(deckId);
          // 3 másodperces időkorlát a felhő alapú válaszra
          final onlineCards =
              await stream.first.timeout(const Duration(seconds: 3));
          if (onlineCards.isNotEmpty) return onlineCards;
        } catch (e) {
          debugPrint("Timeout v. hiba: $e");
        }
      }

      return await LocalDeckService().getOfflineCards(deckId);
    } catch (e) {
      debugPrint("Kritikus hiba: $e");
      return [];
    }
  }
}

class GamePlayArea extends StatefulWidget {
  final List<QuizCard> cards;
  final String deckTitle;
  final bool isAiDeck;
  final int maxQuestionsLimit;
  final String? fixedEnemyId;
  final String? storySubjectId;
  final String? enemyQuote;
  final int? storyXpReward;
  final Map<String, int>? fixedEnemyStats;

  const GamePlayArea({
    super.key,
    required this.cards,
    required this.deckTitle,
    this.isAiDeck = false,
    this.maxQuestionsLimit = 10,
    this.fixedEnemyId,
    this.storySubjectId,
    this.enemyQuote,
    this.storyXpReward,
    this.fixedEnemyStats,
  });

  @override
  State<GamePlayArea> createState() => _GamePlayAreaState();
}

class _GamePlayAreaState extends State<GamePlayArea> {
  // Belső állapotkezelők a kvízhez
  int _currentQuestionIndex = 0;
  List<QuizCard> _gameQueue = [];
  bool _isQuestionsFinished = false;
  bool _isChecking = false; // Animáció/Ellenőrzés alatt áll-e a UI
  bool _isFetchingMoreCards = false; // Háttér AI generálás folyamatban
  final List<Map<String, dynamic>> _matchHistory = []; // Statisztikához
  bool? _lastAnswerCorrect; // Utolsó válasz helyessége a visszajelzéshez

  // AI kiterjesztés (blokkoló) UI állapotai
  bool _isExtendingDeck = false;
  double _aiLoadingProgress = 0.0;
  String _aiLoadingStatus = '';

  // Beviteli vezérlők
  final List<int> _selectedIndices = [];
  final TextEditingController _textController = TextEditingController();
  String? _selectedLeftItem;
  final Map<String, String> _solvedPairs = {};
  List<String> _rightSideItems = [];

  // Játékmotor referenciák
  bool _isGameReady = false;
  late BattleGame _battleGame;
  late GameStateManager _gsm;
  late QuizController _quizController;

  static const Color borderSide = Color(0xFF3E3E63);
  static const Color accentGold = Color(0xFFFFD700);

  bool _showDialogue = false;

  @override
  void initState() {
    super.initState();
    _gameQueue = List.from(widget.cards);
    _fetchPlayerData(); // Karakter adatok betöltése a kezdéshez
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// RPG adatok lekérése a Firestore-ból és a harci motor (GSM) felállítása.
  Future<void> _fetchPlayerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final level = data['level'] ?? 1;
      final cls = data['characterClass'] ?? 'knight';
      final maxHp = AttributeService.getMaxHealth(cls, data['vitality'] ?? 1);

      // Ellenség sorsolása vagy fixálása
      final EnemyBase enemy = widget.fixedEnemyId != null
          ? EnemyRegistry.getEnemyById(
              widget.fixedEnemyId!,
              playerLevel: level,
              fixedStats: widget.fixedEnemyStats,
            )
          : EnemyRegistry.getRandomEnemy(level);

      final battleGame = BattleGame(
        playerMaxHealth: maxHp,
        enemyMaxHealth: enemy.maxHealth,
        playerClass: cls,
        initialEnemyConfig: enemy.entityConfig,
      );

      final combatController = CombatController(
        playerMaxHealth: maxHp,
        playerHealth: maxHp,
        enemyHealth: enemy.maxHealth,
        currentEnemy: enemy,
        playerClass: cls,
        playerStats: {
          'str': data['strength'] ?? 1,
          'agi': data['agility'] ?? 1,
          'intel': data['intellect'] ?? 1,
          'vit': data['vitality'] ?? 1,
          'luck': data['luck'] ?? 1,
          'lvl': level
        },
      );

      // A GameStateManager összeköti a logikát a UI-val
      final gsm = GameStateManager(
        battleGame: battleGame,
        combatController: combatController,
        setState: (fn) {
          if (mounted) setState(fn);
        },
        onGameEnd: _showEndGameDialog,
        onNextQuestion: _nextQuestion,
        playerHealth: maxHp,
        enemyHealth: enemy.maxHealth,
        defeatedMonsters: 0,
        currentCombo: 0,
        characterClass: cls,
        playerLevel: level,
        maxHealth: maxHp,
        isStoryMode: widget.storySubjectId != null,
      );

      setState(() {
        _battleGame = battleGame;
        _gsm = gsm;
        _quizController = QuizController(onResult: _showFeedback);
        _isGameReady = true;

        if (widget.enemyQuote != null && widget.enemyQuote!.isNotEmpty) {
          _showDialogue = true;
        }
      });
    } catch (e) {
      debugPrint("Data error: $e");
    }
  }

  /// Kezeli a választ: elmenti a történelmet és meghívja a harci visszacsatolást.
  void _showFeedback(bool isCorrect) {
    if (_isChecking || _gsm.isAttacking) return;

    final currentCard = _gameQueue[_currentQuestionIndex];
    _matchHistory.add({
      'question': currentCard.question,
      'is_correct': isCorrect,
      'card': currentCard,
    });

    _maybeFetchMoreCards();

    setState(() {
      _isChecking = true;
      _lastAnswerCorrect = isCorrect;
      _gsm.showFeedback(isCorrect,
          mushroomEnemy: _gsm.combatController.currentEnemy);
    });
  }

  /// Következő kérdésre lépés, vagy a harci fázis lezárása, ha elfogytak a kérdések.
  void _nextQuestion() {
    if (!mounted) return;
    if (_currentQuestionIndex >= _gameQueue.length - 1) {
      if (_gsm.currentCombo > 0) {
        setState(() {
          _isChecking = false;
          _isQuestionsFinished = true;
          _gsm.isQuestionsFinished = true;
        });
      } else {
        // Megnézzük, hogy Sztori módban vagyunk-e
        bool isStoryMode = widget.storySubjectId != null;

        if (isStoryMode) {
          _showEndGameDialog(false);
        } else {
          _showEndGameDialog(true);
        }
      }
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedIndices.clear();
        _textController.clear();
        _selectedLeftItem = null;
        _solvedPairs.clear();
        _rightSideItems.clear();
        _isChecking = false;
        _lastAnswerCorrect = null;
      });
    }
  }

  /// Adaptív tanulás: Ha a felhasználó a végére ér, az AI-Service-től új,
  /// a hibáihoz igazított kérdéseket kér a háttérben.
  void _maybeFetchMoreCards() {
    if (!widget.isAiDeck) return;
    final remaining = widget.maxQuestionsLimit - _gameQueue.length;
    if ((_gameQueue.length - _currentQuestionIndex) <= 3 &&
        !_isFetchingMoreCards &&
        remaining > 0) {
      _fetchMoreAdaptiveQuestions(remaining);
    }
  }

  Future<void> _fetchMoreAdaptiveQuestions(int max) async {
    if (_isFetchingMoreCards) return;
    setState(() => _isFetchingMoreCards = true);
    final newCards = await AiService().generateAdaptiveQuestions(
        widget.deckTitle.replaceAll("AI Pakli: ", ""), _matchHistory);
    if (!mounted) return;
    setState(() {
      final toAdd = newCards.length > max ? newCards.sublist(0, max) : newCards;
      _gameQueue.addAll(toAdd);
      _isFetchingMoreCards = false;
    });
  }

  /// Befejezés kezelése: XP jóváírás, szintlépés és tárgyteljesítés mentése.
  Future<void> _showEndGameDialog(bool win) async {
    final user = FirebaseAuth.instance.currentUser;
    int xp = 0;

    // Ha Sztori Módban vagyunk és nyert a játékos:
    if (widget.storySubjectId != null && win) {
      // Megkapja a tárgyhoz előre beállított XP-t
      xp = widget.storyXpReward ?? 50;
    } else {
      // Custom módban kevés XP
      xp = (_gsm.defeatedMonsters * 10) + (win ? 20 : 0);
    }

    if (user != null) {
      if (xp > 0) await FirestoreService().addXpToUser(user.uid, xp);
      if (win && widget.storySubjectId != null) {
        await FirestoreService()
            .addCompletedSubject(user.uid, widget.storySubjectId!);
      }
    }

    if (!mounted) return;
    GameDialogs.showEndGame(
      context: context,
      isVictory: win,
      defeatedMonsters: _gsm.defeatedMonsters,
      earnedXp: xp,
      isAiDeck: widget.isAiDeck,
      onSaveAiDeck: () => _saveAiDeck(),
      onGoBack: () async {
        Navigator.pop(context);
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MatchHistoryScreen(history: _matchHistory)));
        if (mounted) Navigator.pop(context);
      },
      onContinueAi: win
          ? () {
              Navigator.pop(context);
              _continueWithAi();
            }
          : null,
    );
  }

  Future<void> _saveAiDeck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final d = Deck(
          id: '',
          title: widget.deckTitle,
          description: 'AI generated endless quiz.',
          ownerId: user.uid,
          isPublic: false,
          cardCount: 0);
      final id = await FirestoreService().createDeck(d);
      for (final c in widget.cards) {
        await FirestoreService().addCardToDeck(id, c);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("SAVED TO LIBRARY!"),
            backgroundColor: Colors.greenAccent));
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  /// Új AI kártyák legenerálása és a folyamat jelzése a játékos felé.
  Future<void> _continueWithAi() async {
    setState(() {
      _isExtendingDeck = true;
      _isFetchingMoreCards = true;
      _isQuestionsFinished = false;
      _aiLoadingProgress = 0.0;
      _aiLoadingStatus = 'Mágikus tekercsek előkészítése...';
    });

    try {
      final newCards = await AiService()
          .extendCustomDeck(widget.deckTitle, "Extension", _matchHistory,
              onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _aiLoadingProgress = progress;
            _aiLoadingStatus = status;
          });
        }
      });

      if (!mounted) return;

      setState(() {
        _isExtendingDeck = false;
        _isFetchingMoreCards = false;
      });

      if (newCards.isNotEmpty) {
        // Siekres generálás
        _gameQueue.addAll(newCards);
        _nextQuestion();
        final newEnemy = EnemyRegistry.getRandomEnemy(_gsm.playerLevel);
        _gsm.enemyHealth = newEnemy.maxHealth;
        _gsm.combatController.currentEnemy = newEnemy;
        _battleGame.spawnNewEnemyConfig(
            newEnemy.entityConfig, newEnemy.maxHealth);
      } else {
        // sikeres generálás
        _showEndGameDialog(true); // End Game ablak elinditása
        _showTopLevelErrorSnackBar(); // Hiba legfelső rétegben
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtendingDeck = false;
          _isFetchingMoreCards = false;
        });
        _showEndGameDialog(true);
        _showTopLevelErrorSnackBar();
      }
    }
  }

  /// Segédfüggvény: Garantáltan legfelső rétegű (Overlay) hibaüzenet.
  void _showTopLevelErrorSnackBar() {
    String displayError = _aiLoadingStatus;

    // Regex hiba megtisztítás
    final match =
        RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(_aiLoadingStatus);
    if (match != null && match.groupCount >= 1) {
      displayError = match.group(1)!;
    } else {
      if (displayError.contains('GenerativeAIException:')) {
        displayError = displayError.split('GenerativeAIException:').last.trim();
      }
    }

    // A közvetlen képernyő-átfedés (Overlay) lekérése
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Az OverlayEntry közvetlenül a "képernyőre fest", kikerülve a normál ablakkezelést
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            40.0, // Biztonságos távolság alulról
        left: 16.0,
        right: 16.0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            elevation: 10, // Kiemeli az árnyékolást
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.white24,
                      width: 2), // Extra keret, hogy elüssön a háttértől
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 15,
                        offset: Offset(0, 5))
                  ]),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "FAILED:\n$displayError",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    // Ez a gomb törli magát az Overlay-t a képernyőről
                    onPressed: () => overlayEntry.remove(),
                    child: const Text('CLOSE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Késleltetett beszúrás: Vár 0.3 másodpercet, amíg az "EndGameDialog" animációja
    // lefut, és csak utána dobja rá a képernyő legtetejére a hibaüzenetet.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        overlayState.insert(overlayEntry);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGameReady) {
      return const Scaffold(
          backgroundColor: Color(0xFF0F0F1B),
          body: Center(child: CircularProgressIndicator(color: accentGold)));
    }

    final currentCard = _gameQueue[_currentQuestionIndex];

    return LayoutBuilder(builder: (context, constraints) {
      final isLandscape = constraints.maxWidth > constraints.maxHeight;

      // Érintésfigyelő a játéktéren, ami elrejti a billentyűzetet
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            isLandscape
                ? Row(children: [
                    Expanded(flex: 4, child: _buildCombatHUD()),
                    Expanded(flex: 6, child: _buildQuizPanel(currentCard)),
                  ])
                : Column(children: [
                    Expanded(flex: 4, child: _buildCombatHUD()),
                    Expanded(flex: 6, child: _buildQuizPanel(currentCard)),
                  ]),
            // Speciális státuszjelzők (Pajzs, Kitérés, Átok)
            ShieldIndicator(
                activeShield: _gsm.activeShield, isLandscape: isLandscape),
            DodgeIndicator(
                activeDodgeChance: _gsm.activeDodgeChance,
                dodgeCharges: _gsm.dodgeCharges,
                isLandscape: isLandscape),
            DarkPactIndicator(
                turnsLeft: _gsm.darkPactTurns,
                multiplier: _gsm.darkPactMultiplier,
                isLandscape: isLandscape),
            if (_showDialogue && widget.enemyQuote != null)
              Positioned.fill(
                child: EnemyDialogueOverlay(
                  enemyId: widget.fixedEnemyId ??
                      "goblin", // Ha nincs ID, legyen goblin
                  enemyName: widget.deckTitle,
                  quote: widget.enemyQuote!,
                  onDismiss: () {
                    // Kattintásra eltüntetjük, és indulhat a harc!
                    setState(() {
                      _showDialogue = false;
                    });
                  },
                ),
              ),
          ]),
        ),
      );
    });
  }

  /// A harctér és a képesség gombok (ComboPanel) összeállítása.
  Widget _buildCombatHUD() {
    return Column(children: [
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderSide, width: 2))),
          child: GameWidget(game: _battleGame),
        ),
      ),
      ComboPanel(
        currentCombo: _gsm.currentCombo,
        characterClass: _gsm.characterClass,
        playerLevel: _gsm.playerLevel,
        strength: _gsm.combatController.playerStats['str'] ?? 1,
        intellect: _gsm.combatController.playerStats['intel'] ?? 1,
        vitality: _gsm.combatController.playerStats['vit'] ?? 1,
        agility: _gsm.combatController.playerStats['agi'] ?? 1,
        luck: _gsm.combatController.playerStats['luck'] ?? 1,
        isAttacking: _gsm.isAttacking,
        // Itt adjuk át az _isExtendingDeck-et, hogy AI töltés alatt ne lehessen támadni!
        isChecking: _isChecking || _isExtendingDeck,
        darkPactMultiplier:
            _gsm.darkPactTurns > 0 ? _gsm.darkPactMultiplier : 1.0,
        onAttack: (cost) => _gsm.executeAttack(cost),
      ),
    ]);
  }

  /// A kvíz felület: kérdés doboz és a dinamikus válasz widgetek.
  Widget _buildQuizPanel(QuizCard currentCard) {
    // Ha épp kiterjesztés (generálás) folyik, ne kérdéseket, hanem betöltőképernyőt mutassunk
    if (_isExtendingDeck) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF0F0F1B),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.purpleAccent),
            const SizedBox(height: 30),
            const Text("AI QUEST EXTENSION",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            Text(_aiLoadingStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontFamily: 'monospace')),
          ],
        ),
      );
    }

    // Ha elfogytak a kérdések, de a kombó még nem 0, akkor várunk a végső csapásra!
    if (_isQuestionsFinished && _gsm.currentCombo > 0) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF0F0F1B),
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FinishHimWidget(),
            SizedBox(height: 40),
            Text(
              "USE YOUR REMAINING POWER!",
              style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            )
          ],
        ),
      );
    }

    final disabled = _isChecking || _isQuestionsFinished;
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0F1B),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // RPG stílusú doboz a kérdésnek
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Interface/redBox.png'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              centerSlice: Rect.fromLTRB(16, 16, 32, 32),
            ),
          ),
          child: Text(
            currentCard.question.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
            child: SingleChildScrollView(
                child: _buildQuestionInput(currentCard, disabled))),

        // Megerősítő gomb a többválasztós és szöveges kérdésekhez
        if (currentCard is MultipleSelectCard || currentCard is ShortAnswerCard)
          MaterialButton(
            onPressed: disabled
                ? null
                : () {
                    // Amint rányom a gombra, eltüntetjük a billentyűzetet
                    FocusScope.of(context).unfocus();

                    if (currentCard is MultipleSelectCard) {
                      _quizController.checkMultipleSelect(
                          currentCard, _selectedIndices);
                    }
                    if (currentCard is ShortAnswerCard) {
                      _quizController.checkShortAnswer(
                          currentCard, _textController.text,
                          onStart: () => setState(() => _isChecking = true),
                          onEnd: () => setState(() => _isChecking = false));
                    }
                  },
            color: accentGold,
            minWidth: 200,
            height: 50,
            child: const Text("CONFIRM",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2)),
          ),
      ]),
    );
  }

  /// Dinamikusan betölti a kérdés típusához tartozó widgetet.
  Widget _buildQuestionInput(QuizCard currentCard, bool disabled) {
    if (currentCard is MultipleChoiceCard) {
      return MultipleChoiceWidget(
          card: currentCard,
          isDisabled: disabled,
          isCorrect: _lastAnswerCorrect,
          selectedIndex:
              _selectedIndices.isNotEmpty ? _selectedIndices.first : null,
          onSelect: (idx) {
            _selectedIndices.clear();
            _selectedIndices.add(idx);
            _quizController.checkMultipleChoice(currentCard, idx);
          });
    }
    if (currentCard is MultipleSelectCard) {
      return MultipleSelectWidget(
          card: currentCard,
          isDisabled: disabled,
          isCorrect: _lastAnswerCorrect,
          selectedIndices: _selectedIndices,
          onToggle: (idx) => setState(() {
                _selectedIndices.contains(idx)
                    ? _selectedIndices.remove(idx)
                    : _selectedIndices.add(idx);
              }));
    }
    if (currentCard is ShortAnswerCard) {
      return ShortAnswerWidget(
          card: currentCard,
          isDisabled: disabled,
          isCorrect: _lastAnswerCorrect,
          controller: _textController,
          onSubmit: () => _quizController.checkShortAnswer(
              currentCard, _textController.text,
              onStart: () => setState(() => _isChecking = true),
              onEnd: () => setState(() => _isChecking = false)));
    }
    if (currentCard is MatchingCard) {
      if (_rightSideItems.isEmpty) {
        _rightSideItems = currentCard.pairs.values.toList()..shuffle();
      }
      return MatchingWidget(
        card: currentCard,
        isDisabled: disabled,
        isCorrect: _lastAnswerCorrect,
        solvedPairs: _solvedPairs,
        selectedLeftItem: _selectedLeftItem,
        rightSideItems: _rightSideItems,
        onTap: (item, isLeft) {
          final result = _quizController.handleMatchingTap(
              card: currentCard,
              item: item,
              isLeft: isLeft,
              selectedLeftItem: _selectedLeftItem,
              solvedPairs: _solvedPairs);
          setState(() {
            _selectedLeftItem = result.newSelectedLeft;
            _solvedPairs.addAll(result.solvedPairs);
          });
          if (result.isComplete) _showFeedback(true);
        },
      );
    }
    return const Text("UNKNOWN RUNE TYPE",
        style: TextStyle(color: Colors.white24));
  }
}
