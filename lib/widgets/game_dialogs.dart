// Ez a statikus segédosztály felelős a játék végi összefoglaló dialógusok (Győzelem/Vereség) megjelenítéséért.
// Kezeli az RPG stílusú vizuális visszajelzést, az XP összesítést, és az AI-alapú extra funkciók indítását.

import 'package:flutter/material.dart';

class GameDialogs {
  // RPG vizuális stílus konstansai az egységes megjelenéshez
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  /// Megjeleníti a kör végi eredményjelző ablakot.
  /// [isVictory]: Meghatározza, hogy sikeres volt-e a próbatétel.
  /// [isAiDeck]: Jelzi, ha a paklit az AI generálta (ekkor felajánlja a mentést).
  /// [onGoBack]: Visszavezeti a felhasználót a válaszok áttekintéséhez.
  static void showEndGame({
    required BuildContext context,
    required bool isVictory,
    required int defeatedMonsters,
    required int earnedXp,
    required bool isAiDeck,
    required VoidCallback onSaveAiDeck,
    required VoidCallback onGoBack,
    VoidCallback? onContinueAi,
  }) {
    // A kontextusnak megfelelő üzenet kiválasztása
    String message =
        isVictory ? "YOU SURVIVED THE TRIAL!" : "YOUR SPIRIT HAS FADED.";

    showDialog(
      context: context,
      barrierDismissible:
          false, // Kényszerített interakció: nem zárható be mellékattintással
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: panelBg,
            // Színkódolt keret: arany győzelemkor, vörös vereségkor
            border: Border.all(
              color: isVictory ? accentGold : Colors.redAccent,
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- DINAMIKUS FEJLÉC ---
              Text(
                isVictory ? "VICTORY" : "DEFEAT",
                style: TextStyle(
                  color: isVictory ? accentGold : Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                  height: 2,
                  width: 80,
                  color: isVictory ? accentGold : Colors.redAccent),
              const SizedBox(height: 20),

              // --- STÁTUSZ IKON ---
              Icon(
                isVictory ? Icons.emoji_events : Icons.dangerous,
                size: 64,
                color:
                    isVictory ? accentGold : Colors.redAccent.withOpacity(0.5),
              ),
              const SizedBox(height: 20),

              // --- ÁLLAPOT ÜZENET ---
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // --- JUTALOM PANEL (Csak ha van mit mutatni) ---
              if (isVictory || earnedXp > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: borderSide),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow("MONSTERS SLAIN", "$defeatedMonsters"),
                      const SizedBox(height: 4),
                      _buildStatRow("XP GAINED", "+$earnedXp"),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // --- FUNKCIÓGOMBOK ---

              // Mentés: Ha AI generált tartalommal játszott, elrakhatja a könyvtárba
              if (isAiDeck)
                _buildPixelButton(
                  label: "SAVE SCROLL",
                  color: Colors.blueAccent,
                  onTap: onSaveAiDeck,
                ),

              // AI Bővítés: Győzelem esetén felajánlja a pakli végtelenített kiterjesztését
              if (isVictory && !isAiDeck && onContinueAi != null) ...[
                const SizedBox(height: 8),
                _buildPixelButton(
                  label: "EXTEND QUEST (AI)",
                  color: accentGold,
                  textColor: Colors.black,
                  onTap: onContinueAi,
                ),
              ],

              // Áttekintés: Visszanézhető a válaszok helyessége
              const SizedBox(height: 8),
              _buildPixelButton(
                label: "SHOW ANSWERS",
                color: isVictory ? Colors.greenAccent : Colors.white12,
                textColor: isVictory ? Colors.black : Colors.white54,
                onTap: onGoBack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Létrehoz egy adat-sort a jutalom panelen belül.
  static Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        Text(value,
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ],
    );
  }

  /// RPG stílusú, szögletes nyomógomb generálása.
  /// [label]: A gombon megjelenő szöveg.
  /// [color]: A gomb alapszíne.
  static Widget _buildPixelButton({
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: MaterialButton(
        onPressed: onTap,
        color: color,
        elevation: 0,
        highlightElevation: 0,
        // Pixel-art hatású árnyékolt keret
        shape: const Border(
          top: BorderSide(color: Colors.white24, width: 2),
          bottom: BorderSide(color: Colors.black26, width: 4),
          left: BorderSide(color: Colors.white10, width: 2),
          right: BorderSide(color: Colors.black12, width: 2),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
