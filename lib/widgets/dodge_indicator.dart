// Ez a widget az Íjász "Dodge" (Kitérés) mechanizmusának állapotjelzője.
// Megjeleníti a hátralévő védelmi tölteteket és az aktuális kitérési esélyt százalékban.

import 'package:flutter/material.dart';

class DodgeIndicator extends StatelessWidget {
  /// Az aktuális kitérési esély (EVA - Evasion) normalizált értéke (pl. 0.5 = 50%).
  final double activeDodgeChance;

  /// A hátralévő védelmi alkalmak száma. Minden beérkező ütésnél eggyel csökken.
  final int dodgeCharges;

  /// Jelzi, hogy a felület fekvő módban van-e (pozicionáláshoz használható).
  final bool isLandscape;

  const DodgeIndicator({
    super.key,
    required this.activeDodgeChance,
    required this.dodgeCharges,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    // 1. LÉPÉS: Ellenőrzés. Ha nincs esély vagy elfogytak a töltetek, nem rajzolunk semmit.
    if (activeDodgeChance <= 0 || dodgeCharges <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      left: 65, // A karakter portréja mellett jelenik meg.
      child: TweenAnimationBuilder<double>(
        // Megjelenéskor egy 300ms-os beúszó és áttetszőségi animációt indítunk.
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              // Dinamikus eltolás: az animáció elején 20 pixellel jobbról indul.
              offset: Offset((1 - value) * 20, 0),
              child: _buildDodgeContent(),
            ),
          );
        },
      ),
    );
  }

  /// Felépíti a jelző RPG stílusú dobozát.
  Widget _buildDodgeContent() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        // Élénkzöld pixel-stílusú szegély (az íjász/ügyesség színe).
        color: Colors.greenAccent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          // Nagyon sötét zöld háttér a belső szöveg kontrasztjához.
          color: Color(0xFF0A1F0F),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Villám ikon, amely a gyorsaságra és reflexre utal.
            const Icon(Icons.bolt, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Megjeleníti a hátralévő tölteteket (pl. 3X CHRG).
                Text(
                  "${dodgeCharges}X CHRG",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily:
                        'monospace', // RPG stílusú fix szélességű betűk.
                  ),
                ),
                // Megjeleníti a kitérési esélyt kerekített százalékban (pl. 45% EVA).
                Text(
                  "${(activeDodgeChance * 100).round()}% EVA",
                  style: const TextStyle(
                    color: Colors.greenAccent,
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
