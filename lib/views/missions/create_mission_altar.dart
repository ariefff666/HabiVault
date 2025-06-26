import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Fungsi untuk menampilkan Altar
void showCreateMissionAltar(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CreateMissionAltar(),
  );
}

// Widget utama yang hanya bertugas mengambil data skill
class CreateMissionAltar extends StatelessWidget {
  const CreateMissionAltar({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder dipindahkan ke sini, di level tertinggi.
    return StreamBuilder<List<SkillModel>>(
      stream: SkillController().getSkills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan loading screen yang lebih baik saat pertama kali
          return const Center(child: CircularProgressIndicator());
        }

        final skills = snapshot.data ?? [];

        // Setelah data didapat, kita berikan ke widget form
        return _MissionFormSheet(skills: skills);
      },
    );
  }
}

// WIDGET BARU YANG MENANGANI TAMPILAN DAN STATE FORM
class _MissionFormSheet extends StatefulWidget {
  final List<SkillModel> skills;
  const _MissionFormSheet({required this.skills});

  @override
  State<_MissionFormSheet> createState() => _MissionFormSheetState();
}

class _MissionFormSheetState extends State<_MissionFormSheet> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // State untuk semua field
  String? _selectedSkillId;
  double _currentXp = 25.0;
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _hasDuration = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateForm);
  }

  void _validateForm() {
    final bool isTitleValid = _titleController.text.isNotEmpty;
    final bool isSkillValid = _selectedSkillId != null;
    final bool isDaysValid = _selectedDays.contains(true);
    final bool isDurationValid =
        !_hasDuration || (_hasDuration && _durationController.text.isNotEmpty);

    if (_isFormValid !=
        (isTitleValid && isSkillValid && isDaysValid && isDurationValid)) {
      setState(() {
        _isFormValid =
            isTitleValid && isSkillValid && isDaysValid && isDurationValid;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateForm);
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _xpLabel {
    if (_currentXp < 30) return 'Santai';
    if (_currentXp < 60) return 'Tantangan Harian';
    if (_currentXp < 90) return 'Fokus Mendalam';
    return 'Upaya Heroik';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {/* ... (akan kita implementasikan) ... */}

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colors.surface.withOpacity(0.85)
                        : const Color(0xFFF8F7F2).withOpacity(0.95),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                        child: Column(
                          children: [
                            Container(
                                height: 5,
                                width: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade600,
                                    borderRadius: BorderRadius.circular(12))),
                            const SizedBox(height: 16),
                            const Text('Altar Penciptaan Misi',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          children: [
                            const SizedBox(height: 24),
                            _buildSectionTitle('1. Definisikan Esensi Misi'),
                            const SizedBox(height: 16),
                            _buildPulsingTextField(),
                            const SizedBox(height: 24),
                            // Bagian ini sekarang tidak lagi menyebabkan refresh
                            _buildSkillSelector(),
                            const SizedBox(height: 32),
                            _buildSectionTitle(
                                '2. Tentukan Tantangan & Imbalan'),
                            const SizedBox(height: 16),
                            _buildXpSlider(),
                            const SizedBox(height: 32),
                            _buildSectionTitle('3. Ikat Janji dengan Waktu'),
                            const SizedBox(height: 16),
                            _buildDaySelector(),
                            const SizedBox(height: 24),
                            _buildTimeAndDuration(),
                            const SizedBox(height: 32),
                            _buildSectionTitle(
                                '4. Catatan Tambahan (Opsional)'),
                            const SizedBox(height: 16),
                            _buildNotesField(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: _buildSubmitButton(),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold))
      .animate()
      .fadeIn(delay: 300.ms);

  Widget _buildPulsingTextField() => TextFormField(
        controller: _titleController,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: 'Judul Misi...',
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade700, width: 1)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 2)),
        ),
        validator: (v) => v!.isEmpty ? "Judul tidak boleh kosong" : null,
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);

  // --- WIDGET-WIDGET BAGIAN FORM ---
  Widget _buildSkillSelector() {
    if (widget.skills.isEmpty) {
      return _buildNoSkillCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hubungkan ke Skill:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: [
            ...widget.skills.map((skill) {
              final isSelected = _selectedSkillId == skill.id;
              return ChoiceChip(
                label: Text(skill.name),
                avatar: Icon(Icons.shield,
                    size: 16,
                    color: isSelected ? Colors.white : Color(skill.color)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSkillId = selected ? skill.id : null;
                    _validateForm();
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              );
            }),
            ActionChip(
                label: const Text('Skill Baru'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: () {}),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildXpSlider() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('XP Reward',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_currentXp.toInt()} XP',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            Slider(
              value: _currentXp,
              min: 10,
              max: 100,
              divisions: 9,
              label: _currentXp.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentXp = value;
                });
              },
            ),
            Text(_xpLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDaySelector() {
    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
              _validateForm();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              border:
                  isSelected ? null : Border.all(color: Colors.grey.shade700),
            ),
            child: Center(
                child: Text(days[index],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null))),
          ),
        );
      }),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildTimeAndDuration() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Start Time', border: OutlineInputBorder()),
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Duration?'),
            Switch(
                value: _hasDuration,
                onChanged: (v) => setState(() {
                      _hasDuration = v;
                      _validateForm();
                    })),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !_hasDuration
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                        labelText: 'Duration (in minutes)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        _hasDuration && v!.isEmpty ? 'Enter duration' : null,
                    onChanged: (_) => _validateForm(),
                  ),
                ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
          hintText: 'Add any notes here...', border: OutlineInputBorder()),
      maxLines: 3,
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildSubmitButton() => ElevatedButton(
        onPressed: _isFormValid ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        child: Text(_isFormValid ? 'Tetapkan Misi' : 'Lengkapi Detail Misi'),
      );

  Widget _buildNoSkillCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.star_border_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'Create a Skill First!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'A mission must be linked to a skill you want to master.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Skill'),
              onPressed: () {
                // TODO: Navigasi ke halaman AddSkillView (yang akan kita buat)
                print('Navigate to Add Skill Page');
                Navigator.pop(context); // Tutup altar dulu
              },
            )
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
