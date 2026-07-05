import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'guides_hub_screen.dart';
import 'home_screen.dart';
import 'upgrade_planner_screen.dart';

/// Top-level shell that hosts the three persistent tabs (Home, Guides,
/// Upgrade Planner) in an IndexedStack so the bottom nav doesn't slide in
/// or out when the user switches tabs.
///
/// Sub-pages (Settings, Spec Entry, Component Picker, placeholders, etc.)
/// are still pushed on top of this shell as separate routes. From a
/// sub-page, tapping a bottom-nav tab pops back to the shell and calls
/// [MainShellState.switchTab] to select the right tab.
class MainShell extends StatefulWidget {
  final AppTab initialTab;

  const MainShell({super.key, this.initialTab = AppTab.home});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  static MainShellState? _instance;
  static const List<AppTab> _tabs = [
    AppTab.home,
    AppTab.guides,
    AppTab.upgrades,
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final i = _tabs.indexOf(widget.initialTab);
    _currentIndex = i < 0 ? 0 : i;
    _instance = this;
  }

  @override
  void dispose() {
    if (_instance == this) _instance = null;
    super.dispose();
  }

  /// Switch the shell's active tab from anywhere (used by sub-pages after
  /// they pop back to the shell).
  static void switchTab(AppTab tab) {
    _instance?._selectTab(tab);
  }

  void _selectTab(AppTab tab) {
    final i = _tabs.indexOf(tab);
    if (i >= 0) setState(() => _currentIndex = i);
  }

  static const List<Widget> _tabWidgets = [
    HomeScreen(),
    GuidesHubScreen(),
    UpgradePlannerScreen(),
  ];

  Offset _restingOffsetFor(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const Offset(0, 0.04);
      case AppTab.guides:
        return const Offset(-0.08, 0);
      case AppTab.upgrades:
        return const Offset(0.08, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03091F),
      extendBody: true,
      body: Stack(
        children: List.generate(_tabWidgets.length, (i) {
          final isActive = i == _currentIndex;
          final restingOffset = _restingOffsetFor(_tabs[i]);
          return AnimatedSlide(
            offset: isActive ? Offset.zero : restingOffset,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !isActive,
                child: _tabWidgets[i],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: _tabs[_currentIndex],
        onHome: () => _selectTab(AppTab.home),
        onGuides: () => _selectTab(AppTab.guides),
        onUpgrades: () => _selectTab(AppTab.upgrades),
      ),
    );
  }
}
