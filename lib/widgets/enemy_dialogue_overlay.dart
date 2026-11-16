import 'package:flutter/material.dart';

class EnemyDialogueOverlay extends StatefulWidget {
  final String enemyId;
  final String enemyName;
  final String quote;
  final VoidCallback onDismiss;

  const EnemyDialogueOverlay({
    super.key,
    required this.enemyId,
    required this.enemyName,
    required this.quote,
    required this.onDismiss,
  });

  @override
  State<EnemyDialogueOverlay> createState() => _EnemyDialogueOverlayState();
}

class _EnemyDialogueOverlayState extends State<EnemyDialogueOverlay> {
  late List<String> _dialoguePages;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    // A szöveget a '|' karakter mentén feldaraboljuk, és eltávolítjuk a felesleges szóközöket
    _dialoguePages = widget.quote.split('|').map((s) => s.trim()).toList();
  }

  /// Kezeli a képernyőre vagy a gombra kattintást
  void _handleTap() {
    if (_currentPageIndex < _dialoguePages.length - 1) {
      // Ha van még oldal, csak lapozunk egyet
      setState(() {
        _currentPageIndex++;
      });
    } else {
      // Ha az utolsó oldalon vagyunk, bezárjuk az ablakot és indul a harc!
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Megnézzük, hogy ez-e az utolsó oldal, hogy a gomb szövegét dinamikusan cserélhessük
    final isLastPage = _currentPageIndex == _dialoguePages.length - 1;

    return GestureDetector(
      onTap: _handleTap, // Most már nem bezár azonnal, hanem a lapozót hívja
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black87,
        child: Stack(
          children: [
            // 1. RPG SZÖVEGDOBOZ
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.40,
                  top: 20,
                  right: 16,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D35).withOpacity(0.95),
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        offset: Offset(6, 6),
                        blurRadius: 0)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.enemyName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Divider(
                        color: Colors.white24, thickness: 2, height: 16),

                    // --- AKTUÁLIS OLDAL MEGJELENÍTÉSE ---
                    Text(
                      _dialoguePages[_currentPageIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- GOMB DINAMIKUS SZÖVEGGEL ---
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: _handleTap,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isLastPage ? "▼ KATTINTS A HARCHOZ ▼" : "▼ TOVÁBB ▼",
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. KARAKTER PORTRÉ
            Positioned(
              left: 0,
              bottom: 35,
              width: screenWidth * 0.40,
              height: screenHeight * 0.40,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/profile_pics/${widget.enemyId}.png',
                  alignment: Alignment.bottomCenter,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.help_outline,
                      color: Colors.red,
                      size: 100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
