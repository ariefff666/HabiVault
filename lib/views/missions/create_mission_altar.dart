// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/views/skills/add_skill_panel.dart';
import 'package:habi_vault/widgets/custom_dialog.dart';

// --- STATE MANAGEMENT (Disederhanakan) ---
class AltarState {
  static Map<String, dynamic>? _savedFormData;

  // PERBAIKAN: Hapus _shouldShowMini, kita hanya butuh savedData
  static void saveData(Map<String, dynamic> data) {
    final hasData = data['title']?.toString().isNotEmpty == true ||
        data['skillId'] != null ||
        (data['selectedDays'] as List<bool>?)?.contains(true) == true;

    if (hasData) {
      _savedFormData = Map<String, dynamic>.from(data);
    } else {
      _savedFormData = null;
    }
  }

  static void clearData() {
    _savedFormData = null;
  }

  static Map<String, dynamic>? get savedData => _savedFormData;
}

// --- FUNGSI TAMPILAN ---
void showCreateMissionAltar(BuildContext context,
    {Map<String, dynamic>? data}) {
  // Pastikan data lama dibersihkan SEBELUM menampilkan altar,
  // sehingga `.then()` tidak akan dipicu oleh data dari sesi sebelumnya.
  if (data == null) {
    AltarState.clearData();
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black12,
    builder: (context) => CreateMissionAltar(initialData: data),
  ).then((_) {
    // PERBAIKAN: Cek langsung ke savedData. Ini lebih andal.
    if (AltarState.savedData != null) {
      _checkAndShowMiniAltar(context);
    }
  });
}

void _checkAndShowMiniAltar(BuildContext context) {
  Future.delayed(const Duration(milliseconds: 150), () {
    if (context.mounted && AltarState.savedData != null) {
      _showMinimizedAltar(context, AltarState.savedData!);
    }
  });
}

void _showMinimizedAltar(BuildContext context, Map<String, dynamic> formData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: true,
    barrierColor: Colors.transparent,
    builder: (context) => _MinimizedAltar(
      formData: formData,
      onExpand: () {
        Navigator.of(context).pop(); // Tutup mini altar
        Future.delayed(const Duration(milliseconds: 150), () {
          if (context.mounted) {
            // Buka altar utama lagi dengan data yang ada
            showCreateMissionAltar(context, data: formData);
          }
        });
      },
      onClose: () {
        AltarState.clearData();
        Navigator.of(context).pop();
      },
    ),
  );
}

// --- WIDGET ALTAR UTAMA ---
class CreateMissionAltar extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CreateMissionAltar({super.key, this.initialData});

  @override
  State<CreateMissionAltar> createState() => _CreateMissionAltarState();
}

class _CreateMissionAltarState extends State<CreateMissionAltar> {
  final Map<String, dynamic> _formData = {};
  late final DraggableScrollableController _dragController;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _formData.addAll(widget.initialData!);
    }
    _dragController = DraggableScrollableController();
    _dragController.addListener(_onDragMinimize);
  }

  void _handleMinimizeAndPop() {
    if (_isPopping) return; // Jika sudah dalam proses, abaikan
    _isPopping = true;
    AltarState.saveData(_formData);
    // pop() akan memicu WillPopScope, tapi flag _isPopping akan mencegah logika ganda
    Navigator.of(context).pop();
  }

  void _onDragMinimize() {
    if (!_dragController.isAttached) return;
    // Jika di-drag ke bawah melewati threshold, minimize.
    if (_dragController.size < 0.3) {
      _handleMinimizeAndPop();
    }
  }

  Future<bool> _onWillPop() async {
    // Ini akan menangani tap di luar & tombol kembali
    if (!_isPopping) {
      _isPopping = true;
      AltarState.saveData(_formData);
    }
    return true; // Izinkan pop
  }

  @override
  void dispose() {
    // Pastikan listener dilepas
    if (_dragController.isAttached) {
      _dragController.removeListener(_onDragMinimize);
    }
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SkillModel>>(
      stream: SkillController().getSkills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final skills = snapshot.data ?? [];

        return WillPopScope(
          onWillPop: _onWillPop,
          child: DraggableScrollableSheet(
            controller: _dragController,
            initialChildSize: 0.9,
            maxChildSize: 0.9,
            minChildSize: 0.2,
            snap: true,
            snapSizes: const [0.2, 0.9],
            expand: false,
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.85)
                          : const Color(0xFFF8F7F2).withOpacity(0.95),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: _MissionFormContents(
                      scrollController: scrollController,
                      dragController: _dragController,
                      skills: skills,
                      formData: _formData,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- WIDGET MINI ALTAR (Tidak ada perubahan) ---
// ... (Salin seluruh class _MinimizedAltar dari jawaban sebelumnya)
class _MinimizedAltar extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  const _MinimizedAltar({
    required this.formData,
    required this.onExpand,
    required this.onClose,
  });

  @override
  State<_MinimizedAltar> createState() => _MinimizedAltarState();
}

class _MinimizedAltarState extends State<_MinimizedAltar> {
  late DraggableScrollableController _dragController;

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
    _dragController.addListener(_onDragChanged);
  }

  void _onDragChanged() {
    if (!mounted || !_dragController.isAttached) return;

    if (_dragController.size > 0.15) {
      _dragController.removeListener(_onDragChanged);
      widget.onExpand();
    }
  }

  @override
  void dispose() {
    if (_dragController.isAttached) {
      _dragController.removeListener(_onDragChanged);
    }
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.08,
      maxChildSize: 0.3,
      minChildSize: 0.08,
      snap: true,
      snapSizes: const [0.08],
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: widget.onExpand,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.85)
                      : const Color(0xFFF8F7F2).withOpacity(0.95),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                        color: Colors.grey.withOpacity(0.3), width: 1.0),
                  ),
                ),
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Altar Penciptaan Misi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Tap or drag up to continue editing',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: widget.onClose,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGET FORM KONTEN ---
class _MissionFormContents extends StatefulWidget {
  final ScrollController scrollController;
  final DraggableScrollableController dragController;
  final List<SkillModel> skills;
  final Map<String, dynamic> formData;

