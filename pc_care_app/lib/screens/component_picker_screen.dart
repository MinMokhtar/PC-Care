import 'package:flutter/material.dart';

import '../models/pc_specs.dart';
import '../services/compatibility_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

enum UpgradeCategory {
  cpu('CPU', Icons.memory),
  gpu('GPU', Icons.videogame_asset),
  ram('RAM', Icons.view_module),
  storage('Storage', Icons.storage);

  const UpgradeCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  String get fullLabel {
    switch (this) {
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

  bool get hasQuantity =>
      this == UpgradeCategory.ram || this == UpgradeCategory.storage;

  bool get hasTypeFilter =>
      this == UpgradeCategory.gpu || this == UpgradeCategory.storage;
}

/// Returned from the picker when the user taps Select.
/// [quantity] is null for CPU/GPU (always 1 implicit) and set for RAM/Storage.
class ComponentSelection {
  final String name;
  final int? quantity;

  const ComponentSelection({required this.name, this.quantity});

  String get displayText =>
      quantity != null ? '$name  ×$quantity' : name;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };

  factory ComponentSelection.fromJson(Map<String, dynamic> json) =>
      ComponentSelection(
        name: json['name'] as String,
        quantity: json['quantity'] as int?,
      );
}

class ComponentPickerScreen extends StatefulWidget {
  final UpgradeCategory category;
  final PcSpecs currentSpecs;

  const ComponentPickerScreen({
    super.key,
    required this.category,
    required this.currentSpecs,
  });

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color rowDivider = Color(0xFF2A3550);
  static const Color accentBlue = Color(0xFF29ABE2);

  @override
  State<ComponentPickerScreen> createState() => _ComponentPickerScreenState();
}

class _ComponentPickerScreenState extends State<ComponentPickerScreen> {
  final _service = CompatibilityService();
  final _searchCtrl = TextEditingController();
  String _typeFilter = 'All';
  final Map<int, int> _quantities = {}; // index → quantity

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _allItems {
    switch (widget.category) {
      case UpgradeCategory.cpu:
        return _service.compatibleCpus(widget.currentSpecs);
      case UpgradeCategory.gpu:
        return _service.compatibleGpus(widget.currentSpecs);
      case UpgradeCategory.ram:
        return _service.compatibleRam(widget.currentSpecs);
      case UpgradeCategory.storage:
        return _service.compatibleStorage(widget.currentSpecs);
    }
  }

  List<String> get _typeFilterOptions {
    switch (widget.category) {
      case UpgradeCategory.gpu:
        return ['All', 'NVIDIA', 'AMD', 'Intel'];
      case UpgradeCategory.storage:
        return ['All', 'HDD', 'SATA SSD', 'NVMe SSD'];
      default:
        return ['All'];
    }
  }

  bool _matchesTypeFilter(dynamic item) {
    if (_typeFilter == 'All') return true;
    if (item is GpuOption) {
      return item.brand.toLowerCase().contains(_typeFilter.toLowerCase());
    }
    if (item is StorageOption) {
      return item.kind.label.contains(_typeFilter);
    }
    return true;
  }

  bool _matchesSearch(dynamic item) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final name = _nameOf(item).toLowerCase();
    return name.contains(q);
  }

  String _nameOf(dynamic item) {
    if (item is CpuOption) return item.name;
    if (item is GpuOption) return item.name;
    if (item is RamOption) return item.name;
    if (item is StorageOption) return item.name;
    return item.toString();
  }

  String? _warningFor(dynamic item) {
    if (item is GpuOption) {
      return _service.warningForGpu(widget.currentSpecs, item);
    }
    return null;
  }

  List<dynamic> get _visibleItems {
    return _allItems
        .where((e) => _matchesTypeFilter(e) && _matchesSearch(e))
        .toList();
  }

  void _onSelect(int index, dynamic item) {
    final qty = widget.category.hasQuantity ? (_quantities[index] ?? 1) : null;
    Navigator.of(context).pop(
      ComponentSelection(name: _nameOf(item), quantity: qty),
    );
  }

