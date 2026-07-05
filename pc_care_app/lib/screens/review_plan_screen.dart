import 'package:flutter/material.dart';

import '../data/pc_components.dart';
import '../models/pc_specs.dart';
import '../widgets/app_bottom_nav.dart';
import 'component_picker_screen.dart';
import 'main_shell.dart';

/// Shows the user's saved upgrade plan as a side-by-side comparison:
/// Current spec → Upgrade. Pop with `true` if user cleared the plan.
class ReviewPlanScreen extends StatelessWidget {
  final PcSpecs specs;
  final Map<UpgradeCategory, ComponentSelection> plan;

  const ReviewPlanScreen({
    super.key,
    required this.specs,
    required this.plan,
  });

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color goodGreen = Color(0xFF22C55E);
  static const Color goodBg = Color(0xFF13322A);
  static const Color warnAmber = Color(0xFFFFA726);
  static const Color warnBg = Color(0xFF3F2E16);

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

  ({String message, bool warning, int estWatts}) _computeStatus() {
    final upgradedCpu = _lookupCpu(plan[UpgradeCategory.cpu]?.name);
    final upgradedGpu = _lookupGpu(plan[UpgradeCategory.gpu]?.name);
    final currentCpu = _lookupCpu(specs.cpuName);
    final currentGpu = _lookupGpu(specs.gpuName);

    int est = _baseSystemWatts;
    est += (upgradedCpu ?? currentCpu)?.tdpWatts ?? 0;
    est += (upgradedGpu ?? currentGpu)?.powerWatts ?? 0;

    final psu = specs.psuWatts;
    final gpuForCheck = upgradedGpu ?? currentGpu;
    if (gpuForCheck != null && psu != null && psu < gpuForCheck.recommendedPsuWatts) {
      return (
        message:
            'PSU may not be enough for ${gpuForCheck.name}. Needs ~${gpuForCheck.recommendedPsuWatts}W, you have ${psu}W. (EST Pwr: ${est}W)',
        warning: true,
        estWatts: est,
      );
    }
    if (psu != null && (psu - est) < 50) {
      return (
        message:
            'Tight PSU headroom (${psu - est}W spare). Consider higher-wattage PSU. (EST Pwr: ${est}W)',
        warning: true,
        estWatts: est,
      );
    }
    return (
      message:
          'This plan is 100% compatible with your current system. (EST Pwr: ${est}W)',
      warning: false,
      estWatts: est,
    );
  }

  void _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text(
          'Clear plan?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all selected upgrades. You can pick new ones any time.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _computeStatus();
    final entries = <_PlanEntry>[
      _PlanEntry(
        category: UpgradeCategory.cpu,
        icon: Icons.memory,
        title: 'Processor (CPU)',
        currentText: specs.cpuName,
        upgrade: plan[UpgradeCategory.cpu],
      ),
      _PlanEntry(
        category: UpgradeCategory.ram,
        icon: Icons.view_module,
        title: 'Memory (RAM)',
        currentText: specs.ramName,
        upgrade: plan[UpgradeCategory.ram],
      ),
      _PlanEntry(
        category: UpgradeCategory.gpu,
        icon: Icons.videogame_asset_outlined,
        title: 'GPU',
        currentText: specs.gpuName,
        upgrade: plan[UpgradeCategory.gpu],
      ),
      _PlanEntry(
        category: UpgradeCategory.storage,
        icon: Icons.sd_storage_outlined,
        title: 'Storage',
        currentText: specs.storageName,
        upgrade: plan[UpgradeCategory.storage],
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 12),
              _BackPill(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              _CompatBanner(
                message: status.message,
                warning: status.warning,
              ),
              const SizedBox(height: 18),
              for (final e in entries) ...[
                _ComparisonCard(entry: e),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppTab.upgrades,
        onHome: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.home);
        },
        onGuides: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.guides);
        },
        onUpgrades: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _PlanEntry {
  final UpgradeCategory category;
  final IconData icon;
  final String title;
  final String? currentText;
  final ComponentSelection? upgrade;

  const _PlanEntry({
    required this.category,
    required this.icon,
    required this.title,
    required this.currentText,
    required this.upgrade,
  });

  bool get hasUpgrade => upgrade != null;
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Upgrade Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Current parts vs your saved upgrades.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: ReviewPlanScreen.iconBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Compatibility banner ----------

class _CompatBanner extends StatelessWidget {
  final String message;
  final bool warning;

  const _CompatBanner({required this.message, required this.warning});

  @override
  Widget build(BuildContext context) {
    final accent =
        warning ? ReviewPlanScreen.warnAmber : ReviewPlanScreen.goodGreen;
    final bg = warning ? ReviewPlanScreen.warnBg : ReviewPlanScreen.goodBg;
    final icon = warning ? Icons.warning_amber_rounded : Icons.check;
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
              message,
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

// ---------- Comparison card (Current → Upgrade for one component) ----------

class _ComparisonCard extends StatelessWidget {
  final _PlanEntry entry;

  const _ComparisonCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReviewPlanScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ReviewPlanScreen.iconBgInner,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(entry.icon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                entry.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SideColumn(
                  label: 'Current',
                  value: entry.currentText ?? '—',
                  faded: !entry.hasUpgrade,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(
                  Icons.arrow_forward,
                  color: ReviewPlanScreen.accentBlue,
                  size: 20,
                ),
              ),
              Expanded(
                child: _SideColumn(
                  label: 'Upgrade to',
                  value: entry.hasUpgrade ? entry.upgrade!.displayText : 'No change',
                  highlight: entry.hasUpgrade,
                  faded: !entry.hasUpgrade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool faded;

  const _SideColumn({
    required this.label,
    required this.value,
    this.highlight = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight
        ? ReviewPlanScreen.accentBlue
        : (faded ? Colors.white38 : Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
