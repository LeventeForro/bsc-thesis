// Ez a widget a Necromancer "Dark Pact" (Sötét Egyezség) képességének állapotjelzője.
// Megjeleníti a hátralévő köröket és a sebzésnövekedés mértékét a harci felületen.

import 'package:flutter/material.dart';

class DarkPactIndicator extends StatelessWidget {
  /// Megadja, hány körig tart még az aktív sebzésbónusz.
  final int turnsLeft;

  /// A sebzés matematikai szorzója (pl. 1.5 = +50% sebzés).
  final double multiplier;

  /// Jelzi, hogy a kijelző fekvő módban van-e (UI elrendezés finomhangolásához).
  final bool isLandscape;

  const DarkPactIndicator({
    super.key,
    required this.turnsLeft,
    required this.multiplier,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    // Ha a hatás lejárt vagy nem aktív, nem foglal helyet a képernyőn.
    if (turnsLeft <= 0) return const SizedBox.shrink();

    // Százalékos formátumra alakítjuk a szorzót a felhasználó számára (pl. 1.3 -> 30).
    int bonusPercentage = ((multiplier - 1.0) * 100).round();

    return Positioned(
      top: 12,
      left: 65, // A karakter portréja vagy más indikátorok melletti pozíció.
      child: TweenAnimationBuilder<double>(
        // Megjelenéskor egy lágy úszó és áttetszőségi animációt kap.
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              // Az animáció alatt balról jobbra úszik be a panel.
              offset: Offset((1 - value) * 20, 0),
              child: _buildPactContent(bonusPercentage),
            ),
          );
        },
      ),
    );
  }

  /// Felépíti az indikátor tényleges grafikai elemeit (ikonok és szövegek).
  Widget _buildPactContent(int bonusPercentage) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        // RPG stílusú éles szegély vörös színnel (vér/mágia motívum).
        color: Colors.redAccent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          // Nagyon sötét lila/fekete háttér a jó olvashatóságért.
          color: Color(0xFF1A0A1F),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tematikus ikon (vércsepp/életerő típusú).
            const Icon(Icons.bloodtype, color: Colors.redAccent, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hátralévő körök kiírása fix szélességű betűtípussal.
                Text(
                  "$turnsLeft TRNS",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                // Az aktuális sebzésbónusz százalékos megjelenítése.
                Text(
                  "+$bonusPercentage% ATK",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