  const _MissionFormContents({
    required this.scrollController,
    required this.dragController,
    required this.skills,
    required this.formData,
  });

  @override
  State<_MissionFormContents> createState() => __MissionFormContentsState();
}

class __MissionFormContentsState extends State<_MissionFormContents> {
  // ... (properti lain tetap sama)
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final MissionController _missionController = MissionController();

  String? _selectedSkillId;
  double _currentXp = 25.0;
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _hasDuration = false;
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    _restoreFormData();
    _titleController.addListener(_validateAndSaveForm);
    _durationController.addListener(_validateAndSaveForm);
    _notesController.addListener(_validateAndSaveForm);

    // Hanya perlu listener untuk scroll, karena drag akan ditangani AnimatedBuilder
    widget.scrollController.addListener(_onScrollChanged);
  }

  // ... (fungsi _restoreFormData hingga _closeAltar tidak berubah)
  void _restoreFormData() {
    if (widget.formData.isNotEmpty) {
      _titleController.text = widget.formData['title'] ?? '';
      _selectedSkillId = widget.formData['skillId'];
      _currentXp = widget.formData['xp'] ?? 25.0;
      if (widget.formData['selectedDays'] != null) {
        final savedDays = widget.formData['selectedDays'] as List<bool>;
        for (int i = 0; i < _selectedDays.length && i < savedDays.length; i++) {
          _selectedDays[i] = savedDays[i];
        }
      }
      if (widget.formData['selectedTime'] != null) {
        final timeData = widget.formData['selectedTime'] as Map<String, int>;
        _selectedTime =
            TimeOfDay(hour: timeData['hour']!, minute: timeData['minute']!);
      }
      _hasDuration = widget.formData['hasDuration'] ?? false;
      _durationController.text = widget.formData['duration'] ?? '';
      _notesController.text = widget.formData['notes'] ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
  }

  void _saveFormData() {
    widget.formData['title'] = _titleController.text;
    widget.formData['skillId'] = _selectedSkillId;
    widget.formData['xp'] = _currentXp;
    widget.formData['selectedDays'] = List<bool>.from(_selectedDays);
    widget.formData['selectedTime'] = {
      'hour': _selectedTime.hour,
      'minute': _selectedTime.minute
    };
    widget.formData['hasDuration'] = _hasDuration;
    widget.formData['duration'] = _durationController.text;
    widget.formData['notes'] = _notesController.text;
  }

  void _validateAndSaveForm() {
    _saveFormData();
    _validateForm();
  }

  void _validateForm() {
    final bool isTitleValid = _titleController.text.isNotEmpty;
    final bool isSkillValid = _selectedSkillId != null;
    final bool isDaysValid = _selectedDays.contains(true);
    final bool isDurationValid =
        !_hasDuration || (_hasDuration && _durationController.text.isNotEmpty);

    final newValidity =
        isTitleValid && isSkillValid && isDaysValid && isDurationValid;
    if (_isFormValid != newValidity) {
      setState(() {
        _isFormValid = newValidity;
      });
    }
  }

  void _onScrollChanged() {
    if (!mounted || !widget.scrollController.hasClients) return;
    final isAtTopNow = widget.scrollController.position.pixels <= 0;
    if (_isAtTop != isAtTopNow) {
      setState(() {
        _isAtTop = isAtTopNow;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateAndSaveForm);
    _durationController.removeListener(_validateAndSaveForm);
    _notesController.removeListener(_validateAndSaveForm);
    widget.scrollController.removeListener(_onScrollChanged);
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _closeAltar() {
    AltarState.clearData();
    Navigator.of(context).pop();
  }

  void _submitForm() async {
    // ... (Fungsi submit sama seperti sebelumnya)
    if (!_isFormValid || _isLoading) return;
    if (_formKey.currentState?.validate() == false) return;

    setState(() => _isLoading = true);

    final schedule = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) schedule.add(i + 1);
    }

    try {
      await _missionController.addMission(
        title: _titleController.text,
        skillId: _selectedSkillId!,
        xp: _currentXp.toInt(),
        scheduleDays: schedule,
        startTime: _selectedTime,
        duration: _hasDuration
            ? Duration(minutes: int.parse(_durationController.text))
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        AltarState.clearData();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showHabiVaultDialog(
          context: context,
          title: "Error",
          message: "Failed to forge mission. Please try again.",
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ... (fungsi _xpLabel, _selectTime, sama seperti sebelumnya)
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
        _validateAndSaveForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInteractiveHeader(),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: Stack(
              children: [
                _buildFormContent(),
                // PERBAIKAN: Gunakan AnimatedBuilder untuk menghilangkan flicker
                AnimatedBuilder(
                  animation: widget.dragController,
                  builder: (context, child) {
                    return _buildResponsiveStickySubmitButton();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget build method lainnya tidak berubah...
  // ... Salin _buildResponsiveStickySubmitButton dan sisanya dari jawaban sebelumnya ...

  Widget _buildResponsiveStickySubmitButton() {
    bool shouldHideButton = false;

    try {
      if (widget.dragController.isAttached) {
        final dragSize = widget.dragController.size;
        final isAtMaxSize = dragSize >= 0.85;

        // Logika utama untuk visibilitas tombol
        if (isAtMaxSize) {
          // Jika sheet full, visibilitas tergantung posisi scroll
          shouldHideButton = _isAtTop;
        } else {
          // Jika sheet tidak full, selalu sembunyikan tombol
          shouldHideButton = true;
        }
      } else {
        shouldHideButton = true; // Sembunyikan jika controller belum siap
      }
    } catch (_) {
      shouldHideButton = true;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      left: 0,
      right: 0,
      bottom: shouldHideButton ? -100 : 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.0),
              Theme.of(context).colorScheme.surface.withOpacity(0.9),
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: ElevatedButton(
          onPressed: _isFormValid && !_isLoading ? _submitForm : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.grey.shade500,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
              : Text(_isFormValid ? 'Tetapkan Misi' : 'Lengkapi Detail Misi'),
        ),
      ),
    );
  }

  Widget _buildInteractiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              const Text(
                'Altar Penciptaan Misi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _closeAltar,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      physics: const ClampingScrollPhysics(),
      children: [
        _buildSectionTitle('1. Definisikan Esensi Misi'),
        const SizedBox(height: 16),
        _buildPulsingTextField(),
        const SizedBox(height: 24),
        _buildSkillSelector(),
        const SizedBox(height: 32),
        _buildSectionTitle('2. Tentukan Tantangan & Imbalan'),
        const SizedBox(height: 16),
        _buildXpSlider(),
        const SizedBox(height: 32),
        _buildSectionTitle('3. Ikat Janji dengan Waktu'),
        const SizedBox(height: 16),
        _buildDaySelector(),
        const SizedBox(height: 24),
        _buildTimeAndDuration(),
        const SizedBox(height: 32),
        _buildSectionTitle('4. Catatan Tambahan (Opsional)'),
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
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
          runSpacing: 4.0,
          children: [
            ...widget.skills.map((skill) {
              final isSelected = _selectedSkillId == skill.id;
              final iconData =
                  IconData(int.parse(skill.icon), fontFamily: 'MaterialIcons');

              return ChoiceChip(
                label: Text(skill.name),
                avatar: Icon(iconData,
                    size: 16,
                    color: isSelected ? Colors.white : Color(skill.color)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSkillId = selected ? skill.id : null;
                    _validateAndSaveForm();
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              );
            }),
            ActionChip(
              label: const Text('Skill Baru'),
              avatar: const Icon(Icons.add, size: 16),
              onPressed: () => showAddSkillPanel(context),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildXpSlider() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withAlpha(150),
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
              min: 5,
              max: 100,
              divisions: 19,
              label: _currentXp.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentXp = value;
                  _validateAndSaveForm();
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
              _validateAndSaveForm();
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
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Duration?'),
            Switch(
                value: _hasDuration,
                onChanged: (v) => setState(() {
                      _hasDuration = v;
                      _validateAndSaveForm();
                    })),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !_hasDuration
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                        labelText: 'Duration (in minutes)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _hasDuration && (v == null || v.isEmpty)
                        ? 'Enter duration'
                        : null,
                    onChanged: (_) => _validateAndSaveForm(),
                  ),
                ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      onChanged: (_) => _validateAndSaveForm(),
      decoration: const InputDecoration(
          hintText: 'Add any notes here...', border: OutlineInputBorder()),
      maxLines: 3,
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildNoSkillCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.star_border_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Create a Skill First!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
                'A mission must be linked to a skill you want to master.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Skill'),
              onPressed: () => showAddSkillPanel(context),
            )
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
