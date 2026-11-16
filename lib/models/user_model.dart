// A felhasználói profil és az RPG karakterstatisztikák központi adatmodellje.
// Ez az osztály felelős a játékos előrehaladásának (XP, szint) és a
// harci attribútumoknak (erő, ügyesség, stb.) a kezeléséért, valamint
// a Firestore dokumentumok és a Flutter objektumok közötti szinkronizációért.

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;
  final int level;
  final String photoURL;
  final int xp;
  final String characterClass;

  // --- JÁTÉKMECHANIKAI ÉRTÉKEK (RPG STATS) ---
  final int statPoints; // Szintlépéskor kapott, még el nem osztott pontok
  final int vitality; // Életerő (HP) skálázás alapja
  final int strength; // Fizikai sebzés (Knight) és védelem módosítója
  final int intellect; // Mágikus erő (Necromancer) alapja
  final int agility; // Kitérési esély (Archer) és sebesség
  final int luck; // Kritikus találati esély és szerencse faktor

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.level = 1,
    this.photoURL = '',
    this.xp = 0,
    this.characterClass = 'knight',
    this.statPoints = 0,
    this.vitality = 1,
    this.strength = 1,
    this.intellect = 1,
    this.agility = 1,
    this.luck = 1,
  });

  /// Adatok [Map] formátumba alakítása a Firestore-ba történő mentéshez vagy frissítéshez.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': createdAt,
      'level': level,
      'photoURL': photoURL,
      'total_xp': xp,
      'characterClass': characterClass,
      'statPoints': statPoints,
      'vitality': vitality,
      'strength': strength,
      'intellect': intellect,
      'agility': agility,
      'luck': luck,
    };
  }

  /// Modell létrehozása Firestore dokumentumból (Map) érkező adatok alapján.
  /// Tartalmaz egy robusztus dátumkezelőt, amely kezeli a Firebase [Timestamp] típust is.
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;

    // Rugalmas dátum-parzolás: Timestamp (Firebase) vagy int (milliszekundum) formátumból
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      username: map['username'] ?? 'Ismeretlen',
      createdAt: parsedDate,
      level: map['level']?.toInt() ?? 1,
      photoURL: map['photoURL'] ?? '',
      xp: map['total_xp']?.toInt() ?? 0,
      characterClass: map['characterClass'] ?? 'knight',
      statPoints: map['statPoints']?.toInt() ?? 0,
      vitality: map['vitality']?.toInt() ?? 1,
      strength: map['strength']?.toInt() ?? 1,
      intellect: map['intellect']?.toInt() ?? 1,
      agility: map['agility']?.toInt() ?? 1,
      luck: map['luck']?.toInt() ?? 1,
    );
  }
}
