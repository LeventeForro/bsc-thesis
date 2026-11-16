// Az autentikációs képernyő (Bejelentkezés és Regisztráció) megvalósítása.
// Ez a komponens kezeli a felhasználói belépést, az új fiókok létrehozását,
// valamint a jelszó-biztonsági validációt egy egyedi RPG/Pixel Art stílusú felületen.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:szakdolgozat/screens/character_selection_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true; // Üzemmód: true = Bejelentkezés, false = Regisztráció
  bool isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Modern Pixel Art RPG Színpaletta konstansok
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Szigorú jelszó-ellenőrző logika a biztonságos fiókok érdekében.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'PASSWORD IS REQUIRED!';
    }
    if (value.length < 8) {
      return 'TOO WEAK! (MIN 8 CHARS)';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'MUST CONTAIN UPPERCASE!';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'MUST CONTAIN LOWERCASE!';
    }
    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
      return 'MUST CONTAIN NUMBER!';
    }
    return null;
  }

  /// Az űrlap elküldésének kezelése: Firebase Auth és Firestore szinkronizáció.
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // Belépés felhasználónév és jelszó párossal
        await _authService.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        // Új fiók regisztrációja emaillel
        UserCredential? cred = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (cred != null && cred.user != null) {
          // Alapértelmezett RPG profil létrehozása az új felhasználónak
          UserModel newUser = UserModel(
            uid: cred.user!.uid,
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            createdAt: DateTime.now(),
            level: 1,
            xp: 0,
            statPoints: 0,
            vitality: 0,
            strength: 0,
            intellect: 0,
            agility: 0,
            luck: 0,
          );
          await FirestoreService().saveUser(newUser);
        }
      }

      // Navigáció a megfelelő képernyőre a művelet típusától függően
      if (mounted) {
        if (isLogin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          // Új regisztráció esetén kötelező a karakterválasztás
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const CharacterSelectionScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().toUpperCase(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                border: Border.all(color: borderSide, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, offset: Offset(8, 8)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RPG stílusú dinamikus fejléc
                      Text(
                        isLogin ? 'WELCOME BACK!' : 'CREATE NEW ACCOUNT',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: accentGold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 2, width: 60, color: accentGold),
                      const SizedBox(height: 30),

                      // Felhasználónév mező
                      _buildPixelTextField(
                        controller: _usernameController,
                        label: 'USERNAME',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value!.isEmpty ? 'IDENTIFY YOURSELF!' : null,
                      ),
                      const SizedBox(height: 20),

                      // Email mező (csak regisztrációnál jelenik meg)
                      if (!isLogin) ...[
                        _buildPixelTextField(
                          controller: _emailController,
                          label: 'EMAIL ADDRESS',
                          icon: Icons.mail_outline,
                          validator: (value) => !value!.contains('@')
                              ? 'INVALID COMM-LINK!'
                              : null,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Jelszó mező
                      _buildPixelTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        icon: Icons.key_outlined,
                        obscure: _obscurePassword,
                        isPassword: true,
                        onToggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: isLogin
                            ? (value) =>
                                value!.isEmpty ? 'ENTER YOUR KEY!' : null
                            : _validatePassword,
                        onSubmitted: isLogin
                            ? (_) {
                                FocusScope.of(context).unfocus();
                                _submitForm();
                              }
                            : null,
                      ),

                      // Jelszó megerősítése (csak regisztrációnál jelenik meg)
                      if (!isLogin) ...[
                        const SizedBox(height: 20),
                        _buildPixelTextField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRM PASSWORD',
                          icon: Icons.key_outlined,
                          obscure: _obscureConfirmPassword,
                          isPassword: true,
                          onToggleObscure: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'KEYS DO NOT MATCH!';
                            }
                            return null;
                          },
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                            _submitForm();
                          },
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Akciógomb (Pixel-border stílusban)
                      isLoading
                          ? const CircularProgressIndicator(color: accentGold)
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: MaterialButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  _submitForm();
                                },
                                color: accentGold,
                                elevation: 0,
                                highlightElevation: 0,
                                shape: const Border(
                                  top:
                                      BorderSide(color: Colors.white, width: 2),
                                  bottom:
                                      BorderSide(color: Colors.black, width: 4),
                                  left:
                                      BorderSide(color: Colors.white, width: 2),
                                  right:
                                      BorderSide(color: Colors.black, width: 4),
                                ),
                                child: Text(
                                  isLogin ? 'LOGIN' : 'REGISTER',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Üzemmódváltó gomb
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            isLogin = !isLogin;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            _obscurePassword = true;
                            _obscureConfirmPassword = true;
                          });
                        },
                        child: Text(
                          isLogin
                              ? '[ NEED A NEW HERO? ]'
                              : '[ ALREADY REGISTERED? ]',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Saját "Pixel" stílusú beviteli mező generátora.
  Widget _buildPixelTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: borderSide, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: obscure ? borderSide : accentGold,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: Colors.black26,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: borderSide, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: accentGold, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 10),
            errorMaxLines: 2,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
