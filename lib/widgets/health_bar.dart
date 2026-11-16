// Ez a komponens felelős az életerő (HP) sávok kirajzolásáért a Flame játékmotoron belül.
// Dinamikusan kezeli a töltöttségi szintet, a háttérszíneket, a kereteket és a
// számszerűsített értékek (aktuális/max) szöveges megjelenítését.

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class HealthBarComponent extends PositionComponent {
  int _current; // Az aktuális életerőpontok száma
  int _max; // A maximum életerőpontok száma
  final Color _barColor; // A töltöttségi szint színe (pl. zöld vagy piros)
  final Color _bgColor; // A csík hátterének színe
  final Color _borderColor; // A keret színe
  final Color _labelColor; // A szöveges felirat színe

  HealthBarComponent({
    required Vector2 position,
    required Vector2 size,
    required int max,
    required Color barColor,
    Color bgColor = const Color(0xFF000000),
    Color borderColor = const Color(0xFFFFFFFF),
    Color labelColor = const Color(0xFFFFFFFF),
  })  : _current = max,
        _max = max,
        _barColor = barColor,
        _bgColor = bgColor,
        _borderColor = borderColor,
        _labelColor = labelColor,
        super(position: position, size: size);

  /// Inicializálja az életerőt egy új maximum értékkel.
  /// Hasznos új ellenség megjelenésekor vagy szintlépés utáni gyógyuláskor.
  /// [newMax]: Az új beállítandó maximum életerő.
  void initHealth(int newMax) {
    _max = newMax;
    _current = newMax;
  }

  /// Frissíti az aktuális életerőpontokat.
  /// [value]: Az új érték, amelyet a rendszer automatikusan a 0 és a maximum közé korlátoz.
  void setHealth(int value) => _current = value.clamp(0, _max);

  /// A Flame motor renderelési ciklusa, amely minden képkockánál meghívódik.
  @override
  void render(Canvas canvas) {
    if (_max <= 0) return;

    // Arányok és méretek kiszámítása a komponens befoglaló mérete alapján
    final double barH =
        size.y * 0.55; // A csík magassága a teljes magasság 55%-a
    final double barY = size.y * 0.10; // Függőleges eltolás felülről
    final double fill = (_current / _max).clamp(0.0, 1.0); // Töltöttségi arány

    // 1. LÉPÉS: A háttér (üres sáv) megrajzolása
    final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, size.x, barH), Radius.circular(barH / 2));
    canvas.drawRRect(bgRect, Paint()..color = _bgColor.withOpacity(0.55));

    // 2. LÉPÉS: A töltöttség (aktuális HP) megrajzolása
    if (fill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, barY, size.x * fill, barH),
            Radius.circular(barH / 2)),
        Paint()..color = _barColor,
      );
    }

    // 3. LÉPÉS: A keret megrajzolása a kontúrért
    canvas.drawRRect(
        bgRect,
        Paint()
          ..color = _borderColor.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // 4. LÉPÉS: A szöveges információk (pl. "75 / 100") renderelése
    final tp = TextPainter(
      text: TextSpan(
        text: '$_current / $_max',
        style: TextStyle(
          color: _labelColor,
          fontSize: size.y *
              0.35, // A szöveg mérete a komponens magasságához igazodik
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
                color: Color(0xFF000000),
                blurRadius: 4) // Árnyék a jobb olvashatóságért
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);

    // A szöveg középre igazítása a csíkon belül
    tp.paint(
        canvas, Offset((size.x - tp.width) / 2, barY + (barH - tp.height) / 2));
  }
}
