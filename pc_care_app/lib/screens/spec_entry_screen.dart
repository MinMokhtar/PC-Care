import 'package:flutter/material.dart';

import '../data/spec_options.dart';
import '../models/pc_specs.dart';
import '../services/pc_specs_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

class SpecEntryScreen extends StatefulWidget {
  final PcSpecs initialSpecs;

  const SpecEntryScreen({super.key, required this.initialSpecs});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color dropdownBg = Color(0xFF1B2238);
  static const Color accentBlue = Color(0xFF29ABE2);

  @override
  State<SpecEntryScreen> createState() => _SpecEntryScreenState();
}

class _SpecEntryScreenState extends State<SpecEntryScreen> {
  final _service = PcSpecsService();

  // CPU
  String? _cpuBrand;
  CpuSocket? _cpuSocket;
  String? _cpuModel;

  // Motherboard
  String? _moboChipset;
  String? _moboSize;

  // GPU
  String? _gpuBrand;
  String? _gpuModel;
  int? _gpuQuantity;

  // Secondary GPU (optional)
  bool _showSecondaryGpu = false;
  String? _gpuBrand2;
  String? _gpuModel2;
  int? _gpuQuantity2;

  // RAM
  String? _ramModule;
  int? _ramQuantity;

  // Storage
  String? _storageType;
  String? _storageSize;
  int? _storageQuantity;

  // Secondary Storage (optional)
  bool _showSecondaryStorage = false;
  String? _storageType2;
  String? _storageSize2;
  int? _storageQuantity2;

