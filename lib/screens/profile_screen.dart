//
// ProfileScreen - Karakterlap képernyő
//
// Ez a képernyő felelős a felhasználó karakterének adatainak (név, kaszt, szint, statisztikák, profilkép)
// megjelenítéséért, módosításáért, valamint a statisztikák elosztásáért, profilkép és beállítások kezeléséért.
//
// Fő funkciók:
// - Felhasználói adatok betöltése Firestore-ból
// - Statisztikák, szint, XP, profilkép megjelenítése
// - Statisztikák elosztása, bónuszok számítása
// - Profilkép választás
// - Felhasználónév/jelszó módosítás
// - Kijelentkezés
//
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';

// Karakterlap képernyő: statisztikák kezelése, szintlépés és profilkép módosítása
/// Karakterlap képernyő fő widget
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Karakterlap képernyő állapotkezelője
class _ProfileScreenState extends State<ProfileScreen> {
  /// Felhasználónév
  String _username = "Betöltés...";

  /// Karakterosztály (pl. knight, necromancer, archer)
  String _characterClass = 'knight';

  /// Jelenlegi szint
  int _level = 1;

  /// Jelenlegi XP
  int _currentXp = 0;

  /// Profilkép elérési útja
  String _avatar = 'assets/images/profile_pics/avatar0.png';

  /// Betöltés állapota (adatok töltésekor true)
  bool _isLoading = true;

  // RPG Statisztikák alapértékei
  /// Elosztható statisztika pontok száma
  int _statPoints = 0;

  /// Életerő szintje
  int _vitality = 1;

  /// Erő szintje
  int _strength = 1;

  /// Intelligencia szintje
  int _intellect = 1;

  /// Gyorsaság szintje
  int _agility = 1;

  /// Szerencse szintje
  int _luck = 1;

  // Választható pixel art profilképek listája
  /// Választható pixel art profilképek listája
  final List<String> _availableAvatars = [
    'assets/images/profile_pics/avatar1.png',
    'assets/images/profile_pics/avatar2.png',
    'assets/images/profile_pics/avatar3.png',
    'assets/images/profile_pics/avatar4.png',
    'assets/images/profile_pics/avatar5.png',
    'assets/images/profile_pics/avatar6.png',
    'assets/images/profile_pics/avatar7.png',
    'assets/images/profile_pics/avatar8.png',
    'assets/images/profile_pics/avatar9.png',
  ];

  // RPG/Pixel Art Színpaletta
  /// Háttérszín (sötét)
  static const Color bgDark = Color(0xFF0F0F1B);

  /// Panel háttérszín
  static const Color panelBg = Color(0xFF1D1D35);

  /// Kiemelő arany szín
  static const Color accentGold = Color(0xFFFFD700);

