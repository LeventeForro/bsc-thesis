// Kvízkártyák szerkesztésére és létrehozására szolgáló dialógus ablak.
// Ez a komponens biztosítja a vizuális szerkesztőfelületet a szerkesztők számára,
// támogatva a négy alapvető kártyatípust (feleletválasztós, többszörös választás, párosítás, kifejtős).

import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardEditorDialog extends StatefulWidget {
  final QuizCard? existingCard; // Ha null, akkor új kártyát hozunk létre

  const CardEditorDialog({super.key, this.existingCard});

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  String _selectedType = 'multiple_choice';
  final _questionController = TextEditingController();

  // RPG/Pixel Art vizuális stílus konstansai
  static const Color bgDark = Color(0xFF0F0F1B);
  static const Color panelBg = Color(0xFF1D1D35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color borderSide = Color(0xFF3E3E63);

  // Dinamikus vezérlők a különböző kártyatípusok bemeneteihez
  final List<TextEditingController> _optionsControllers = [];
  int _correctOptionIndex = 0;

  final List<TextEditingController> _multiSelectOptions = [];
  final List<bool> _multiSelectCorrects = [];

  final List<TextEditingController> _shortAnswerControllers = [];
  final List<List<TextEditingController>> _matchingControllers = [];

  @override
  void initState() {
    super.initState();

    // Alapértelmezett üres beviteli mezők inicializálása
    _optionsControllers
        .addAll([TextEditingController(), TextEditingController()]);
    _multiSelectOptions
        .addAll([TextEditingController(), TextEditingController()]);
    _multiSelectCorrects.addAll([false, false]);
    _shortAnswerControllers.add(TextEditingController());
    _matchingControllers.addAll([
      [TextEditingController(), TextEditingController()],
      [TextEditingController(), TextEditingController()]
    ]);

    // Ha szerkesztési módban vagyunk, feltöltjük a mezőket a meglévő adatokkal
    if (widget.existingCard != null) {
      final card = widget.existingCard!;
      _selectedType = card.type;
      _questionController.text = card.question;

      if (card is MultipleChoiceCard) {
        _optionsControllers.clear();
        for (var opt in card.options) {
          _optionsControllers.add(TextEditingController(text: opt));
        }
        _correctOptionIndex = card.correctIndex;
      } else if (card is MultipleSelectCard) {
        _multiSelectOptions.clear();
        _multiSelectCorrects.clear();
        for (int i = 0; i < card.options.length; i++) {
          _multiSelectOptions.add(TextEditingController(text: card.options[i]));
          _multiSelectCorrects.add(card.correct.contains(i));
        }
      } else if (card is ShortAnswerCard) {
        _shortAnswerControllers.clear();
        for (var ans in card.answers) {
          _shortAnswerControllers.add(TextEditingController(text: ans));
        }
      } else if (card is MatchingCard) {
        _matchingControllers.clear();
        card.pairs.forEach((key, value) {
          _matchingControllers.add([
            TextEditingController(text: key),
            TextEditingController(text: value)
          ]);
        });
      }
    }
  }

  @override
  void dispose() {
    // Erőforrások felszabadítása a memóriaszivárgás elkerülése érdekében
    _questionController.dispose();
    for (var c in _optionsControllers) {
      c.dispose();
    }
    for (var c in _shortAnswerControllers) {
      c.dispose();
    }
    for (var pair in _matchingControllers) {
      pair[0].dispose();
      pair[1].dispose();
    }
    for (var c in _multiSelectOptions) {
      c.dispose();
    }
    super.dispose();
  }

  /// A kártya adatainak ellenőrzése és mentése.
  /// Összeállítja a megfelelő [QuizCard] alosztályt a beírt adatok alapján.
  void _saveCard() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("EMPTY QUESTION FIELD!",
              style: TextStyle(fontFamily: 'monospace'))));
      return;
    }

    final String id = widget.existingCard?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    QuizCard? newCard;

    // Típus-specifikus objektum-összeállítás
    if (_selectedType == 'multiple_choice') {
      List<String> validOptions = _optionsControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (validOptions.length < 2) return;
      newCard = MultipleChoiceCard(
        id: id,
        question: _questionController.text,
        order: widget.existingCard?.order ?? 0,
        options: validOptions,
        correctIndex: _correctOptionIndex >= validOptions.length
            ? 0
            : _correctOptionIndex,
      );
    } else if (_selectedType == 'short_answer') {
      List<String> validAnswers = _shortAnswerControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (validAnswers.isEmpty) return;
      newCard = ShortAnswerCard(
        id: id,
        question: _questionController.text,
        order: widget.existingCard?.order ?? 0,
        answers: validAnswers,
      );
    } else if (_selectedType == 'multiple_select') {
      List<String> finalOptions = [];
      List<int> correctIndices = [];
      for (int i = 0; i < _multiSelectOptions.length; i++) {
        String text = _multiSelectOptions[i].text.trim();
        if (text.isNotEmpty) {
          finalOptions.add(text);
          if (_multiSelectCorrects[i]) {
            correctIndices.add(finalOptions.length - 1);
          }
        }
      }
      if (finalOptions.length < 2 || correctIndices.isEmpty) return;
      newCard = MultipleSelectCard(
        id: id,
        question: _questionController.text,
        order: widget.existingCard?.order ?? 0,
        options: finalOptions,
        correct: correctIndices,
      );
    } else if (_selectedType == 'matching') {
      Map<String, String> pairs = {};
      for (var pair in _matchingControllers) {
        String left = pair[0].text.trim();
        String right = pair[1].text.trim();
        if (left.isNotEmpty && right.isNotEmpty) pairs[left] = right;
      }
      if (pairs.length < 2) return;
      newCard = MatchingCard(
        id: id,
        question: _questionController.text,
        order: widget.existingCard?.order ?? 0,
        pairs: pairs,
      );
    }

    if (newCard != null) Navigator.of(context).pop(newCard);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingCard != null;

    // A GestureDetector biztosítja, hogy a képernyő bármely
    // üres pontjára kattintva a billentyűzet eltűnjön.
    return GestureDetector(
      onTap: () {
        // Leveszi a fókuszt az éppen aktív TextFielDről -> eltűnik a billentyűzet
        FocusScope.of(context).unfocus();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgDark,
            border: Border.all(color: accentGold, width: 3),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // FEJLÉC: Cím és Típusválasztó Dropdown
              Row(
                children: [
                  const Icon(Icons.auto_stories, color: accentGold, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? "EDIT QUEST" : "SCRIBE NEW QUEST",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 16),
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: panelBg),
                    child: DropdownButton<String>(
                      value: _selectedType,
                      style: const TextStyle(
                          color: accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      underline: Container(),
                      icon:
                          const Icon(Icons.arrow_drop_down, color: accentGold),
                      items: const [
                        DropdownMenuItem(
                            value: 'multiple_choice',
                            child: Text("MULTIPLE CHOICE")),
                        DropdownMenuItem(
                            value: 'multiple_select',
                            child: Text("MULTIPLE SELECT")),
                        DropdownMenuItem(
                            value: 'matching', child: Text("MATCHING")),
                        DropdownMenuItem(
                            value: 'short_answer', child: Text("SHORT ANSWER")),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                  ),
                ],
              ),
              const Divider(color: borderSide, thickness: 2, height: 24),

              // KÉRDÉS SZÖVEGE (Textfield)
              _buildStyledTextField(
                controller: _questionController,
                hint: "Enter your question here...",
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // DINAMIKUS SZERKESZTŐ FELÜLET (Típusfüggő tartalom)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: borderSide),
                  ),
                  child: SingleChildScrollView(
                    child: _buildEditorContent(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ALSÓ VEZÉRLŐ GOMBOK (Cancel / Forge)
              Row(
                children: [
                  Expanded(
                    child: _buildPixelButton(
                      label: "CANCEL",
                      color: Colors.white24,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildPixelButton(
                      label: isEditing ? "UPDATE RUNE" : "FORGE CARD",
                      color: accentGold,
                      textColor: Colors.black,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _saveCard();
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET ÉPÍTŐ METÓDUSOK ---

  Widget _buildEditorContent() {
    if (_selectedType == 'multiple_choice') return _buildMultipleChoiceEditor();
    if (_selectedType == 'multiple_select') return _buildMultipleSelectEditor();
    if (_selectedType == 'matching') return _buildMatchingEditor();
    if (_selectedType == 'short_answer') return _buildShortAnswerEditor();
    return Container();
  }

  Widget _buildStyledTextField(
      {required TextEditingController controller,
      required String hint,
      int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
          color: Colors.white, fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint.toUpperCase(),
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 11),
        filled: true,
        fillColor: panelBg,
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: borderSide),
            borderRadius: BorderRadius.zero),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: accentGold),
            borderRadius: BorderRadius.zero),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildPixelButton(
      {required String label,
      required Color color,
      Color textColor = Colors.white,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  // SZERKESZTŐI AL-FELÜLETEK (A, B, C, D)

  Widget _buildMultipleChoiceEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT THE TRUTH:",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_optionsControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: _correctOptionIndex,
                  activeColor: accentGold,
                  onChanged: (val) =>
                      setState(() => _correctOptionIndex = val!),
                ),
                Expanded(
                    child: _buildStyledTextField(
                        controller: _optionsControllers[index],
                        hint: "Option ${index + 1}")),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent, size: 18),
                  onPressed: () => setState(() {
                    if (_optionsControllers.length > 2) {
                      _optionsControllers.removeAt(index);
                    }
                  }),
                ),
              ],
            ),
          );
        }),
        _buildAddAction(() =>
            setState(() => _optionsControllers.add(TextEditingController()))),
      ],
    );
  }

  Widget _buildMultipleSelectEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT ALL VALID ANSWERS:",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_multiSelectOptions.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _multiSelectCorrects[index],
                  activeColor: accentGold,
                  checkColor: Colors.black,
                  onChanged: (val) => setState(
                      () => _multiSelectCorrects[index] = val ?? false),
                ),
                Expanded(
                    child: _buildStyledTextField(
                        controller: _multiSelectOptions[index],
                        hint: "Option ${index + 1}")),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent, size: 18),
                  onPressed: () => setState(() {
                    if (_multiSelectOptions.length > 2) {
                      _multiSelectOptions.removeAt(index);
                      _multiSelectCorrects.removeAt(index);
                    }
                  }),
                ),
              ],
            ),
          );
        }),
        _buildAddAction(() => setState(() {
              _multiSelectOptions.add(TextEditingController());
              _multiSelectCorrects.add(false);
            })),
      ],
    );
  }

  Widget _buildShortAnswerEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACCEPTED ANSWERS (CASE INSENSITIVE):",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_shortAnswerControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                    child: _buildStyledTextField(
                        controller: _shortAnswerControllers[index],
                        hint: "Variation ${index + 1}")),
                if (_shortAnswerControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent, size: 18),
                    onPressed: () =>
                        setState(() => _shortAnswerControllers.removeAt(index)),
                  ),
              ],
            ),
          );
        }),
        _buildAddAction(() => setState(
            () => _shortAnswerControllers.add(TextEditingController()))),
      ],
    );
  }

  Widget _buildMatchingEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LINK THE ELEMENTS:",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_matchingControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                    child: _buildStyledTextField(
                        controller: _matchingControllers[index][0],
                        hint: "Key")),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.link, color: accentGold, size: 16)),
                Expanded(
                    child: _buildStyledTextField(
                        controller: _matchingControllers[index][1],
                        hint: "Value")),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent, size: 18),
                  onPressed: () => setState(() {
                    if (_matchingControllers.length > 2) {
                      _matchingControllers.removeAt(index);
                    }
                  }),
                ),
              ],
            ),
          );
        }),
        _buildAddAction(() => setState(() => _matchingControllers
            .add([TextEditingController(), TextEditingController()]))),
      ],
    );
  }

  Widget _buildAddAction(VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, color: accentGold, size: 16),
      label: const Text("ADD NEW SLOT",
          style: TextStyle(
              color: accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