  // PSU
  int? _psuWatts;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSpecs;
    _cpuBrand = s.cpuBrand;
    _cpuSocket = s.motherboardSocket;
    _cpuModel = s.cpuName;
    _moboChipset = s.motherboardName;
    _moboSize = s.motherboardSize;
    _gpuBrand = s.gpuBrand;
    _gpuModel = s.gpuName;
    _gpuQuantity = s.gpuQuantity;
    _gpuBrand2 = s.secondaryGpuBrand;
    _gpuModel2 = s.secondaryGpuName;
    _gpuQuantity2 = s.secondaryGpuQuantity;
    _showSecondaryGpu = s.hasSecondaryGpu;
    _ramModule = s.ramName;
    _ramQuantity = s.ramQuantity;
    _storageType = s.storageType;
    _storageSize = s.storageName;
    _storageQuantity = s.storageQuantity;
    _storageType2 = s.secondaryStorageType;
    _storageSize2 = s.secondaryStorageName;
    _storageQuantity2 = s.secondaryStorageQuantity;
    _showSecondaryStorage = s.hasSecondaryStorage;
    _psuWatts = s.psuWatts;
  }

  RamType? get _inferredRamType =>
      _moboChipset != null ? ramTypeByChipset[_moboChipset] : null;

  Future<void> _save() async {
    final specs = PcSpecs(
      cpuBrand: _cpuBrand,
      cpuName: _cpuModel,
      gpuBrand: _gpuBrand,
      gpuName: _gpuModel,
      gpuQuantity: _gpuQuantity,
      secondaryGpuBrand: _showSecondaryGpu ? _gpuBrand2 : null,
      secondaryGpuName: _showSecondaryGpu ? _gpuModel2 : null,
      secondaryGpuQuantity: _showSecondaryGpu ? _gpuQuantity2 : null,
      ramName: _ramModule,
      ramQuantity: _ramQuantity,
      storageName: _storageSize,
      storageType: _storageType,
      storageQuantity: _storageQuantity,
      secondaryStorageName: _showSecondaryStorage ? _storageSize2 : null,
      secondaryStorageType: _showSecondaryStorage ? _storageType2 : null,
      secondaryStorageQuantity:
          _showSecondaryStorage ? _storageQuantity2 : null,
      motherboardSocket: _cpuSocket,
      motherboardRamType: _inferredRamType,
      motherboardName: _moboChipset,
      motherboardSize: _moboSize,
      psuWatts: _psuWatts,
    );
    await _service.save(specs);
    if (!mounted) return;
    Navigator.of(context).pop(specs);
  }

  void _onPlusTap() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SpecEntryScreen.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text(
              'Add an extra component',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'For users with mixed types (e.g., M.2 + SATA)',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.sd_storage_outlined,
                color: Colors.white70,
              ),
              title: const Text(
                'Add another Storage',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _showSecondaryStorage
                    ? 'Already added'
                    : 'For a second drive of a different type',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              enabled: !_showSecondaryStorage,
              onTap: () => Navigator.pop(context, 'storage'),
            ),
            ListTile(
              leading: const Icon(
                Icons.videogame_asset_outlined,
                color: Colors.white70,
              ),
              title: const Text(
                'Add another GPU',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _showSecondaryGpu
                    ? 'Already added'
                    : 'For a second graphics card',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              enabled: !_showSecondaryGpu,
              onTap: () => Navigator.pop(context, 'gpu'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == 'storage') {
      setState(() => _showSecondaryStorage = true);
    } else if (picked == 'gpu') {
      setState(() => _showSecondaryGpu = true);
    }
  }

  void _removeSecondaryGpu() {
    setState(() {
      _showSecondaryGpu = false;
      _gpuBrand2 = null;
      _gpuModel2 = null;
      _gpuQuantity2 = null;
    });
  }

  void _removeSecondaryStorage() {
    setState(() {
      _showSecondaryStorage = false;
      _storageType2 = null;
      _storageSize2 = null;
      _storageQuantity2 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecEntryScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              const _HeroBlock(),
              const SizedBox(height: 20),
              _CpuCard(
                brand: _cpuBrand,
                socket: _cpuSocket,
                model: _cpuModel,
                onBrandChanged: (v) => setState(() {
                  _cpuBrand = v;
                  _cpuSocket = null;
                  _cpuModel = null;
                }),
                onSocketChanged: (v) => setState(() {
                  _cpuSocket = v;
                  _cpuModel = null;
                  _moboChipset = null;
                  _ramModule = null;
                }),
                onModelChanged: (v) => setState(() => _cpuModel = v),
              ),
              const SizedBox(height: 14),
              _MoboCard(
                socket: _cpuSocket,
                chipset: _moboChipset,
                size: _moboSize,
                onChipsetChanged: (v) => setState(() {
                  _moboChipset = v;
                  _ramModule = null;
                }),
                onSizeChanged: (v) => setState(() => _moboSize = v),
              ),
              const SizedBox(height: 14),
              _GpuCard(
                brand: _gpuBrand,
                model: _gpuModel,
                quantity: _gpuQuantity,
                onBrandChanged: (v) => setState(() {
                  _gpuBrand = v;
                  _gpuModel = null;
                }),
                onModelChanged: (v) => setState(() => _gpuModel = v),
                onQuantityChanged: (v) => setState(() => _gpuQuantity = v),
              ),
              if (_showSecondaryGpu) ...[
                const SizedBox(height: 14),
                _GpuCard(
                  title: 'GPU (secondary)',
                  brand: _gpuBrand2,
                  model: _gpuModel2,
                  quantity: _gpuQuantity2,
                  onBrandChanged: (v) => setState(() {
                    _gpuBrand2 = v;
                    _gpuModel2 = null;
                  }),
                  onModelChanged: (v) => setState(() => _gpuModel2 = v),
                  onQuantityChanged: (v) => setState(() => _gpuQuantity2 = v),
                  onRemove: _removeSecondaryGpu,
                ),
              ],
              const SizedBox(height: 14),
              _RamCard(
                ramType: _inferredRamType,
                module: _ramModule,
                quantity: _ramQuantity,
                onModuleChanged: (v) => setState(() => _ramModule = v),
                onQuantityChanged: (v) => setState(() => _ramQuantity = v),
              ),
              const SizedBox(height: 14),
              _StorageCard(
                type: _storageType,
                size: _storageSize,
                quantity: _storageQuantity,
                onTypeChanged: (v) => setState(() => _storageType = v),
                onSizeChanged: (v) => setState(() => _storageSize = v),
                onQuantityChanged: (v) => setState(() => _storageQuantity = v),
              ),
              if (_showSecondaryStorage) ...[
                const SizedBox(height: 14),
                _StorageCard(
                  title: 'Storage (secondary)',
                  type: _storageType2,
                  size: _storageSize2,
                  quantity: _storageQuantity2,
                  onTypeChanged: (v) => setState(() => _storageType2 = v),
                  onSizeChanged: (v) => setState(() => _storageSize2 = v),
                  onQuantityChanged: (v) =>
                      setState(() => _storageQuantity2 = v),
                  onRemove: _removeSecondaryStorage,
                ),
              ],
              const SizedBox(height: 14),
              _PsuCard(
                watts: _psuWatts,
                onChanged: (v) => setState(() => _psuWatts = v),
              ),
              const SizedBox(height: 18),
              Center(
                child: Material(
                  color: SpecEntryScreen.iconBg,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _onPlusTap,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpecEntryScreen.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Save & Continue'),
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
          color: SpecEntryScreen.iconBg,
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
        color: SpecEntryScreen.iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ---------- Hero ----------

class _HeroBlock extends StatelessWidget {
  const _HeroBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.developer_board_outlined,
          color: Colors.white,
          size: 56,
        ),
        SizedBox(height: 12),
        Text(
          'Tell us about your PC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            "Enter your specs here. We'll filter upgrade options that fit your current build",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ---------- Generic spec card shell ----------

class _SpecCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onRemove;

  const _SpecCard({
    required this.icon,
    required this.title,
    required this.child,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SpecEntryScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------- Reusable labeled dropdown ----------

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: SpecEntryScreen.dropdownBg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: SpecEntryScreen.dropdownBg,
              iconEnabledColor: Colors.white70,
              iconDisabledColor: Colors.white24,
              hint: Text(
                hint,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(
                          display(e),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- CPU card ----------

class _CpuCard extends StatelessWidget {
  final String? brand;
  final CpuSocket? socket;
  final String? model;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<CpuSocket?> onSocketChanged;
  final ValueChanged<String?> onModelChanged;

  const _CpuCard({
    required this.brand,
    required this.socket,
    required this.model,
    required this.onBrandChanged,
    required this.onSocketChanged,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sockets =
        brand == null ? <CpuSocket>[] : cpuSocketsByBrand[brand!] ?? [];
    final models =
        socket == null ? <String>[] : cpuModelsBySocket[socket!] ?? [];
    return _SpecCard(
      icon: Icons.memory,
      title: 'Processor (CPU)',
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<String>(
              label: 'Brand',
              hint: 'Select Brand',
              value: brand,
              items: cpuBrands,
              display: (e) => e,
              onChanged: onBrandChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<CpuSocket>(
              label: 'Socket',
              hint: 'Select Socket',
              value: socket,
              items: sockets,
              display: (e) => e.label,
              onChanged: onSocketChanged,
              enabled: brand != null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<String>(
              label: 'Model',
              hint: 'Select Model',
              value: model,
              items: models,
              display: (e) => e,
              onChanged: onModelChanged,
              enabled: socket != null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Motherboard card ----------

class _MoboCard extends StatelessWidget {
  final CpuSocket? socket;
  final String? chipset;
  final String? size;
  final ValueChanged<String?> onChipsetChanged;
  final ValueChanged<String?> onSizeChanged;

  const _MoboCard({
    required this.socket,
    required this.chipset,
    required this.size,
    required this.onChipsetChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chipsets = socket == null
        ? <String>[]
        : motherboardChipsetsBySocket[socket!] ?? [];
    return _SpecCard(
      icon: Icons.developer_board,
      title: 'Motherboard',
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<String>(
              label: 'Model Type',
              hint: 'Select Type',
              value: chipset,
              items: chipsets,
              display: (e) => e,
              onChanged: onChipsetChanged,
              enabled: socket != null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<String>(
              label: 'Size',
              hint: 'Select Size',
              value: size,
              items: motherboardSizes,
              display: (e) => e,
              onChanged: onSizeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- GPU card ----------

class _GpuCard extends StatelessWidget {
  final String title;
  final String? brand;
  final String? model;
  final int? quantity;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<int?> onQuantityChanged;
  final VoidCallback? onRemove;

  const _GpuCard({
    this.title = 'GPU',
    required this.brand,
    required this.model,
    required this.quantity,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final models = brand == null ? <String>[] : gpuModelsByBrand[brand!] ?? [];
    return _SpecCard(
      icon: Icons.videogame_asset_outlined,
      title: title,
      onRemove: onRemove,
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<String>(
              label: 'Brand',
              hint: 'Select Brand',
              value: brand,
              items: gpuBrands,
              display: (e) => e,
              onChanged: onBrandChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<String>(
              label: 'Graphics Card',
              hint: 'Select GPU',
              value: model,
              items: models,
              display: (e) => e,
              onChanged: onModelChanged,
              enabled: brand != null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<int>(
              label: 'Quantity',
              hint: 'Quantity',
              value: quantity,
              items: componentQuantities,
              display: (e) => '$e',
              onChanged: onQuantityChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- RAM card ----------

class _RamCard extends StatelessWidget {
  final RamType? ramType;
  final String? module;
  final int? quantity;
  final ValueChanged<String?> onModuleChanged;
  final ValueChanged<int?> onQuantityChanged;

  const _RamCard({
    required this.ramType,
    required this.module,
    required this.quantity,
    required this.onModuleChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modules =
        ramType == null ? <String>[] : ramModulesByType[ramType!] ?? [];
    return _SpecCard(
      icon: Icons.view_module,
      title: 'RAM',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _Dropdown<String>(
              label: 'Memory Module',
              hint: ramType == null
                  ? 'Select Motherboard first'
                  : 'Select Memory Module',
              value: module,
              items: modules,
              display: (e) => e,
              onChanged: onModuleChanged,
              enabled: ramType != null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<int>(
              label: 'Quantity',
              hint: 'Quantity',
              value: quantity,
              items: componentQuantities,
              display: (e) => '$e',
              onChanged: onQuantityChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Storage card ----------

class _StorageCard extends StatelessWidget {
  final String title;
  final String? type;
  final String? size;
  final int? quantity;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onSizeChanged;
  final ValueChanged<int?> onQuantityChanged;
  final VoidCallback? onRemove;

  const _StorageCard({
    this.title = 'Storage',
    required this.type,
    required this.size,
    required this.quantity,
    required this.onTypeChanged,
    required this.onSizeChanged,
    required this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SpecCard(
      icon: Icons.sd_storage_outlined,
      title: title,
      onRemove: onRemove,
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<String>(
              label: 'Type',
              hint: 'Select Type',
              value: type,
              items: storageTypes,
              display: (e) => e,
              onChanged: onTypeChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<String>(
              label: 'Size',
              hint: 'Select Size',
              value: size,
              items: storageSizes,
              display: (e) => e,
              onChanged: onSizeChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown<int>(
              label: 'Quantity',
              hint: 'Quantity',
              value: quantity,
              items: componentQuantities,
              display: (e) => '$e',
              onChanged: onQuantityChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- PSU card ----------

class _PsuCard extends StatelessWidget {
  final int? watts;
  final ValueChanged<int?> onChanged;

  const _PsuCard({required this.watts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SpecCard(
      icon: Icons.bolt_outlined,
      title: 'Power Supply (PSU)',
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<int>(
              label: 'Wattage',
              hint: 'Select Wattage',
              value: watts,
              items: psuWattages,
              display: (e) => '${e}W',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