  void _showSortMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sort options — coming soon'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTypeMenu() async {
    final options = _typeFilterOptions;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ComponentPickerScreen.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Filter by type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final opt in options)
              ListTile(
                title: Text(opt, style: const TextStyle(color: Colors.white)),
                trailing: opt == _typeFilter
                    ? const Icon(Icons.check,
                        color: ComponentPickerScreen.accentBlue)
                    : null,
                onTap: () => Navigator.pop(context, opt),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _typeFilter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return Scaffold(
      backgroundColor: ComponentPickerScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              _CategoryToolbar(
                title: widget.category.fullLabel,
                hasTypeFilter: widget.category.hasTypeFilter,
                typeFilter: _typeFilter,
                onTypeTap: _showTypeMenu,
                onSortTap: _showSortMenu,
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                _EmptyState(category: widget.category.label)
              else
                _ItemsList(
                  items: items,
                  hasQuantity: widget.category.hasQuantity,
                  quantities: _quantities,
                  nameOf: _nameOf,
                  warningOf: _warningFor,
                  onQuantityChanged: (i, q) =>
                      setState(() => _quantities[i] = q),
                  onSelect: _onSelect,
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

// ---------- Header (title + bell + settings + back) ----------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _MiniIconButton(icon: Icons.notifications_outlined),
                  SizedBox(width: 10),
                  _MiniIconButton(icon: Icons.settings_outlined),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: ComponentPickerScreen.iconBg,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onBack,
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
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  const _MiniIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: ComponentPickerScreen.iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ---------- Search bar ----------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ComponentPickerScreen.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search a model',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Category title + Type filter + Sort ----------

class _CategoryToolbar extends StatelessWidget {
  final String title;
  final bool hasTypeFilter;
  final String typeFilter;
  final VoidCallback onTypeTap;
  final VoidCallback onSortTap;

  const _CategoryToolbar({
    required this.title,
    required this.hasTypeFilter,
    required this.typeFilter,
    required this.onTypeTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (hasTypeFilter) ...[
          _Pill(
            icon: null,
            label: 'Type: $typeFilter',
            onTap: onTypeTap,
          ),
          const SizedBox(width: 8),
        ],
        _Pill(
          icon: Icons.swap_vert,
          label: 'Sort: Performance',
          onTap: onSortTap,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _Pill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ComponentPickerScreen.iconBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Items list ----------

class _ItemsList extends StatelessWidget {
  final List<dynamic> items;
  final bool hasQuantity;
  final Map<int, int> quantities;
  final String Function(dynamic) nameOf;
  final String? Function(dynamic) warningOf;
  final void Function(int, int) onQuantityChanged;
  final void Function(int, dynamic) onSelect;

  const _ItemsList({
    required this.items,
    required this.hasQuantity,
    required this.quantities,
    required this.nameOf,
    required this.warningOf,
    required this.onQuantityChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ComponentPickerScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ItemRow(
              name: nameOf(items[i]),
              warning: warningOf(items[i]),
              hasQuantity: hasQuantity,
              quantity: quantities[i] ?? 1,
              onQuantityChanged: (q) => onQuantityChanged(i, q),
              onSelect: () => onSelect(i, items[i]),
            ),
            if (i != items.length - 1)
              const Divider(
                color: ComponentPickerScreen.rowDivider,
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final String? warning;
  final bool hasQuantity;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onSelect;

  const _ItemRow({
    required this.name,
    required this.warning,
    required this.hasQuantity,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFA726),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warning!,
                          style: const TextStyle(
                            color: Color(0xFFFFA726),
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasQuantity) ...[
            const SizedBox(width: 8),
            _QuantityStepper(
              quantity: quantity,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: onSelect,
            style: TextButton.styleFrom(
              foregroundColor: ComponentPickerScreen.accentBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(40, 30),
              textStyle: const TextStyle(
                fontSize: 13,
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

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onChanged((quantity + 1).clamp(1, 4)),
          child: const Icon(Icons.add, color: Colors.white54, size: 16),
        ),
        Text(
          '$quantity',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        InkWell(
          onTap: () => onChanged((quantity - 1).clamp(1, 4)),
          child: const Icon(Icons.remove, color: Colors.white54, size: 16),
        ),
      ],
    );
  }
}

// ---------- Empty state ----------

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ComponentPickerScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            'No $category options match your filters.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
