enum CpuSocket {
  am4('AM4'),
  am5('AM5'),
  lga1155('LGA1155'),
  lga1200('LGA1200'),
  lga1700('LGA1700');

  const CpuSocket(this.label);

  final String label;

  static CpuSocket? fromLabel(String? label) {
    if (label == null) return null;
    for (final s in CpuSocket.values) {
      if (s.label == label) return s;
    }
    return null;
  }
}

enum RamType {
  ddr3('DDR3'),
  ddr4('DDR4'),
  ddr5('DDR5');

  const RamType(this.label);

  final String label;

  static RamType? fromLabel(String? label) {
    if (label == null) return null;
    for (final t in RamType.values) {
      if (t.label == label) return t;
    }
    return null;
  }
}

class CpuOption {
  final String name;
  final String brand;
  final CpuSocket socket;
  final int cores;
  final int threads;
  final double baseGhz;
  final int tdpWatts;

  const CpuOption({
    required this.name,
    required this.brand,
    required this.socket,
    required this.cores,
    required this.threads,
    required this.baseGhz,
    required this.tdpWatts,
  });

  String get summary => '$cores cores / $threads threads, ${baseGhz}GHz base';
}

class GpuOption {
  final String name;
  final String brand;
  final int vramGb;
  final int powerWatts;
  final int recommendedPsuWatts;

  const GpuOption({
    required this.name,
    required this.brand,
    required this.vramGb,
    required this.powerWatts,
    required this.recommendedPsuWatts,
  });

  String get summary =>
      '${vramGb}GB VRAM, ${powerWatts}W TDP, ${recommendedPsuWatts}W PSU recommended';
}

class RamOption {
  final String name;
  final RamType type;
  final int capacityGb;
  final int speedMhz;
  final int kitCount;

  const RamOption({
    required this.name,
    required this.type,
    required this.capacityGb,
    required this.speedMhz,
    this.kitCount = 1,
  });

  String get summary =>
      '${capacityGb}GB ${type.label} @ ${speedMhz}MHz${kitCount > 1 ? ' (${kitCount}-stick kit)' : ''}';
}

class StorageOption {
  final String name;
  final String brand;
  final StorageKind kind;
  final int capacityGb;

  const StorageOption({
    required this.name,
    required this.brand,
    required this.kind,
    required this.capacityGb,
  });

  String get summary {
    final capacity = capacityGb >= 1000
        ? '${(capacityGb / 1000).toStringAsFixed(capacityGb % 1000 == 0 ? 0 : 1)}TB'
        : '${capacityGb}GB';
    return '$capacity, ${kind.label}';
  }
}

enum StorageKind {
  hdd('HDD (Hard Drive)'),
  sataSsd('SATA SSD'),
  nvmeSsd('NVMe SSD');

  const StorageKind(this.label);

  final String label;
}

class PcSpecs {
  final String? cpuBrand;
  final String? cpuName;
  final String? gpuBrand;
  final String? gpuName;
  final int? gpuQuantity;
  // Optional second GPU (e.g., dual-GPU build w/ different brand/model).
  final String? secondaryGpuBrand;
  final String? secondaryGpuName;
  final int? secondaryGpuQuantity;
  final String? ramName;
  final int? ramQuantity;
  final String? storageName;
  final String? storageType;
  final int? storageQuantity;
  // Optional second storage drive (e.g., M.2 NVMe primary + SATA SSD secondary).
  final String? secondaryStorageName;
  final String? secondaryStorageType;
  final int? secondaryStorageQuantity;
  final CpuSocket? motherboardSocket;
  final RamType? motherboardRamType;
  final String? motherboardName;
  final String? motherboardSize;
  final int? psuWatts;

  const PcSpecs({
    this.cpuBrand,
    this.cpuName,
    this.gpuBrand,
    this.gpuName,
    this.gpuQuantity,
    this.secondaryGpuBrand,
    this.secondaryGpuName,
    this.secondaryGpuQuantity,
    this.ramName,
    this.ramQuantity,
    this.storageName,
    this.storageType,
    this.storageQuantity,
    this.secondaryStorageName,
    this.secondaryStorageType,
    this.secondaryStorageQuantity,
    this.motherboardSocket,
    this.motherboardRamType,
    this.motherboardName,
    this.motherboardSize,
    this.psuWatts,
  });

  bool get hasSecondaryGpu =>
      secondaryGpuBrand != null || secondaryGpuName != null;
  bool get hasSecondaryStorage =>
      secondaryStorageType != null || secondaryStorageName != null;

  bool get isComplete =>
      cpuName != null &&
      gpuName != null &&
      ramName != null &&
      storageName != null &&
      motherboardSocket != null &&
      motherboardRamType != null &&
      psuWatts != null;

