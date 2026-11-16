// Ez a fájl a főmenü (HomeScreen) megvalósításáért felel.
// Kezeli a navigációt a modulok között, a reszponzív elrendezést (mobil/asztali),
// az AI-alapú küldetésgenerálás indítását, és a Flame-alapú hős-bemutatót (Showcase).

import 'package:flutter/material.dart';
import 'package:szakdolgozat/screens/game_screen.dart';
import '../services/ai_service.dart';
import '../models/card_model.dart';
import 'library_screen.dart';
import 'create_deck_screen.dart';
import 'profile_screen.dart';
import '../game/story/index_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame/game.dart';
import '../game/entity_component.dart';
import '../game/heroes/archer.dart';
import '../game/heroes/knight.dart';
import '../game/heroes/necromancer.dart';
import '../game/heroes/hero_base.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Az aktuálisan kiválasztott fül indexe
  late PageController _pageController; // A lapozható felület vezérlője

  // RPG/Pixel Art stílusú színpaletta konstansok
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  /// A navigációhoz használt főoldalak listája.
  static final List<Widget> _pages = <Widget>[
    const GameModeSelection(), // Játékmód választó
    const LibraryScreen(), // Közösségi könyvtár
    const CreateDeckScreen(), // Saját pakli készítő
    const ProfileScreen(), // Karakterstatisztikák és profil
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Kezeli a navigációs sávon történő kattintást: frissíti az indexet és lapoz.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Frissíti az indexet, ha a felhasználó vízszintes elhúzással lapoz (swipe).
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptív UI: 600px szélesség felett asztali (oldalsávos), alatta mobil (alsó sávos) nézet
        bool isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          // --- ASZTALI ELRENDEZÉS (NavigationRail) ---
          return Scaffold(
            backgroundColor: bgDark,
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    backgroundColor: panelBg,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(color: accentGold),
                    unselectedIconTheme:
                        const IconThemeData(color: Colors.white24),
                    selectedLabelTextStyle: const TextStyle(
                        color: accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    unselectedLabelTextStyle:
                        const TextStyle(color: Colors.white24, fontSize: 11),
                    destinations: const [
                      NavigationRailDestination(
                          icon: Icon(Icons.videogame_asset),
                          label: Text('PLAY')),
                      NavigationRailDestination(
                          icon: Icon(Icons.book), label: Text('LIBRARY')),
                      NavigationRailDestination(
                          icon: Icon(Icons.add_box), label: Text('CREATE')),
                      NavigationRailDestination(
                          icon: Icon(Icons.person), label: Text('HERO')),
                    ],
                  ),
                  const VerticalDivider(
                      thickness: 2, width: 2, color: borderSide),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // --- MOBIL ELRENDEZÉS (BottomNavigationBar) ---
          return Scaffold(
            backgroundColor: bgDark,
            body: SafeArea(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: _pages,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: borderSide, width: 2)),
              ),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(Icons.videogame_asset), label: 'PLAY'),
                  BottomNavigationBarItem(icon: Icon(Icons.book), label: 'LIB'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.add_box), label: 'NEW'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person), label: 'HERO'),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: accentGold,
                unselectedItemColor: Colors.white24,
                backgroundColor: panelBg,
                type: BottomNavigationBarType.fixed,
                onTap: _onItemTapped,
              ),
            ),
          );
        }
      },
    );
  }
}

/// Játékmód választó felület: Történet mód és AI kérdésgenerálás indítása.
class GameModeSelection extends StatelessWidget {
  const GameModeSelection({super.key});

