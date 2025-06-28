// lib/views/skills/skill_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:habi_vault/views/skills/add_skill_panel.dart';
import 'package:habi_vault/views/skills/skill_detail_page.dart';

class SkillCard extends StatefulWidget {
  final SkillModel skill;
  const SkillCard({super.key, required this.skill});

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  bool _isMenuVisible = false;
  final SkillController _skillController = SkillController();

  void _toggleMenu() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _handleTap() {
    if (_isMenuVisible) {
      _toggleMenu();
    } else {
      // Kirim hanya ID
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SkillDetailPage(skillId: widget.skill.id)),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Path?'),
        content: Text(
            'Are you sure you want to abandon the path of "${widget.skill.name}"? All related progress will be lost forever.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _skillController.deleteSkill(widget.skill.id);
              Navigator.of(context).pop();
            },
            child: const Text('Abandon', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final skillColor = Color(widget.skill.color);
    final progress = widget.skill.xpForNextLevel > 0
        ? widget.skill.currentXp / widget.skill.xpForNextLevel
        : 0.0;
    final levelTier = widget.skill.tierName;

    return GestureDetector(
      onLongPress: _toggleMenu,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isMenuVisible ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Card(
          elevation: _isMenuVisible ? 10 : 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: colors.surface,
          clipBehavior: Clip.antiAlias, // Penting untuk bingkai progres
          child: Stack(
            children: [
              // Konten Utama Kartu
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      IconData(int.parse(widget.skill.icon),
                          fontFamily: 'MaterialIcons'),
                      color: skillColor,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.skill.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      levelTier.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: skillColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Bingkai Progress Bar yang Bercahaya
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 10,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(skillColor),
                  ),
                ),
              ),

              // Lencana Level di Pojok
              Positioned(
                top: 0,
                right: 0,
                child: _LevelBadge(level: widget.skill.level),
              ),

              // Tombol Edit/Hapus saat Long Press
              AnimatedOpacity(
                opacity: _isMenuVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          icon:
                              const Icon(Icons.edit_note, color: Colors.white),
                          onPressed: () {
                            _toggleMenu(); // Tutup menu
                            showAddSkillPanel(context,
                                skill: widget.skill); // Buka panel dengan data
                          },
                          tooltip: 'Reforge Skill'),
                      IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: Colors.white),
                          onPressed: () {
                            _toggleMenu(); // Tutup menu
                            _showDeleteConfirmation(); // Tampilkan konfirmasi
                          },
                          tooltip: 'Abandon Path'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGET KUSTOM UNTUK LENCANA LEVEL BERBENTUK PERISAI
class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ShieldClipper(),
      child: Container(
        width: 40,
        height: 45,
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Text(
            '$level',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// CUSTOM CLIPPER UNTUK MEMBUAT BENTUK PERISAI
class _ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.8);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.8);
    path.lineTo(0, size.height * 0.2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
