// Ez a fájl a harci képességek kezelőfelületéért (ComboPanel) felel.
// Megjeleníti az aktuális kombó pontokat, kiszámítja a statisztikák alapján a skillek
// sebzését/hatását, és kezeli a támadások indítását az RPG logika szerint.

import 'package:flutter/material.dart';

class ComboPanel extends StatefulWidget {
  final int currentCombo; // Az aktuálisan rendelkezésre álló energia (0-4)
  final String characterClass; // A hős kasztja (knight, archer, necromancer)
  final int playerLevel; // A játékos szintje (skálázáshoz)
  final int strength; // Erő statisztika
  final int intellect; // Intelligencia statisztika
  final int vitality; // Vitalitás statisztika
  final int agility; // Ügyesség statisztika
  final int luck; // Szerencse statisztika
  final bool
      isAttacking; // True, ha éppen zajlik egy animáció (gombok letiltása)
  final bool
      isChecking; // True, ha éppen válaszellenőrzés van (gombok letiltása)
  final double darkPactMultiplier; // Necromancer speciális sebzésszorzója
  final Function(int) onAttack; // Callback függvény a támadás indításához

  const ComboPanel({
    super.key,
    required this.currentCombo,
    required this.characterClass,
    required this.playerLevel,
    required this.strength,
    required this.intellect,
    required this.vitality,
    required this.agility,
    required this.luck,
    required this.isAttacking,
    required this.isChecking,
    required this.onAttack,
    required this.darkPactMultiplier,
  });

  @override
  State<ComboPanel> createState() => _ComboPanelState();
}

class _ComboPanelState extends State<ComboPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Modern Pixel Art Színpaletta konstansok
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  // Képesség gombok színkódjai költség szerint
  static const Color kButtonBlue = Color(0xFF3498DB);
  static const Color kButtonOrange = Color(0xFFE67E22);
  static const Color kButtonGreen = Color(0xFF2ECC71);
  static const Color kButtonPurple = Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    // Lüktető animáció: akkor aktiválódik, ha a kombó csík megtelt (Ultimate kész)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.currentCombo == 4) _animationController.repeat(reverse: true);
  }

  /// Frissíti az animációt, ha a kombó pontok száma eléri a maximumot.
  @override
  void didUpdateWidget(ComboPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentCombo == 4 && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (widget.currentCombo < 4 && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Kiszámítja a képességek dinamikus értékeit (sebzés, védelem) a karakter statisztikái alapján.
  String _getSkillTitle(int cost) {
    // Necromancer esetén a Dark Pact szorzó módosítja az alap sebzést
    double m = widget.characterClass == 'necromancer'
        ? widget.darkPactMultiplier
        : 1.0;

    if (widget.characterClass == 'knight') {
      switch (cost) {
        case 1:
          return "${(10 + widget.strength * 0.5).round()} ATK";
        case 2:
          double def =
              (widget.vitality / (widget.playerLevel * 2)).clamp(0.1, 0.6);
          return "+${(def * 100).round()}% SHIELD";
        case 3:
          return "3-HIT COMBO";
        case 4:
          return "${((widget.strength * 2.5) + (widget.luck * 1.2)).round()} ATK";
      }
    }

    if (widget.characterClass == 'archer') {
      switch (cost) {
        case 1:
          return "${(10 + widget.agility * 0.6).round()} ATK";
        case 2:
          double eva = (0.1 + (widget.agility / (widget.playerLevel * 100)))
              .clamp(0.1, 0.7);
          return "${(eva * 100).round()}% DODGE";
        case 3:
          return "TRIPLE SHOT";
        case 4:
          return "8-HIT EXECUTE";
      }
    }

    if (widget.characterClass == 'necromancer') {
      switch (cost) {
        case 1:
          return "${((10 + widget.intellect * 0.8) * m).round()} ATK";
        case 2:
          return "DARK PACT";
        case 3:
          return "CURSE & ATK";
        case 4:
          return "ULTIMATE CURSE";
      }
    }
    return "SPECIAL";
  }

  @override
  Widget build(BuildContext context) {
    double progressValue =
        widget.currentCombo / 4.0; // Normalizált érték (0.0 - 1.0) a csíkhoz

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: bgDark,
        border: Border(top: BorderSide(color: borderSide, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: [
          _buildComboProgressBar(progressValue), // Energia mérő sáv
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(1, kButtonBlue),
              _buildButton(2, kButtonOrange),
              _buildButton(3, kButtonGreen),
              _buildButton(4, kButtonPurple),
            ],
          )
        ],
      ),
    );
  }

  /// Segédwidget a gombok méretezéséhez.
  Widget _buildButton(int cost, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: _buildPixelComboButton(
          cost: cost,
          title: _getSkillTitle(cost),
          color: color,
        ),
      ),
    );
  }

  /// Létrehozza a lüktető kombó sávot (Combo Gauge).
  Widget _buildComboProgressBar(double value) {
    bool isMaxCombo = widget.currentCombo == 4;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Teli állapotban arany és piros között lüktet a szín
        Color progressColor = isMaxCombo
            ? Color.lerp(accentGold, Colors.redAccent, _pulseAnimation.value)!
            : accentGold;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("COMBO",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                Text(
                    isMaxCombo
                        ? "ULTIMATE READY!"
                        : "LEVEL ${widget.currentCombo}",
                    style: TextStyle(
                        color: progressColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: borderSide, width: 2)),
              child: Stack(
                children: [
                  // Rácsozás: 4 egyenlő részre osztja a sávot
                  Row(
                    children: List.generate(
                        4,
                        (index) => Expanded(
                              child: Container(
                                  decoration: BoxDecoration(
                                      border: Border(
                                          right: BorderSide(
                                              color:
                                                  borderSide.withOpacity(0.5),
                                              width: 1)))),
                            )),
                  ),
                  // A tényleges töltöttségi szint vizualizációja
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        boxShadow: isMaxCombo
                            ? [
                                BoxShadow(
                                    color: progressColor.withOpacity(0.5),
                                    blurRadius: 10 * _pulseAnimation.value)
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// RPG/Pixel stílusú gomb, amely csak akkor aktív, ha van elég kombó pont.
  Widget _buildPixelComboButton(
      {required int cost, required String title, required Color color}) {
    bool canAfford = widget.currentCombo >= cost; // Van-e elég energia?
    bool isActive =
        widget.currentCombo == cost || (cost == 4 && widget.currentCombo == 4);

    return GestureDetector(
      onTap: (canAfford && !widget.isAttacking && !widget.isChecking)
          ? () => widget.onAttack(cost)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: canAfford ? color : Colors.black26,
          // Pixel-művészeti stílusú keret: felülről fényesebb, alulról árnyékosabb
          border: Border(
            top: BorderSide(
                color: canAfford
                    ? Colors.white.withOpacity(0.4)
                    : Colors.transparent,
                width: 2),
            bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: 4),
            left: BorderSide(
                color: canAfford
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                width: 2),
            right: BorderSide(color: Colors.black.withOpacity(0.3), width: 2),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: accentGold.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text("$cost",
                style: TextStyle(
                    color: canAfford ? Colors.white : Colors.white10,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'monospace')),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: Colors.black26,
              child: Text(title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: canAfford ? Colors.white : Colors.white10,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