  PcSpecs copyWith({
    String? cpuBrand,
    String? cpuName,
    String? gpuBrand,
    String? gpuName,
    int? gpuQuantity,
    String? secondaryGpuBrand,
    String? secondaryGpuName,
    int? secondaryGpuQuantity,
    String? ramName,
    int? ramQuantity,
    String? storageName,
    String? storageType,
    int? storageQuantity,
    String? secondaryStorageName,
    String? secondaryStorageType,
    int? secondaryStorageQuantity,
    CpuSocket? motherboardSocket,
    RamType? motherboardRamType,
    String? motherboardName,
    String? motherboardSize,
    int? psuWatts,
  }) {
    return PcSpecs(
      cpuBrand: cpuBrand ?? this.cpuBrand,
      cpuName: cpuName ?? this.cpuName,
      gpuBrand: gpuBrand ?? this.gpuBrand,
      gpuName: gpuName ?? this.gpuName,
      gpuQuantity: gpuQuantity ?? this.gpuQuantity,
      secondaryGpuBrand: secondaryGpuBrand ?? this.secondaryGpuBrand,
      secondaryGpuName: secondaryGpuName ?? this.secondaryGpuName,
      secondaryGpuQuantity: secondaryGpuQuantity ?? this.secondaryGpuQuantity,
      ramName: ramName ?? this.ramName,
      ramQuantity: ramQuantity ?? this.ramQuantity,
      storageName: storageName ?? this.storageName,
      storageType: storageType ?? this.storageType,
      storageQuantity: storageQuantity ?? this.storageQuantity,
      secondaryStorageName: secondaryStorageName ?? this.secondaryStorageName,
      secondaryStorageType: secondaryStorageType ?? this.secondaryStorageType,
      secondaryStorageQuantity:
          secondaryStorageQuantity ?? this.secondaryStorageQuantity,
      motherboardSocket: motherboardSocket ?? this.motherboardSocket,
      motherboardRamType: motherboardRamType ?? this.motherboardRamType,
      motherboardName: motherboardName ?? this.motherboardName,
      motherboardSize: motherboardSize ?? this.motherboardSize,
      psuWatts: psuWatts ?? this.psuWatts,
    );
  }

  Map<String, dynamic> toJson() => {
        'cpuBrand': cpuBrand,
        'cpuName': cpuName,
        'gpuBrand': gpuBrand,
        'gpuName': gpuName,
        'gpuQuantity': gpuQuantity,
        'secondaryGpuBrand': secondaryGpuBrand,
        'secondaryGpuName': secondaryGpuName,
        'secondaryGpuQuantity': secondaryGpuQuantity,
        'ramName': ramName,
        'ramQuantity': ramQuantity,
        'storageName': storageName,
        'storageType': storageType,
        'storageQuantity': storageQuantity,
        'secondaryStorageName': secondaryStorageName,
        'secondaryStorageType': secondaryStorageType,
        'secondaryStorageQuantity': secondaryStorageQuantity,
        'motherboardSocket': motherboardSocket?.label,
        'motherboardRamType': motherboardRamType?.label,
        'motherboardName': motherboardName,
        'motherboardSize': motherboardSize,
        'psuWatts': psuWatts,
      };

  factory PcSpecs.fromJson(Map<String, dynamic> json) => PcSpecs(
        cpuBrand: json['cpuBrand'] as String?,
        cpuName: json['cpuName'] as String?,
        gpuBrand: json['gpuBrand'] as String?,
        gpuName: json['gpuName'] as String?,
        gpuQuantity: json['gpuQuantity'] as int?,
        secondaryGpuBrand: json['secondaryGpuBrand'] as String?,
        secondaryGpuName: json['secondaryGpuName'] as String?,
        secondaryGpuQuantity: json['secondaryGpuQuantity'] as int?,
        ramName: json['ramName'] as String?,
        ramQuantity: json['ramQuantity'] as int?,
        storageName: json['storageName'] as String?,
        storageType: json['storageType'] as String?,
        storageQuantity: json['storageQuantity'] as int?,
        secondaryStorageName: json['secondaryStorageName'] as String?,
        secondaryStorageType: json['secondaryStorageType'] as String?,
        secondaryStorageQuantity: json['secondaryStorageQuantity'] as int?,
        motherboardSocket:
            CpuSocket.fromLabel(json['motherboardSocket'] as String?),
        motherboardRamType:
            RamType.fromLabel(json['motherboardRamType'] as String?),
        motherboardName: json['motherboardName'] as String?,
        motherboardSize: json['motherboardSize'] as String?,
        psuWatts: json['psuWatts'] as int?,
      );

  static const empty = PcSpecs();
}