  /// Panel szegély színe
  static const Color borderSide = Color(0xFF3E3E63);

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Adatok betöltése indításkor
  }

  /// Felhasználói adatok lekérése a Firestore-ból és state frissítése
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _username = data['username'] ?? "Névtelen Hős";
            _characterClass = data['characterClass'] ?? 'knight';
            _level = data['level'] ?? 1;
            _currentXp = data['total_xp'] ?? 0;
            _statPoints = data['statPoints'] ?? 0;
            _vitality = data['vitality'] ?? 1;
            _strength = data['strength'] ?? 1;
            _intellect = data['intellect'] ?? 1;
            _agility = data['agility'] ?? 1;
            _luck = data['luck'] ?? 1;
            _avatar =
                data['avatar'] ?? 'assets/images/profile_pics/avatar0.png';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Kiszámolja az adott statisztika bónuszát a karakterosztály alapján
  /// pl. HP, ATK, DEF, stb. visszaadása
  String _getStatCurrentBonus(String statKey, int value) {
    switch (statKey) {
      case 'vitality':
        int hpMult = (_characterClass == 'knight')
            ? 15
            : (_characterClass == 'necromancer' ? 12 : 10);
        return "+${50 + (value * hpMult)} MAX HP";
      case 'strength':
        if (_characterClass == 'knight') {
          return "+${(value * 2.0).round()} ATK | ${(value / 2).toStringAsFixed(1)} DEF";
        }
        return "+${(value / 2).toStringAsFixed(1)} DEF";
      case 'intellect':
        if (_characterClass == 'necromancer') {
          return "+${(value * 2.5).round()} MAG | ${(value / 2).toStringAsFixed(1)} RES";
        }
        return "+${(value / 2).toStringAsFixed(1)} RES";
      case 'agility':
        if (_characterClass == 'archer') {
          return "+${(value * 1.8).round()} RNG | ${(value / 2).toStringAsFixed(1)} EVA";
        }
        return "+${(value / 2).toStringAsFixed(1)} EVA";
      case 'luck':
        double critMult = (_characterClass == 'archer')
            ? 0.3
            : (_characterClass == 'necromancer' ? 0.2 : 0.1);
        return "+${(value * critMult).toStringAsFixed(1)}% CRIT CHANCE";
      default:
        return "";
    }
  }

  /// Statisztika leírását megjelenítő dialógus
  /// Segítség szöveg megjelenítése az adott statisztikához
  void _showStatHelp(String statKey, String statName) {
    String helpText = "";
    switch (statKey) {
      case 'vitality':
        helpText = "Növeli az életerőt. A Lovagok számára kiemelten fontos.";
        break;
      case 'strength':
        helpText = "Fizikai erő és védelem. A Lovag fő statisztikája.";
        break;
      case 'intellect':
        helpText = "Mágikus erő és ellenállás. A Necromancer alapja.";
        break;
      case 'agility':
        helpText = "Gyorsaság és kitérés. Az Íjász fő statisztikája.";
        break;
      case 'luck':
        helpText = "Kritikus találati esély minden kaszt számára.";
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: panelBg,
        shape: const Border(
            top: BorderSide(color: accentGold, width: 4),
            bottom: BorderSide(color: accentGold, width: 4),
            left: BorderSide(color: accentGold, width: 4),
            right: BorderSide(color: accentGold, width: 4)),
        title: Text(statName.toUpperCase(),
            style: const TextStyle(
                color: accentGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        content: Text(helpText,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontFamily: 'monospace')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("[ OK ]",
                  style: TextStyle(
                      color: accentGold, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  /// Elosztható stat pontok elköltése, Firestore frissítése
  Future<void> _allocateStat(String statName) async {
    if (_statPoints <= 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _statPoints--;
      if (statName == 'vitality') _vitality++;
      if (statName == 'strength') _strength++;
      if (statName == 'intellect') _intellect++;
      if (statName == 'agility') _agility++;
      if (statName == 'luck') _luck++;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'statPoints': _statPoints,
      statName: FieldValue.increment(1),
    });
  }

  /// Fő build metódus: teljes karakterlap felépítése
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: bgDark,
          body: Center(child: CircularProgressIndicator(color: accentGold)));
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: bgDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: accentGold),
                tooltip: 'Settings',
                onPressed: _showSettingsMenu, // Ez hívja meg az új menüt
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xFF252545), bgDark],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter))),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(color: accentGold, width: 3),
                                color: Colors.black),
                            child: Image.asset(_avatar,
                                width: 80, height: 80, fit: BoxFit.contain),
                          ),
                          GestureDetector(
                              onTap: _showAvatarPicker,
                              child: Container(
                                  color: accentGold,
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.edit,
                                      size: 14, color: Colors.black))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_username.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      Text("CLASS: ${_characterClass.toUpperCase()}",
                          style: const TextStyle(
                              color: accentGold,
                              letterSpacing: 2,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  _buildXpCard(), // Szint és tapasztalati pont csík
                  const SizedBox(height: 16),
                  _buildStatPanel(), // Statisztikák elosztása panel
                  const SizedBox(height: 24),
                  _buildLogoutButton(), // Kijelentkezés
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// XP és szint megjelenítő widget
  Widget _buildXpCard() {
    int xpNeeded = _level * 100;
    double progress = (_currentXp / xpNeeded).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: panelBg, border: Border.all(color: borderSide, width: 2)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("LVL $_level",
                  style: const TextStyle(
                      color: accentGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text("XP: $_currentXp / $xpNeeded",
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: borderSide, width: 1))),
              FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 14, color: Colors.blueAccent)),
            ],
          ),
        ],
      ),
    );
  }

  /// Statisztika panel építése, statisztikák listázása
  Widget _buildStatPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: panelBg, border: Border.all(color: borderSide, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CHARACTER STATS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: _statPoints > 0
                    ? Colors.green.withOpacity(0.2)
                    : Colors.black12,
                child: Text("POINTS: $_statPoints",
                    style: TextStyle(
                        color: _statPoints > 0
                            ? Colors.greenAccent
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: borderSide, height: 24),
          _buildStatRow("VIT", _getStatCurrentBonus('vitality', _vitality),
              _vitality, 'vitality', Colors.redAccent),
          _buildStatRow("STR", _getStatCurrentBonus('strength', _strength),
              _strength, 'strength', Colors.orangeAccent),
          _buildStatRow("INT", _getStatCurrentBonus('intellect', _intellect),
              _intellect, 'intellect', Colors.blueAccent),
          _buildStatRow("AGI", _getStatCurrentBonus('agility', _agility),
              _agility, 'agility', Colors.greenAccent),
          _buildStatRow("LUK", _getStatCurrentBonus('luck', _luck), _luck,
              'luck', Colors.purpleAccent),
        ],
      ),
    );
  }

  /// Egyedi statisztika sor gombbal és leírással
  /// Egy statisztika sorának felépítése, bónusz, érték, növelés gomb
  Widget _buildStatRow(
      String name, String effect, int value, String key, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showStatHelp(key, name),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.5)),
                  color: Colors.black26),
              child: Center(
                  child: Text(name,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("LEVEL: $value",
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(effect,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          if (_statPoints > 0)
            GestureDetector(
              onTap: () => _allocateStat(key),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent),
                    color: Colors.black26),
                child:
                    const Icon(Icons.add, color: Colors.greenAccent, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// Kilépés gomb stílusos kerettel, kijelentkeztet a felhasználót
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: MaterialButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (c) => const AuthScreen()));
        },
        color: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        shape: const Border(
            top: BorderSide(color: Colors.redAccent),
            bottom: BorderSide(color: Colors.redAccent),
            left: BorderSide(color: Colors.redAccent),
            right: BorderSide(color: Colors.redAccent)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Text("QUIT TO MENU",
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
    );
  }

  /// Profilkép választó modal ablak megjelenítése
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: accentGold, width: 4))),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15),
          itemCount: _availableAvatars.length,
          itemBuilder: (context, i) => GestureDetector(
            onTap: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({'avatar': _availableAvatars[i]});
              setState(() => _avatar = _availableAvatars[i]);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: borderSide, width: 2),
                  color: panelBg),
              child: Image.asset(_availableAvatars[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  /// Beállítások főmenü dialógus megjelenítése
  void _showSettingsMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: panelBg,
        shape: const Border(
            top: BorderSide(color: accentGold, width: 4),
            bottom: BorderSide(color: accentGold, width: 4),
            left: BorderSide(color: accentGold, width: 4),
            right: BorderSide(color: accentGold, width: 4)),
        title: const Text('SETTINGS',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: accentGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsOption("CHANGE USERNAME", Icons.person, () {
              Navigator.pop(context); // Bezárja a főmenüt
              _showChangeUsernameDialog(); // Megnyitja a névcserét
            }),
            const SizedBox(height: 15),
            _buildSettingsOption("CHANGE PASSWORD", Icons.key, () {
              Navigator.pop(context);
              _showChangePasswordDialog();
            }),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("[ CLOSE ]",
                  style: TextStyle(
                      color: Colors.white54, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  /// Segéd widget a beállítások menü opcióihoz
  Widget _buildSettingsOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderSide, width: 2),
          color: Colors.black26,
        ),
        child: Row(
          children: [
            Icon(icon, color: accentGold, size: 20),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  /// Felhasználónév változtató dialógus megjelenítése
  void _showChangeUsernameDialog() {
    final TextEditingController nameController =
        TextEditingController(text: _username);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: panelBg,
            shape: Border.all(color: accentGold, width: 4),
            title: const Text('NEW IDENTITY',
                style: TextStyle(color: accentGold, letterSpacing: 1)),
            content: isSaving
                ? const SizedBox(
                    height: 50,
                    child: Center(
                        child: CircularProgressIndicator(color: accentGold)))
                : TextField(
                    controller: nameController,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: "Enter new username...",
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderSide)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentGold)),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                  ),
            actions: isSaving
                ? []
                : [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("[ CANCEL ]",
                            style: TextStyle(color: Colors.white54))),
                    TextButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty || newName == _username) return;

                        setStateDialog(() => isSaving = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Firestore frissítése
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'username': newName});

                            // UI frissítése
                            if (!mounted) return;
                            setState(() => _username = newName);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'IDENTITY UPDATED!',
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('UPDATE FAILED!'),
                                backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: const Text("[ SAVE ]",
                          style: TextStyle(color: accentGold)),
                    ),
                  ],
          );
        },
      ),
    );
  }

  /// Jelszóváltoztató dialógus megjelenítése
  void _showChangePasswordDialog() {
    final TextEditingController passController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: panelBg,
            shape: Border.all(color: accentGold, width: 4),
            title: const Text('FORGE NEW KEY',
                style: TextStyle(color: accentGold, letterSpacing: 1)),
            content: isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(
                        child: CircularProgressIndicator(color: accentGold)))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(errorMessage!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12)),
                        ),
                      TextField(
                        controller: passController,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: "New Password...",
                          hintStyle: TextStyle(color: Colors.white24),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderSide)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accentGold)),
                          filled: true,
                          fillColor: Colors.black26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: "Confirm Password...",
                          hintStyle: TextStyle(color: Colors.white24),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderSide)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accentGold)),
                          filled: true,
                          fillColor: Colors.black26,
                        ),
                      ),
                    ],
                  ),
            actions: isSaving
                ? []
                : [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("[ CANCEL ]",
                            style: TextStyle(color: Colors.white54))),
                    TextButton(
                      onPressed: () async {
                        final pass = passController.text;
                        final confirm = confirmController.text;

                        if (pass.length < 8) {
                          setStateDialog(
                              () => errorMessage = "TOO WEAK! (MIN 8 CHARS)");
                          return;
                        }
                        if (pass != confirm) {
                          setStateDialog(
                              () => errorMessage = "KEYS DO NOT MATCH!");
                          return;
                        }

                        setStateDialog(() {
                          isSaving = true;
                          errorMessage = null;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Jelszó csere a Firebase Auth-ban
                            await user.updatePassword(pass);

                            if (!context.mounted) return;

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'PASSWORD UPDATED!',
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setStateDialog(() {
                            isSaving = false;
                            // Ha a felhasználó régóta be van jelentkezve, a Firebase biztonsági okokból kérhet egy újra-bejelentkezést
                            if (e.code == 'requires-recent-login') {
                              errorMessage =
                                  "ERROR: LOG OUT AND LOG IN AGAIN TO CHANGE KEY!";
                            } else {
                              errorMessage =
                                  e.message?.toUpperCase() ?? "UPDATE FAILED!";
                            }
                          });
                        } catch (e) {
                          setStateDialog(() {
                            isSaving = false;
                            errorMessage = "SYSTEM ERROR OCCURRED.";
                          });
                        }
                      },
                      child: const Text("[ FORGE ]",
                          style: TextStyle(color: accentGold)),
                    ),
                  ],
          );
        },
      ),
    );
  }
}
