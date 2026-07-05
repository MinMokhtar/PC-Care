import 'package:flutter/material.dart';

import '../data/pc_components.dart';
import '../models/pc_specs.dart';
import '../services/pc_specs_service.dart';
import '../services/upgrade_plan_service.dart';
import '../widgets/notifications_dropdown.dart';
import 'component_picker_screen.dart';
import 'review_plan_screen.dart';
import 'settings_screen.dart';
import 'spec_entry_screen.dart';

class UpgradePlannerScreen extends StatefulWidget {
  const UpgradePlannerScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color compatGreen = Color(0xFF22C55E);
  static const Color compatBg = Color(0xFF13322A);

  @override
  State<UpgradePlannerScreen> createState() => _UpgradePlannerScreenState();
}

class _UpgradePlannerScreenState extends State<UpgradePlannerScreen> {
  final _specsService = PcSpecsService();
  final _planService = UpgradePlanService();
  final GlobalKey _bellKey = GlobalKey();

  PcSpecs _specs = PcSpecs.empty;
  bool _loading = true;
  bool _hasUnread = true;
  Map<UpgradeCategory, ComponentSelection> _selectedUpgrades = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final specs = await _specsService.load();
    final plan = await _planService.load();
    if (!mounted) return;
    setState(() {
      _specs = specs;
      _selectedUpgrades = plan;
      _loading = false;
    });
  }

  void _persistPlan() {
    _planService.save(_selectedUpgrades);
  }

  Future<void> _openReviewPlan() async {
    final cleared = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewPlanScreen(
          specs: _specs,
          plan: _selectedUpgrades,
        ),
      ),
    );
    if (cleared == true && mounted) {
      setState(() => _selectedUpgrades = {});
      _planService.clear();
    }
  }

  Future<void> _editSpecs() async {
    final updated = await Navigator.of(context).push<PcSpecs>(
      MaterialPageRoute(
        builder: (_) => SpecEntryScreen(initialSpecs: _specs),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _specs = updated;
        _selectedUpgrades.clear();
      });
      _persistPlan();
    }
  }

  Future<void> _pickUpgrade(UpgradeCategory category) async {
    if (!_hasSpecs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your PC specs first to see compatible parts.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final selected = await Navigator.of(context).push<ComponentSelection>(
      MaterialPageRoute(
        builder: (_) => ComponentPickerScreen(
          category: category,
          currentSpecs: _specs,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedUpgrades[category] = selected);
      _persistPlan();
    }
  }

  bool get _hasSpecs =>
      _specs.motherboardSocket != null &&
      _specs.motherboardRamType != null &&
      _specs.psuWatts != null;

  void _showNotifications() {
    showNotificationsDropdown(
      context: context,
      bellKey: _bellKey,
      onMarkAllRead: () => setState(() => _hasUnread = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      bellKey: _bellKey,
                      hasUnread: _hasUnread,
                      onBell: _showNotifications,
                      onSettings: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_hasSpecs)
                      _SpecsCard(specs: _specs, onEdit: _editSpecs)
                    else
                      _EmptyState(onEnterSpecs: _editSpecs),
                    const SizedBox(height: 18),
                    _UpgradeListCard(
                      specs: _specs,
                      selectedUpgrades: _selectedUpgrades,
                      onPick: _pickUpgrade,
                      enabled: _hasSpecs,
                    ),
                    if (_selectedUpgrades.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openReviewPlan,
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Review Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UpgradePlannerScreen.accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

// ---------- Top bar ----------

class _TopBar extends StatelessWidget {
  final GlobalKey bellKey;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onSettings;

  const _TopBar({
    required this.bellKey,
    required this.hasUnread,
    required this.onBell,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade Planner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Find the best parts for your needs.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _CircleIconButton(
                key: bellKey,
                icon: Icons.notifications_outlined,
                onTap: onBell,
                showBadge: hasUnread,
              ),
              const SizedBox(width: 10),
              _CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: UpgradePlannerScreen.iconBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(
                  color: UpgradePlannerScreen.iconBg,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- Current PC Specs card ----------

class _SpecsCard extends StatelessWidget {
  final PcSpecs specs;
  final VoidCallback onEdit;

  const _SpecsCard({required this.specs, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UpgradePlannerScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current PC Specs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
                tooltip: 'Edit specs',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _specRow('CPU', specs.cpuName ?? '—'),
          _specRow('GPU', specs.gpuName ?? '—'),
          if (specs.hasSecondaryGpu)
            _specRow('GPU 2', specs.secondaryGpuName ?? '—'),
          _specRow('RAM', specs.ramName ?? specs.motherboardRamType?.label ?? '—'),
          _specRow('Storage', specs.storageName ?? '—'),
          if (specs.hasSecondaryStorage)
            _specRow(
              'Storage 2',
              [
                specs.secondaryStorageType,
                specs.secondaryStorageName,
              ].where((s) => s != null).join(' '),
            ),
          _specRow(
            'Mobo',
            specs.motherboardName ??
                specs.motherboardSocket?.label ??
                '—',
          ),
          _specRow(
            'PSU',
            specs.psuWatts != null ? '${specs.psuWatts}W' : '—',
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Empty state ("Tell us about your PC") ----------

class _EmptyState extends StatelessWidget {
  final VoidCallback onEnterSpecs;

  const _EmptyState({required this.onEnterSpecs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UpgradePlannerScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.developer_board_outlined,
            color: Colors.white,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tell us about your PC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "Enter your specs here. We'll filter upgrade options that fit your current build",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onEnterSpecs,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Enter my specs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: UpgradePlannerScreen.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Upgrade list card ----------

enum _CompatKind { neutral, success, warning }

class _CompatStatus {
  final _CompatKind kind;
  final String message;
  const _CompatStatus({required this.kind, required this.message});
}

class _UpgradeListCard extends StatelessWidget {
  final PcSpecs specs;
  final Map<UpgradeCategory, ComponentSelection> selectedUpgrades;
  final void Function(UpgradeCategory) onPick;
  final bool enabled;

  const _UpgradeListCard({
    required this.specs,
    required this.selectedUpgrades,
    required this.onPick,
    required this.enabled,
  });

  static const int _baseSystemWatts = 150;

  CpuOption? _lookupCpu(String? name) {
    if (name == null) return null;
    for (final c in availableCpus) {
      if (c.name == name) return c;
    }
    return null;
  }

  GpuOption? _lookupGpu(String? name) {
    if (name == null) return null;
    for (final g in availableGpus) {
      if (g.name == name) return g;
    }
    return null;
  }

  _CompatStatus _computeStatus() {
    if (!enabled) {
      return const _CompatStatus(
        kind: _CompatKind.neutral,
        message: 'Enter your PC specs above to see compatible parts.',
      );
    }
    if (selectedUpgrades.isEmpty) {
      return const _CompatStatus(
        kind: _CompatKind.success,
        message:
            'These parts are 100% compatible with your current system. (EST Pwr: None)',
      );
    }
    final cpu = _lookupCpu(selectedUpgrades[UpgradeCategory.cpu]?.name);
    final gpu = _lookupGpu(selectedUpgrades[UpgradeCategory.gpu]?.name);
    int estPower = _baseSystemWatts;
    if (cpu != null) estPower += cpu.tdpWatts;
    if (gpu != null) estPower += gpu.powerWatts;
    final psuWatts = specs.psuWatts;
    if (gpu != null && psuWatts != null && psuWatts < gpu.recommendedPsuWatts) {
      return _CompatStatus(
        kind: _CompatKind.warning,
        message:
            'PSU may be too low for the ${gpu.name}. Needs ~${gpu.recommendedPsuWatts}W, you have ${psuWatts}W. (EST Pwr: ${estPower}W)',
      );
    }
    if (psuWatts != null) {
      final headroom = psuWatts - estPower;
      if (headroom < 50) {
        return _CompatStatus(
          kind: _CompatKind.warning,
          message:
              'Tight PSU headroom (${headroom}W spare). Consider a higher-wattage PSU. (EST Pwr: ${estPower}W)',
        );
      }
    }
    return _CompatStatus(
      kind: _CompatKind.success,
      message:
          'These parts are 100% compatible with your current system. (EST Pwr: ${estPower}W)',
    );
  }

  String _categoryDisplay(UpgradeCategory c) {
    switch (c) {
      case UpgradeCategory.cpu:
        return 'Processor (CPU)';
      case UpgradeCategory.ram:
        return 'Memory (RAM)';
      case UpgradeCategory.gpu:
        return 'GPU';
      case UpgradeCategory.storage:
        return 'Storage';
    }
  }

  IconData _categoryIcon(UpgradeCategory c) {
    switch (c) {
      case UpgradeCategory.cpu:
        return Icons.memory;
      case UpgradeCategory.ram:
        return Icons.view_module;
      case UpgradeCategory.gpu:
        return Icons.videogame_asset_outlined;
      case UpgradeCategory.storage:
        return Icons.sd_storage_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UpgradePlannerScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upgrade list',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select parts thats currently compatible with your current specs',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _compatBadge(),
              const SizedBox(height: 14),
              for (final cat in UpgradeCategory.values) ...[
                _UpgradeRow(
                  icon: _categoryIcon(cat),
                  title: _categoryDisplay(cat),
                  selected: selectedUpgrades[cat],
                  onSelect: () => onPick(cat),
                ),
                if (cat != UpgradeCategory.values.last)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _compatBadge() {
    final status = _computeStatus();
    Color accent;
    Color bg;
    IconData icon;
    switch (status.kind) {
      case _CompatKind.warning:
        accent = const Color(0xFFFFA726);
        bg = const Color(0xFF3F2E16);
        icon = Icons.warning_amber_rounded;
        break;
      case _CompatKind.neutral:
      case _CompatKind.success:
        accent = UpgradePlannerScreen.compatGreen;
        bg = UpgradePlannerScreen.compatBg;
        icon = Icons.check;
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final ComponentSelection? selected;
  final VoidCallback onSelect;

  const _UpgradeRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UpgradePlannerScreen.iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: UpgradePlannerScreen.iconBgInner,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected == null
                      ? 'Selected: None'
                      : 'Selected: ${selected!.displayText}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSelect,
            style: TextButton.styleFrom(
              foregroundColor: UpgradePlannerScreen.accentBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
