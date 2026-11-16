// Ez a komponens felelős a harc közbeni sebzésértékek (vagy gyógyulás) animált megjelenítéséért.
// A szöveg a becsapódás helyén jelenik meg, majd felfelé úszik és fokozatosan elhalványul.

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class DamageTextComponent extends TextComponent {
  /// Mennyi ideig marad életben a komponens (másodperc).
  final double lifespan = 1.0;

  /// Belső időzítő az élettartam követéséhez.
  double _timer = 0.0;

  /// A szöveg mozgási sebessége és iránya (V2: 0 vízszintes, -150 függőlegesen felfelé).
  final Vector2 _velocity = Vector2(0, -150);

  /// A szöveg alapszíne (pl. sebzésnél piros, gyógyulásnál zöld).
  final Color baseColor;

  /// Jelzi, ha a találat kritikus volt (ilyenkor nagyobb mérettel jelenik meg).
  final bool isCrit;

  DamageTextComponent({
    required String text,
    required Vector2 position,
    required this.baseColor,
    this.isCrit = false,
  }) : super(
            text: text,
            position: position,
            anchor: Anchor.center,
            priority: 100) {
    // Magas prioritás (Z-index), hogy a karakterek és effektek felett lebegjen.
    _applyStyle(1.0);
  }

  /// Beállítja a szöveg renderelési stílusát, beleértve a dinamikus áttetszőséget.
  /// [opacity]: A szöveg és az árnyék aktuális átlátszósága (0.0 - 1.0).
  void _applyStyle(double opacity) {
    textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'Courier', // Fix szélességű font a retró/pixel hatásért.
        fontSize: isCrit
            ? 42.0
            : 28.0, // Kritikus találatnál jelentősen nagyobb méret.
        fontWeight: FontWeight.w900,
        color: baseColor.withOpacity(opacity),
        shadows: [
          Shadow(
            blurRadius: 0.0,
            color: const Color(0xFF000000).withOpacity(opacity),
            offset:
                const Offset(3, 3), // RPG-kre jellemző éles, "kemény" árnyék.
          ),
        ],
      ),
    );
  }

  /// Minden frame-ben lefutó frissítési logika.
  @override
  void update(double dt) {
    super.update(dt);

    // 1. Mozgatás: a pozíció eltolása felfelé az idő függvényében.
    position += _velocity * dt;
    _timer += dt;

    // 2. Életciklus kezelése.
    if (_timer > lifespan) {
      // Ha lejárt az idő, töröljük a komponenst a memóriából.
      removeFromParent();
    } else {
      // 3. Elhalványítás: az élettartam utolsó 0.5 másodpercében lineárisan csökkentjük az opacitást.
      final remaining = lifespan - _timer;
      if (remaining < 0.5) {
        _applyStyle((remaining / 0.5).clamp(0.0, 1.0));
      }
    }
  }
}
