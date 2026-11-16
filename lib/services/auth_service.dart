// Ez a szolgáltatás felelős a Firebase Authentication folyamatok kezeléséért.
// Lehetővé teszi a regisztrációt, a kijelentkezést, valamint egy egyedi
// bejelentkezési logikát, amely email cím helyett felhasználónevet használ.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // A Firebase Authentication és a Firestore adatbázis központi példányainak elérése
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Visszaadja az aktuálisan hitelesített felhasználót, vagy null-t, ha senki nincs belépve.
  User? get currentUser => _auth.currentUser;

  /// Egy Stream, amely folyamatosan figyeli a felhasználó állapotát (belépés/kilépés).
  /// Ezt használja a UI a megfelelő képernyő (Auth vagy Home) automatikus kiválasztásához.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Bejelentkezés egyedi felhasználónév (Username) alapján.
  /// Mivel a Firebase Auth emailt vár, ez a függvény először a Firestore-ban megkeresi
  /// az adott felhasználónévhez tartozó email címet.
  /// [username]: A játékos által megadott egyedi felhasználónév.
  /// [password]: A fiókhoz tartozó jelszó.
  Future<UserCredential?> signInWithUsername(
      String username, String password) async {
    try {
      // 1. LÉPÉS: Megkeressük a Firestore 'users' kollekciójában a dokumentumot, ahol a név egyezik
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1) // Hatékonyság: elég az első találat
          .get();

      // Ha nincs találat a keresett névre
      if (result.docs.isEmpty) {
        throw 'Nem található ilyen felhasználónév!';
      }

      // 2. LÉPÉS: Kinyerjük a megtalált felhasználó mentett email címét
      final String email = result.docs.first.get('email');

      // 3. LÉPÉS: A megszerzett emaillel és jelszóval elvégezzük a standard Firebase Auth bejelentkezést
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Speciális Firebase hibaüzenetek (pl. rossz jelszó) továbbítása
      throw e.message ?? 'Hiba történt a belépéskor.';
    } catch (e) {
      // Bármilyen egyéb hiba (pl. adatbázis elérés) kezelése
      throw e.toString();
    }
  }

  /// Új fiók létrehozása email és jelszó párossal.
  /// Megjegyzés: A regisztráció után a felhasználói profil (név, statok) mentése
  /// a FirestoreService-ben történik.
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Regisztrációs hibák kezelése (pl. foglalt email cím)
      throw e.message ?? 'Hiba történt a regisztrációkor.';
    }
  }

  /// Kijelentkezteti a felhasználót és megszünteti az aktív munkamenetet.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
