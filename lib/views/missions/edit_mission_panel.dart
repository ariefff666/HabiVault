// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/widgets/custom_dialog.dart';

// Fungsi untuk menampilkan panel
void showEditMissionPanel(BuildContext context,
    {required EnrichedMissionModel enrichedMission}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditMissionPanel(enrichedMission: enrichedMission),
  );
}

class EditMissionPanel extends StatefulWidget {
  final EnrichedMissionModel enrichedMission;

  const EditMissionPanel({super.key, required this.enrichedMission});

  @override
  State<EditMissionPanel> createState() => _EditMissionPanelState();
}

class _EditMissionPanelState extends State<EditMissionPanel> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final MissionController _missionController = MissionController();

  // State untuk menyimpan perubahan
  late double _currentXp;
  late List<bool> _selectedDays;
  late TimeOfDay _selectedTime;
  late bool _hasDuration;
  bool _isFormValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi state dari data misi yang ada
    final mission = widget.enrichedMission.mission;
    _currentXp = mission.xp.toDouble();
    _selectedDays =
        List.generate(7, (index) => mission.scheduleDays.contains(index + 1));
    _selectedTime = mission.startTime;
    _hasDuration = mission.duration != null;
    if (_hasDuration) {
      _durationController.text = mission.duration!.inMinutes.toString();
    }
    _notesController.text = mission.notes ?? '';

    _durationController.addListener(_validateForm);
    _notesController.addListener(_validateForm);
    _validateForm(); // Validasi awal
  }

  void _validateForm() {
    final bool isDaysValid = _selectedDays.contains(true);
    final bool isDurationValid =
        !_hasDuration || (_hasDuration && _durationController.text.isNotEmpty);

    final newValidity = isDaysValid && isDurationValid;
    if (_isFormValid != newValidity) {
      setState(() {
        _isFormValid = newValidity;
      });
    }
  }

  String get _xpLabel {
    if (_currentXp < 30) return 'Santai';
    if (_currentXp < 60) return 'Tantangan Harian';
    if (_currentXp < 90) return 'Fokus Mendalam';
    return 'Upaya Heroik';
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_isFormValid || _isLoading) return;
    if (_formKey.currentState?.validate() == false) return;

    setState(() => _isLoading = true);

    final schedule = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) schedule.add(i + 1);
    }

    try {
      await _missionController.updateMissionDetails(
        missionId: widget.enrichedMission.mission.id,
        xp: _currentXp.toInt(),
        scheduleDays: schedule,
        startTime: _selectedTime,
        duration: _hasDuration
            ? Duration(minutes: int.parse(_durationController.text))
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup panel
        showHabiVaultDialog(
          context: context,
          title: 'Success',
          message:
              'Misi "${widget.enrichedMission.mission.title}" telah diperbarui.',
          type: DialogType.success,
        );
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _validateForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildReadOnlyInfo(),
                const SizedBox(height: 24),
                // Field yang bisa diedit
                _buildXpSlider(),
                const SizedBox(height: 16),
                _buildDaySelector(),
                const SizedBox(height: 16),
                _buildTimeAndDuration(),
                const SizedBox(height: 16),
                _buildNotesField(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  // Widget-widget pembangun UI
  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Edit Misi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );

  Widget _buildReadOnlyInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.enrichedMission.mission.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Skill: ', style: TextStyle(color: Colors.grey)),
                Icon(
                  IconData(int.parse(widget.enrichedMission.skill!.icon),
                      fontFamily: 'MaterialIcons'),
                  size: 16,
                  color: Color(widget.enrichedMission.skill!.color),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.enrichedMission.skill!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(widget.enrichedMission.skill!.color),
                  ),
                ),
              ],
            )
          ],
        ),
      );

  // ... (Salin _buildXpSlider, _buildDaySelector, _buildTimeAndDuration, _buildNotesField dari create_mission_altar.dart)
  // ... dan sesuaikan agar memanggil _validateForm() dan setState
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
                  _validateForm();
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
                    onChanged: (_) => _validateForm(),
                  ),
                ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildNotesField() {
    // Implementasi field catatan
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
          labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
      maxLines: 3,
    );
  }

  Widget _buildActionButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isFormValid && !_isLoading ? _submitForm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: _isLoading ? Container() : const Icon(Icons.save),
            label: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Perubahan'),
          ),
        ],
      );
}
