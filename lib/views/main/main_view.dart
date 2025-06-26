// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:habi_vault/views/dashboard/dashboard_view.dart';
import 'package:habi_vault/views/main/placeholder_view.dart';
import 'package:habi_vault/views/missions/missions_page_view.dart';

// Data untuk setiap tombol aksi
class ActionButtonData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  ActionButtonData(
      {required this.icon, required this.label, required this.onTap});
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  // State baru untuk mengontrol pembukaan Altar
  bool _shouldShowAltarOnNextBuild = false;

  late AnimationController _animationController;
  int? _hoveredIndex;
  late final List<ActionButtonData> _actionButtons;
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _actionButtons = [
      ActionButtonData(
        icon: Icons.add_task,
        label: 'Mission',
        onTap: () => _navigateAndShowAltar(),
      ),
      ActionButtonData(
          icon: Icons.star_outline_rounded,
          label: 'Skill',
          onTap: () => _onActionSelected('Add Skill')),
      ActionButtonData(
          icon: Icons.history_edu_rounded,
          label: 'Log',
          onTap: () => _onActionSelected('Log Progress')),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Navigasi dan Aksi ---
  void _onItemTapped(int index) {
    setState(() {
      if (_animationController.isCompleted) {
        _closeMenu();
      }
      _selectedIndex = index;
    });
  }

  void _onActionSelected(String action) {
    print('$action selected! coy');
    _closeMenu();
  }

  // --- FUNGSI UNTUK NAVIGASI DAN MEMBUKA ALTAR ---
  void _navigateAndShowAltar() {
    _closeMenu();

    // Berikan feedback visual
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: const Text('Opening Mission Creator...'),
    //     duration: const Duration(milliseconds: 800),
    //     behavior: SnackBarBehavior.floating,
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //   ),
    // );

    setState(() {
      _selectedIndex = 2;
      _shouldShowAltarOnNextBuild = true;
    });
  }

  // --- Kontrol Menu Aksi ---
  void _toggleMenu() {
    if (_animationController.isCompleted) {
      _closeMenu();
    } else {
      _animationController.forward();
    }
  }

  void _closeMenu() {
    _animationController.reverse();
    setState(() {
      _hoveredIndex = null;
    });
  }

  // --- Logika Gestur Tahan-dan-Geser ---
  void _onPanStart(DragStartDetails details) {
    _animationController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final fabRenderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (fabRenderBox == null) return;
    final fabCenter =
        fabRenderBox.localToGlobal(Offset.zero) + const Offset(28, 28);
    final touchPosition = details.globalPosition;
    int? newHoveredIndex;

    for (int i = 0; i < _actionButtons.length; i++) {
      final buttonPosition = _getActionButtonPosition(i, fabCenter);
      // Kembalikan radius detection ke original
      if ((touchPosition - buttonPosition).distance < 35.0) {
        newHoveredIndex = i;
        break;
      }
    }

    if (newHoveredIndex != _hoveredIndex) {
      setState(() {
        _hoveredIndex = newHoveredIndex;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_hoveredIndex != null) {
      _actionButtons[_hoveredIndex!].onTap();
    } else {
      _closeMenu();
    }
  }

  // Helper untuk menghitung posisi sub-tombol dengan kurva
  Offset _getActionButtonPosition(int index, Offset fabCenter) {
    // Gunakan nilai yang sama seperti di overlay
    final verticalDistance =
        (index == 1) ? 120.0 : 90.0; // Update sesuai perubahan Anda
    final horizontalDistance =
        (index - 1) * 70.0; // Update sesuai perubahan Anda
    return Offset(
        fabCenter.dx + horizontalDistance, fabCenter.dy - verticalDistance);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DashboardView(),
      const PlaceholderView(pageName: 'All Skills'),
      QuestsPage(showAltarOnLoad: _shouldShowAltarOnNextBuild),
      const PlaceholderView(pageName: 'Profile'),
    ];

    // Reset bendera setelah build selesai untuk mencegah altar terbuka terus-menerus
    if (_shouldShowAltarOnNextBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _shouldShowAltarOnNextBuild = false;
          });
        }
      });
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            Scaffold(
              extendBody: true,
              body: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
              bottomNavigationBar: _buildCustomBottomAppBar(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: _buildCentralButton(),
            ),

            // Action buttons di layer terpisah dengan positioning manual
            if (_animationController.value > 0.1) _buildActionButtonsOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildActionButtonsOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: _animationController.value < 0.8,
        child: Stack(
          children: [
            // Dapatkan posisi FAB untuk referensi
            LayoutBuilder(
              builder: (context, constraints) {
                // Hitung posisi FAB berdasarkan screen size
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final fabX = screenWidth / 2;
                final fabY = screenHeight - 80;

                return Stack(
                  children: List.generate(_actionButtons.length, (index) {
                    final animationValue = _animationController.value;
                    final verticalDistance = (index == 1) ? 120.0 : 90.0;
                    final horizontalDistance = (index - 1) * 70.0;

                    final buttonX =
                        fabX + (horizontalDistance * animationValue) - 22;
                    final buttonY =
                        fabY - (verticalDistance * animationValue) - 22;

                    return Positioned(
                      left: buttonX,
                      top: buttonY,
                      child: Opacity(
                        opacity: animationValue,
                        child: Transform(
                          alignment: Alignment.center, // Scaling dari center
                          transform: Matrix4.identity()..scale(animationValue),
                          child: _ActionButton(
                            data: _actionButtons[index],
                            isHovered: _hoveredIndex == index,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralButton() {
    return GestureDetector(
      onTap: _toggleMenu,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: FloatingActionButton(
        key: _fabKey,
        heroTag: 'main_fab',
        onPressed: null, // Disable bawaan, gunakan GestureDetector
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.375).animate(_animationController),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildCustomBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0, // <-- Lekukan yang lebih kecil dan pas
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavIcon(icon: Icons.home_rounded, index: 0, label: 'Home'),
          _buildNavIcon(icon: Icons.star_rounded, index: 1, label: 'Skills'),
          const SizedBox(width: 48), // Ruang kosong untuk lekukan
          _buildNavIcon(
              icon: Icons.check_circle_rounded, index: 2, label: 'Quests'),
          _buildNavIcon(icon: Icons.person_rounded, index: 3, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
      {required IconData icon, required int index, required String label}) {
    bool isSelected = (_selectedIndex == index);
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                  size: isSelected ? 30 : 28),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ActionButtonData data;
  final bool isHovered;

  const _ActionButton({required this.data, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final bgColor = isHovered
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final fgColor = isHovered
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;

    return AnimatedScale(
      scale: isHovered ? 1.18 : 1.0, // Hover scaling yang smooth
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Container(
        width: 44, // Ukuran tetap
        height: 44, // Ukuran tetap
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.7),
                    blurRadius: 12.0,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print("Action button tapped: ${data.label}");
              data.onTap();
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(data.icon, color: fgColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
