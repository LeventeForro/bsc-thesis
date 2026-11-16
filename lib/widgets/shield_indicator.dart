// Ez a widget a Lovag "Shield" (Pajzs) képességének állapotjelzője.
// Megjeleníti az aktuális sebzéscsökkentési bónuszt százalékos formában,
// segítve a játékost a védelmi státuszának követésében a harc során.

import 'package:flutter/material.dart';

class ShieldIndicator extends StatelessWidget {
  /// A pajzs hatékonysága normalizált értékként (pl. 0.3 = 30% sebzéscsökkentés).
  final double activeShield;

  /// Jelzi, hogy a kijelző fekvő módban van-e (UI elrendezés finomhangolásához).
  final bool isLandscape;

  const ShieldIndicator({
    super.key,
    required this.activeShield,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    // 1. LÉPÉS: Ellenőrzés. Ha nincs aktív pajzs (értéke 0 vagy negatív), a widget láthatatlan marad.
    if (activeShield <= 0) return const SizedBox.shrink();

    return Positioned(
      top: 12,
      left: 65, // A karakter portréja melletti fix pozíció.
      child: TweenAnimationBuilder<double>(
        // Megjelenéskor egy rövid (300ms) beúszó és áttetszőségi animációt hajt végre.
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              // Dinamikus eltolás: az animáció alatt jobbról (20 pixel) balra úszik be.
              offset: Offset((1 - value) * 20, 0),
              child: _buildShieldContent(),
            ),
          );
        },
      ),
    );
  }

  /// Felépíti a jelző RPG/Pixel stílusú dobozát.
  Widget _buildShieldContent() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        // Lovag-specifikus kék szegély az azonosíthatóság kedvéért.
        color: Colors.blueAccent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          // Nagyon sötét kék háttér a belső szöveg kontrasztjához.
          color: Color(0xFF0A141F),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pajzs ikon a vizuális megerősítéshez.
            const Icon(Icons.shield, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Statikus felirat fix szélességű betűkkel.
                const Text(
                  "SHIELD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                // Dinamikus sebzéscsökkentési érték (pl. 40% DEF).
                Text(
                  "${(activeShield * 100).round()}% DEF",
                  style: const TextStyle(
                    color: Colors.blueAccent,
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
