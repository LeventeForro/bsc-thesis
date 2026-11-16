// Ez a fájl tárolja a Firebase projekt alapértelmezett konfigurációs beállításait.
// A FlutterFire CLI automatikusan generálja, és lehetővé teszi, hogy ugyanaz a kód
// különböző platformokon (Android, iOS, Web, Windows, macOS) a megfelelő Firebase apphoz kapcsolódjon.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Lekéri az aktuális platformhoz tartozó konfigurációt.
  /// A fő [main.dart] fájlban hívjuk meg a Firebase inicializálásakor.
  static FirebaseOptions get currentPlatform {
    // 1. LÉPÉS: Webes platform ellenőrzése
    if (kIsWeb) {
      return web;
    }

    // 2. LÉPÉS: Natív platformok azonosítása
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        // A Linux konfiguráció jelenleg hiányzik
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- PLATFORMSPECIFIKUS KONFIGURÁCIÓK ---
  // Ezeket az értékeket a Firebase Console generálja a projekthez.

  /// Webes alkalmazás konfigurációja.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAns429R9u7adRWg0u8LXtnl_k96_480nA',
    appId: '1:113772878695:web:a1d534bd5a326701dd2dc2',
    messagingSenderId: '113772878695',
    projectId: 'szakdolgozat-2026',
    authDomain: 'szakdolgozat-2026.firebaseapp.com',
    storageBucket: 'szakdolgozat-2026.firebasestorage.app',
  );

  /// Android alkalmazás konfigurációja.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1hOr9bidoU3cyGnA5hgWLQoa17s-LALE',
    appId: '1:113772878695:android:6955bce06205c003dd2dc2',
    messagingSenderId: '113772878695',
    projectId: 'szakdolgozat-2026',
    storageBucket: 'szakdolgozat-2026.firebasestorage.app',
  );

  /// iOS alkalmazás konfigurációja (szükség van a Bundle ID-ra is).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBljgLnFbDNzrVeVV9u7Ly8emQJo7h1h2I',
    appId: '1:113772878695:ios:479e757ca71d745add2dc2',
    messagingSenderId: '113772878695',
    projectId: 'szakdolgozat-2026',
    storageBucket: 'szakdolgozat-2026.firebasestorage.app',
    iosBundleId: 'com.example.szakdolgozat',
  );

  /// macOS alkalmazás konfigurációja (gyakran megegyezik az iOS beállításokkal).
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBljgLnFbDNzrVeVV9u7Ly8emQJo7h1h2I',
    appId: '1:113772878695:ios:479e757ca71d745add2dc2',
    messagingSenderId: '113772878695',
    projectId: 'szakdolgozat-2026',
    storageBucket: 'szakdolgozat-2026.firebasestorage.app',
    iosBundleId: 'com.example.szakdolgozat',
  );

  /// Windows asztali alkalmazás konfigurációja.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAns429R9u7adRWg0u8LXtnl_k96_480nA',
    appId: '1:113772878695:web:c6353efc8b68da0ddd2dc2',
    messagingSenderId: '113772878695',
    projectId: 'szakdolgozat-2026',
    authDomain: 'szakdolgozat-2026.firebaseapp.com',
    storageBucket: 'szakdolgozat-2026.firebasestorage.app',
  );
}
