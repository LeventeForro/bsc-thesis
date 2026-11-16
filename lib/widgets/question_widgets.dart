// Ez a fájl a kvízkérdések megválaszolásához használt interaktív widgeteket tartalmazza.
// Minden widget egyedi logikát valósít meg a kártyatípustól függően,
// miközben szigorúan tartja magát a játék Pixel Art/RPG vizuális stílusához.

import 'package:flutter/material.dart';
import '../models/card_model.dart';

// Modern Pixel Art RPG Színpaletta konstansok
const Color kPanelBg = Color(0xFF1D1D35);
const Color kAccentGold = Color(0xFFFFD700);
const Color kBorderSide = Color(0xFF3E3E63);

// --- 1. FELELETVÁLASZTÓS WIDGET (Single Choice) ---
/// Egyszerű gomblista, ahol a felhasználó egyetlen helyes választ választhat ki.
class MultipleChoiceWidget extends StatelessWidget {
  final MultipleChoiceCard card;
  final bool isDisabled; // Letiltja az interakciót (pl. ellenőrzés alatt)
  final bool? isCorrect;
  final int? selectedIndex;
  final Function(int) onSelect;

  const MultipleChoiceWidget({
    super.key,
    required this.card,
    required this.isDisabled,
    this.isCorrect,
    this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: card.options.asMap().entries.map((entry) {
        int index = entry.key;
        String text = entry.value;

        // Háttérkép kiválasztása a visszajelzés állapota alapján
        String backgroundImage = 'assets/images/Interface/grayBox.png';

        if (isDisabled && isCorrect != null) {
          // Ha már válaszoltunk, megmutatjuk mi volt a helyes
          if (index == card.correctIndex) {
            backgroundImage = 'assets/images/Interface/greenBox.png';
          } else if (index == selectedIndex && !isCorrect!) {
            backgroundImage = 'assets/images/Interface/redBox.png';
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: isDisabled ? null : () => onSelect(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.fill,
                  filterQuality:
                      FilterQuality.none, // Pixel-perfect megjelenítés
                  centerSlice:
                      const Rect.fromLTRB(16, 16, 32, 32), // 9-slice scaling
                  // Csak akkor szürkítjük, ha disabled de NEM a válasz visszajelzés miatt (pl. animáció fut)
                  colorFilter: (isDisabled && isCorrect == null)
                      ? const ColorFilter.mode(
                          Colors.grey, BlendMode.saturation)
                      : null,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: (isDisabled && isCorrect == null)
                      ? Colors.white24
                      : Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- 2. TÖBBVÁLASZOS WIDGET (Multiple Select) ---
/// Lehetővé teszi több opció kijelölését. A kijelölt elemek arany színű dobozt kapnak.
class MultipleSelectWidget extends StatelessWidget {
  final MultipleSelectCard card;
  final bool isDisabled;
  final bool? isCorrect;
  final List<int> selectedIndices; // Az aktuálisan kijelölt indexek listája
  final Function(int) onToggle;

  const MultipleSelectWidget({
    super.key,
    required this.card,
    required this.isDisabled,
    this.isCorrect,
    required this.selectedIndices,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(card.options.length, (index) {
          final isSelected = selectedIndices.contains(index);
          final isActuallyCorrectOption = card.correct.contains(index);

          // Alapállapot: sárga, ha kijelölt, különben szürke
          String backgroundImage = isSelected
              ? 'assets/images/Interface/yellowBox.png'
              : 'assets/images/Interface/grayBox.png';

          // Visszajelzés állapota (ha már leadtuk a választ)
          if (isDisabled && isCorrect != null) {
            if (isActuallyCorrectOption) {
              // A valóban helyes válaszokat kizöldítjük (akkor is ha nem jelölte be, hogy tanuljon belőle)
              backgroundImage = 'assets/images/Interface/greenBox.png';
            } else if (isSelected && !isActuallyCorrectOption) {
              // Amit bejelölt, de rossz volt, azt bepirosítjuk
              backgroundImage = 'assets/images/Interface/redBox.png';
            } else {
              backgroundImage = 'assets/images/Interface/grayBox.png';
            }
          }

          return GestureDetector(
            onTap: isDisabled ? null : () => onToggle(index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    centerSlice: const Rect.fromLTRB(16, 16, 32, 32),
                    colorFilter: (isDisabled && isCorrect == null)
                        ? const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation)
                        : null,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  card.options[index].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    // Ha fekete volt a sárgán, de most zöld/piros, akkor fehérre váltunk a kontraszt miatt
                    color: (isSelected && !isDisabled)
                        ? Colors.black
                        : ((isDisabled && isCorrect == null)
                            ? Colors.white24
                            : Colors.white),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// --- 3. RÖVID VÁLASZ WIDGET (Short Answer) ---
/// Szabad szöveges beviteli mező, RPG stílusú keretbe ágyazva.
class ShortAnswerWidget extends StatelessWidget {
  final ShortAnswerCard card;
  final bool isDisabled;
  final bool? isCorrect; // ÚJ: Visszajelzéshez
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const ShortAnswerWidget({
    super.key,
    required this.card,
    required this.isDisabled,
    this.isCorrect,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // A TextField háttere vált színt az eredmény alapján
    String backgroundImage = 'assets/images/Interface/grayBox.png';
    if (isDisabled && isCorrect != null) {
      backgroundImage = isCorrect!
          ? 'assets/images/Interface/greenBox.png'
          : 'assets/images/Interface/redBox.png';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              centerSlice: const Rect.fromLTRB(16, 16, 32, 32),
              colorFilter: (isDisabled && isCorrect == null)
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : null,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !isDisabled,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 2),
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
                hintText: 'ENTER ANSWER...',
                hintStyle: TextStyle(color: Colors.white10, fontSize: 14)),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isDisabled) onSubmit();
            },
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

// --- 4. PÁROSÍTÓS WIDGET (Matching) ---
/// Két oszlop elemeinek összekötése. A megoldott párok zöld színnel kiemelve felülre kerülnek.
class MatchingWidget extends StatelessWidget {
  final MatchingCard card;
  final bool isDisabled;
  final bool? isCorrect;
  final Map<String, String> solvedPairs;
  final String? selectedLeftItem;
  final List<String> rightSideItems;
  final Function(String, bool) onTap;

  const MatchingWidget({
    super.key,
    required this.card,
    required this.isDisabled,
    this.isCorrect,
    required this.solvedPairs,
    required this.selectedLeftItem,
    required this.rightSideItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unsolvedLeft =
        card.pairs.keys.where((k) => !solvedPairs.containsKey(k)).toList();
    final unsolvedRight =
        rightSideItems.where((v) => !solvedPairs.containsValue(v)).toList();

    return Column(
      children: [
        // MEGOLDOTT PÁROK (Zöld dobozokban)
        if (solvedPairs.isNotEmpty) ...[
          ...solvedPairs.entries
              .map((entry) => _buildSolvedPairRow(entry.key, entry.value)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: kBorderSide, thickness: 2)),
        ],

        // AKTÍV PÁROSÍTÓ TERÜLET (Két oszlop)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMatchingColumn(unsolvedLeft, true)),
            const SizedBox(width: 8),
            Expanded(child: _buildMatchingColumn(unsolvedRight, false)),
          ],
        ),
      ],
    );
  }

  /// Megrajzol egy már sikeresen összekötött párt.
  Widget _buildSolvedPairRow(String key, String value) {
    // Ha a legvégén vagyunk és isCorrect false,
    // akkor a maradék megoldatlan elemeket pirosra festjük.
    // De a már megoldott párok maradjanak zöldek.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Interface/greenBox.png'),
          fit: BoxFit.fill,
          centerSlice: Rect.fromLTRB(16, 16, 32, 32),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(key.toUpperCase(),
                  textAlign: TextAlign.center, style: _matchStyle())),
          const Icon(Icons.link, color: Colors.white70, size: 20),
          Expanded(
              child: Text(value.toUpperCase(),
                  textAlign: TextAlign.center, style: _matchStyle())),
        ],
      ),
    );
  }

  /// Felépíti az oszlopokat a még meg nem oldott elemekből.
  Widget _buildMatchingColumn(List<String> items, bool isLeft) {
    return Column(
      children: items.map((item) {
        final isSelected = isLeft && selectedLeftItem == item;
        return _buildMatchingBox(item, isSelected, () => onTap(item, isLeft));
      }).toList(),
    );
  }

  /// RPG stílusú gomb a párosításhoz.
  Widget _buildMatchingBox(
      String text, bool isSelected, VoidCallback onPressed) {
    // Alap háttérkép logika
    String backgroundImage = isSelected
        ? 'assets/images/Interface/yellowBox.png'
        : 'assets/images/Interface/grayBox.png';

    // Ha rossz választ adott, a megoldatlan elemeket pirosra festjük, de a már megoldott párok maradjanak zöldek
    if (isDisabled && isCorrect == false) {
      backgroundImage = 'assets/images/Interface/redBox.png';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.fill,
              centerSlice: const Rect.fromLTRB(16, 16, 32, 32),
              colorFilter: (isDisabled && isCorrect == null)
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : null,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: (isSelected && !isDisabled)
                    ? Colors.black
                    : ((isDisabled && isCorrect == null)
                        ? Colors.white24
                        : Colors.white)),
          ),
        ),
      ),
    );
  }

  TextStyle _matchStyle() => const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'monospace');
}
