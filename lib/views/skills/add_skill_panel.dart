import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/skill_model.dart';

// Fungsi untuk menampilkan Panel
void showAddSkillPanel(BuildContext context, {SkillModel? skill}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      // Oper skill ke dalam panel
      return AddSkillPanel(skill: skill);
    },
    // Animasi kustom untuk panel
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

class AddSkillPanel extends StatefulWidget {
  // Tambahkan parameter skill opsional
  final SkillModel? skill;
  const AddSkillPanel({super.key, this.skill});

  @override
  State<AddSkillPanel> createState() => _AddSkillPanelState();
}

class _AddSkillPanelState extends State<AddSkillPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final SkillController _skillController = SkillController();

  final List<IconData> _icons = [
    Icons.code,
    Icons.book,
    Icons.fitness_center,
    Icons.music_note,
    Icons.brush,
    Icons.camera_alt,
    Icons.attach_money
  ];
  final List<Color> _colors = [
    const Color(0xFF8A63D2),
    Colors.lightBlue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];

  IconData _selectedIcon = Icons.code;
  Color _selectedColor = const Color(0xFF8A63D2);

  bool _isFormValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Jika ini adalah mode edit, isi form dengan data yang ada
    if (widget.skill != null) {
      _nameController.text = widget.skill!.name;
      _selectedIcon =
          IconData(int.parse(widget.skill!.icon), fontFamily: 'MaterialIcons');
      _selectedColor = Color(widget.skill!.color);
    }
    _nameController.addListener(() {
      setState(() {
        _isFormValid = _nameController.text.trim().isNotEmpty;
      });
    });
    // Langsung validasi saat pertama kali dibuka (untuk mode edit)
    _isFormValid = _nameController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- FUNGSI SUBMIT YANG DIPERBAIKI ---
  void _submit() async {
    if (!_isFormValid || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.skill != null) {
        // --- LOGIKA UPDATE ---
        final updatedSkill = SkillModel(
          id: widget.skill!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon.codePoint.toString(),
          color: _selectedColor.value,
          level: widget.skill!.level, // Data progresi tidak diubah di sini
          currentXp: widget.skill!.currentXp,
          xpForNextLevel: widget.skill!.xpForNextLevel,
          createdAt: widget.skill!.createdAt,
        );
        await _skillController.updateSkill(updatedSkill);
      } else {
        // --- LOGIKA ADD ---
        await _skillController.addSkill(
          name: _nameController.text.trim(),
          icon: _selectedIcon.codePoint.toString(),
          color: _selectedColor.value,
        );
      }

      if (mounted) {
        final action = widget.skill != null ? 'reforged' : 'forged';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Skill "${_nameController.text.trim()}" has been $action!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error creating skill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Could not create skill.')));
      }
    } finally {
      // Pastikan loading selalu berhenti, baik berhasil maupun gagal
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Animate(
          // Wrapper Animate untuk transisi keluar yang elegan
          effects: const [FadeEffect(), ScaleEffect(curve: Curves.easeIn)],
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      widget.skill != null ? 'Reforge Rune' : 'Ukir Rune Skill',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Nama Skill dengan kursor berwarna dinamis
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 18),
                    cursorColor: _selectedColor,
                    decoration: InputDecoration(
                      labelText: 'Nama Skill',
                      labelStyle: TextStyle(color: _selectedColor),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: _selectedColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pilih Sigil (Ikon)
                  const Text('Pilih Sigil',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _icons.map((icon) {
                      return _SigilButton(
                        icon: icon,
                        color: _selectedColor,
                        isSelected: _selectedIcon == icon,
                        onTap: () => setState(() => _selectedIcon = icon),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Berikan Esensi Warna
                  const Text('Berikan Esensi Warna',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _colors.map((color) {
                      return _ColorOrb(
                        color: color,
                        isSelected: _selectedColor == color,
                        onTap: () => setState(() => _selectedColor = color),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isFormValid && !_isLoading ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(widget.skill != null
                                ? 'Save Changes'
                                : 'Ukir Skill'),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// WIDGET KUSTOM UNTUK TOMBOL SIGIL BERBENTUK HEKSAGONAL
class _SigilButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SigilButton(
      {required this.icon,
      required this.color,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSelected ? color : Colors.grey.shade700;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected ? effectiveColor.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: effectiveColor, width: isSelected ? 2 : 1),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: effectiveColor)),
      ),
    );
  }
}

// WIDGET KUSTOM UNTUK ORB WARNA
class _ColorOrb extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOrb(
      {required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: isSelected ? 8 : 2,
              spreadRadius: isSelected ? 2 : 0,
            )
          ],
        ),
      ),
    );
  }
}
