// Ez az alkalmazás belépési pontja.
// Felelős a Flutter és a Firebase inicializálásáért, valamint a felhasználó
// aktuális állapota alapján (bejelentkezett-e, van-e karaktere) a megfelelő kezdőképernyő kiválasztásáért.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/character_selection_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 1. LÉPÉS: A Flutter motor inicializálása.
  // Ez kötelező, mielőtt bármilyen aszinkron natív hívást (pl. Firebase) végeznénk.
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    // 2. LÉPÉS: A Firebase csatlakoztatása a projekthez a generált beállítások alapján.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Speciális hibakezelés: ha a Firebase már fut (pl. Hot Reload esetén), ne álljon le a program.
    if (!e.toString().contains('duplicate-app')) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {}
    }
  }

  // 3. LÉPÉS: Az alkalmazás gyökér widgetének elindítása.
  runApp(const QuestForKnowledge());
}

class QuestForKnowledge extends StatelessWidget {
  const QuestForKnowledge({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quest for Knowledge',
      debugShowCheckedModeBanner:
          false, // Eltávolítja a "Debug" feliratot a sarokból.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // A Google legújabb dizájnnyelvének aktiválása.
      ),

      // OKOS ÚTVONALVÁLASZTÓ (ROOT NAVIGATION)
      // Egy StreamBuilder-t használunk, amely folyamatosan figyeli, hogy van-e belépett felhasználó.
      home: StreamBuilder<User?>(
        stream: AuthService()
            .authStateChanges, // A Firebase Auth állapotváltozásait figyeli.
        builder: (context, snap) {
          // A) Állapot: Az alkalmazás még kérdezi a szervert a felhasználóról.
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // B) Állapot: Van bejelentkezett felhasználó (hasData).
          if (snap.hasData) {
            // Meg kell néznünk a Firestore adatbázisban, hogy befejezte-e a karakterkészítést.
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snap.data!.uid)
                  .get(),
              builder: (context, userSnap) {
                // Adatok lekérése közbeni várakozás (RPG stílusú háttérrel).
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF0F0F1B),
                    body: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFD700))),
                  );
                }

                // Ha létezik a profilja, megnézzük, választott-e már karakterosztályt.
                if (userSnap.hasData && userSnap.data!.exists) {
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;

                  // Ha nincs választott kaszt (pl. regisztráció után bezárta az appot), a karakterválasztóba küldjük.
                  if (userData == null || userData['characterClass'] == null) {
                    return const CharacterSelectionScreen();
                  }

                  // Minden adat rendben: irány a főmenü.
                  return const HomeScreen();
                }

                // Ha a felhasználó létezik az Auth-ban, de nincs dokumentuma a Firestore-ban.
                return const CharacterSelectionScreen();
              },
            );
          }

          // C) Állapot: Nincs bejelentkezett felhasználó -> Irány az autentikációs (Login/Register) ablak.
          return const AuthScreen();
        },
      ),
    );
  }
}
