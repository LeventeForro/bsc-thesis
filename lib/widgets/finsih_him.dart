import 'package:flutter/material.dart';

/// FINISH HIM felirat a játék végére
/// Retro Pixel Art stílusban kemény árnyékokkal és élekkel.
class FinishHimWidget extends StatefulWidget {
  const FinishHimWidget({super.key});

  @override
  State<FinishHimWidget> createState() => _FinishHimWidgetState();
}

class _FinishHimWidgetState extends State<FinishHimWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceInOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFAA0000),
      end: const Color(0xFFFF0000),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: _colorAnimation.value!, width: 4),
                    left: BorderSide(color: _colorAnimation.value!, width: 4),
                    bottom: BorderSide(color: Colors.red[900]!, width: 4),
                    right: BorderSide(color: Colors.red[900]!, width: 4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Text(
                    "FINISH HIM!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _colorAnimation.value,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      shadows: const [
                        Shadow(
                          color: Colors.white30,
                          offset: Offset(-2, -2),
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
