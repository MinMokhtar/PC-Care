import 'package:flutter/material.dart';

enum AppTab { home, guides, upgrades }

class AppBottomNav extends StatelessWidget {
  final AppTab? activeTab;
  final VoidCallback onHome;
  final VoidCallback onGuides;
  final VoidCallback onUpgrades;

  const AppBottomNav({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onGuides,
    required this.onUpgrades,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF06112E),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: _NavItem(
                      icon: Icons.menu_book_outlined,
                      label: 'GUIDES',
                      active: activeTab == AppTab.guides,
                      onTap: onGuides,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: _NavItem(
                      icon: Icons.build_outlined,
                      label: 'UPGRADES',
                      active: activeTab == AppTab.upgrades,
                      onTap: onUpgrades,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              child: _HomeIndicator(
                active: activeTab == AppTab.home,
                onTap: onHome,
              ),
            ),
            Positioned(
              bottom: 4,
              child: Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: activeTab == AppTab.home
                      ? const Color(0xFF29ABE2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF29ABE2) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF29ABE2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HomeIndicator({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = active
        ? const LinearGradient(
            colors: [Color(0xFF5BCBF0), Color(0xFF1B6BB0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF4A5570), Color(0xFF2E3650)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF29ABE2).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