  /// Megjelenít egy dialógust a témakör bekéréséhez, majd elindítja az AI generálást.
  void _showAiTopicDialog(BuildContext context) {
    TextEditingController topicController = TextEditingController();
    bool isLoading = false;
    double questionCount = 5;

    // Státusz és hibaüzenetek tárolása a UI-hoz
    String statusMessage = "WAITING FOR INPUT...";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1D35),
              title: const Text('AI QUEST GENERATOR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              content: isLoading
                  // Töltőképernyő kibővítése szöveggel
                  ? SizedBox(
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.blueAccent),
                          const SizedBox(height: 20),
                          // Valós időben frissülő AI státusz
                          Text(statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    )
                  // ----------------------------------------------
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: topicController,
                          style: const TextStyle(
                              color: Colors.white, fontFamily: 'monospace'),
                          decoration: const InputDecoration(
                              hintText: 'Enter topic (e.g. Ancient Rome)',
                              hintStyle: TextStyle(color: Colors.white24)),
                        ),
                        const SizedBox(height: 25),
                        Text('QUESTIONS: ${questionCount.toInt()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace')),
                        Slider(
                          value: questionCount,
                          min: 3,
                          max: 50,
                          divisions: 47,
                          activeColor: Colors.blueAccent,
                          onChanged: (newValue) =>
                              setState(() => questionCount = newValue),
                        ),
                      ],
                    ),
              actions: [
                if (!isLoading)
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("[ CANCEL ]",
                          style: TextStyle(color: Colors.white54))),
                if (!isLoading)
                  TextButton(
                    onPressed: () async {
                      if (topicController.text.trim().isEmpty) return;
                      setState(() {
                        isLoading = true;
                        statusMessage = "INITIALIZING AI...";
                      });

                      int initialBatchSize =
                          questionCount > 5 ? 5 : questionCount.toInt();

                      List<QuizCard> generatedCards = await AiService()
                          .generateEndlessQuestions(
                              topicController.text, initialBatchSize,
                              onProgress: (progress, status) {
                        setState(() => statusMessage = status);
                      });

                      if (!context.mounted) return;

                      if (generatedCards.isNotEmpty) {
                        // SIKER
                        setState(() => isLoading = false);
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GameScreen(
                                      predefinedCards: generatedCards,
                                      title:
                                          "AI: ${topicController.text.toUpperCase()}",
                                      maxQuestionsLimit: questionCount.toInt(),
                                    )));
                      } else {
                        // Hiba kezelése
                        setState(() => isLoading = false);

                        // mwssage rész kinyerése a JSON-ből
                        String displayError = statusMessage;
                        final match = RegExp(r'"message"\s*:\s*"([^"]+)"')
                            .firstMatch(statusMessage);

                        if (match != null && match.groupCount >= 1) {
                          // Ha talált "message" kulcsot, csak annak az értékét vesszük ki
                          displayError = match.group(1)!;
                        } else {
                          // Ha nem JSON hiba jött (pl. nincs internet), levágjuk a felesleges prefixeket
                          if (displayError.contains('GenerativeAIException:')) {
                            displayError = displayError
                                .split('GenerativeAIException:')
                                .last
                                .trim();
                          }
                        }

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            "FAILED:\n$displayError", // Itt már a letisztított üzenet jelenik meg
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.redAccent,
                          duration: const Duration(days: 365),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'CLOSE',
                            textColor: Colors.white,
                            onPressed: () {
                              // a SnackBar bezárásáról, ha rányomnak egy Action gombra.
                            },
                          ),
                        ));
                      }
                    },
                    child: const Text("[ GENERATE ]",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const HeroShowcaseWidget(), // Aktuális hős bemutatója felül
            const SizedBox(height: 30),
            const Text("SELECT A GAME MODE",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 25),
            _buildGameModeCard(context,
                title: "STORY MODE",
                subtitle: "Progress through levels",
                icon: Icons.map,
                color: Colors.purpleAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IndexScreen()))),
            const SizedBox(height: 16),
            _buildGameModeCard(context,
                title: "AI QUEST MODE",
                subtitle: "Generate a deck from any topic",
                icon: Icons.auto_awesome,
                color: Colors.blueAccent,
                onTap: () => _showAiTopicDialog(context)),
          ],
        ),
      ),
    );
  }

  /// RPG stílusú választókártya a játékmódokhoz.
  Widget _buildGameModeCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1D1D35),
          border: Border.all(color: const Color(0xFF3E3E63), width: 2)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      border: Border.all(color: color.withOpacity(0.5)),
                      color: Colors.black26),
                  child: Icon(icon, color: color, size: 28)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

/// [MenuShowcaseGame] - Egy kisméretű Flame játékmotor példány, amely
/// csak a kiválasztott hős animációját jeleníti meg a menüben.
class MenuShowcaseGame extends FlameGame {
  final String characterClass;
  MenuShowcaseGame({required this.characterClass});

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    HeroBase hero;
    switch (characterClass) {
      case 'archer':
        hero = Archer();
        break;
      case 'knight':
        hero = Knight();
        break;
      case 'necromancer':
        hero = Necromancer();
        break;
      default:
        hero = Knight();
    }

    final heroComponent =
        EntityComponent(config: hero.entityConfig, isEnemy: false);

    heroComponent.isManualMode = true;
    heroComponent.isEntering = false; // Megakadályozza, hogy elsétáljon
    await add(heroComponent);

    // Kasztspecifikus méretezés és eltolás a widgeten belül
    double customScale = 1.4;
    double yMultiplier = 0.85;

    switch (characterClass) {
      case 'knight':
        yMultiplier = 1.3;
        break;
      case 'archer':
        yMultiplier = 1.85;
        break;
      case 'necromancer':
        yMultiplier = 1.5;
        break;
    }

    heroComponent.scale = Vector2.all(customScale);
    heroComponent.position = Vector2(size.x / 2, size.y * yMultiplier);

    heroComponent.targetPos = heroComponent.position;

    heroComponent.playState(EntityState.idle);
  }
}

/// [HeroShowcaseWidget] - Egy Stateful widget, amely betölti a hős adatait
/// Firestore-ból és beágyazza a Flame-alapú animációt.
class HeroShowcaseWidget extends StatefulWidget {
  const HeroShowcaseWidget({super.key});

  @override
  State<HeroShowcaseWidget> createState() => _HeroShowcaseWidgetState();
}

class _HeroShowcaseWidgetState extends State<HeroShowcaseWidget> {
  MenuShowcaseGame? _game; // A Flame játékmotor példánya
  String _charClass = 'knight';
  Color _heroColor = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _loadHeroData();
  }

  /// Lekéri a felhasználó választott karakterosztályát a felhőből.
  Future<void> _loadHeroData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && mounted) {
          final data = doc.data();
          _charClass = data?['characterClass'] ?? 'knight';
        }
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }

    // Hős-specifikus színbeállítás az aurához
    switch (_charClass) {
      case 'knight':
        _heroColor = Colors.orangeAccent;
        break;
      case 'archer':
        _heroColor = Colors.greenAccent;
        break;
      case 'necromancer':
        _heroColor = Colors.blueAccent;
        break;
    }

    if (mounted) {
      setState(() {
        _game = MenuShowcaseGame(characterClass: _charClass);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
            colors: [_heroColor.withOpacity(0.2), Colors.black26], radius: 0.8),
        border: Border.all(color: const Color(0xFF3E3E63), width: 2),
      ),
      child:
          GameWidget(game: _game!), // Itt fut a Flame motor a hős animációjával
    );
  }
}
