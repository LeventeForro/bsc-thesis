// Karakterválasztó képernyő.
// Lehetővé teszi a három alapvető kaszt (Knight, Archer, Necromancer) egyikének kiválasztását.
// A döntés után a hős alapértelmezett statisztikái (Vitality, Strength, stb.)
// mentésre kerülnek a felhasználó felhő alapú profiljába.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../game/heroes/hero_registry.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  String? _selectedClass; // Tárolja az aktuálisan kijelölt kaszt azonosítóját
  bool _isLoading = false;

  // Stílus konstansok az egységes RPG látványvilághoz
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  /// Mentési folyamat: Lekéri a Registry-ből az alapértékeket és frissíti a Firestore dokumentumot.
  void _saveCharacterAndStart() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SELECT A CLASS TO CONTINUE!',
              style: TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // A HeroRegistry-ből kinyerjük a választott osztály specifikus statisztikáit
        Map<String, int> baseStats =
            HeroRegistry.getHero(_selectedClass!).baseStats;

        // Firestore frissítése: a karakterosztály és a statok rögzítése
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'characterClass': _selectedClass,
          'statPoints': 0,
          ...baseStats,
        });

        if (mounted) {
          // Sikeres mentés után a főmenübe ugrunk, a választót töröljük a navigációs veremből
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ERROR SAVING HERO: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CHOOSE YOUR HERO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'THIS CHOICE IS PERMANENT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),

              // A választható hősök kártyáinak listája
              _buildClassCard(
                'knight',
                'KNIGHT',
                Icons.shield,
                Colors.blueAccent,
                'High vitality and physical power.',
              ),
              const SizedBox(height: 16),
              _buildClassCard(
                'archer',
                'ARCHER',
                Icons.gps_fixed,
                Colors.greenAccent,
                'Unmatched agility and range.',
              ),
              const SizedBox(height: 16),
              _buildClassCard(
                'necromancer',
                'NECROMANCER',
                Icons.auto_fix_high,
                Colors.purpleAccent,
                'Master of intellect and dark arts.',
              ),

              const SizedBox(height: 50),

              // Indító gomb vagy töltésjelző
              _isLoading
                  ? const CircularProgressIndicator(color: accentGold)
                  : SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: MaterialButton(
                        color: accentGold,
                        elevation: 0,
                        shape: const Border(
                          top: BorderSide(color: Colors.white, width: 2),
                          bottom: BorderSide(color: Colors.black, width: 4),
                          left: BorderSide(color: Colors.white, width: 2),
                          right: BorderSide(color: Colors.black, width: 4),
                        ),
                        onPressed: _saveCharacterAndStart,
                        child: const Text(
                          'START ADVENTURE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// [Widget] - Egy osztály-választó kártyát generál vizuális visszajelzéssel.
  Widget _buildClassCard(
      String classId, String title, IconData icon, Color color, String desc) {
    bool isSelected = _selectedClass == classId;

    return GestureDetector(
      onTap: () => setState(() => _selectedClass = classId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : panelBg,
          border: Border.all(
            color: isSelected ? accentGold : borderSide,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            // Ikon és belső doboz
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? accentGold : borderSide),
                color: Colors.black26,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? color : Colors.white24,
              ),
            ),
            const SizedBox(width: 20),
            // Szöveges leírás
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc.toUpperCase(),
                    style: TextStyle(
                      color:
                          isSelected ? color.withOpacity(0.7) : Colors.white12,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_outline,
                  color: accentGold, size: 24),
          ],
        ),
      ),
    );
  }
}
