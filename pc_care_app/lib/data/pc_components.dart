import '../models/pc_specs.dart';

const List<CpuOption> availableCpus = [
  // AMD AM4
  CpuOption(
    name: 'AMD Ryzen 5 3600',
    brand: 'AMD',
    socket: CpuSocket.am4,
    cores: 6,
    threads: 12,
    baseGhz: 3.6,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'AMD Ryzen 5 5600',
    brand: 'AMD',
    socket: CpuSocket.am4,
    cores: 6,
    threads: 12,
    baseGhz: 3.5,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'AMD Ryzen 5 5600X',
    brand: 'AMD',
    socket: CpuSocket.am4,
    cores: 6,
    threads: 12,
    baseGhz: 3.7,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'AMD Ryzen 7 5800X',
    brand: 'AMD',
    socket: CpuSocket.am4,
    cores: 8,
    threads: 16,
    baseGhz: 3.8,
    tdpWatts: 105,
  ),
  CpuOption(
    name: 'AMD Ryzen 7 5800X3D',
    brand: 'AMD',
    socket: CpuSocket.am4,
    cores: 8,
    threads: 16,
    baseGhz: 3.4,
    tdpWatts: 105,
  ),

  // AMD AM5
  CpuOption(
    name: 'AMD Ryzen 5 7600',
    brand: 'AMD',
    socket: CpuSocket.am5,
    cores: 6,
    threads: 12,
    baseGhz: 3.8,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'AMD Ryzen 7 7700X',
    brand: 'AMD',
    socket: CpuSocket.am5,
    cores: 8,
    threads: 16,
    baseGhz: 4.5,
    tdpWatts: 105,
  ),
  CpuOption(
    name: 'AMD Ryzen 7 7800X3D',
    brand: 'AMD',
    socket: CpuSocket.am5,
    cores: 8,
    threads: 16,
    baseGhz: 4.2,
    tdpWatts: 120,
  ),

  // Intel LGA1700
  CpuOption(
    name: 'Intel Core i5-12400F',
    brand: 'Intel',
    socket: CpuSocket.lga1700,
    cores: 6,
    threads: 12,
    baseGhz: 2.5,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'Intel Core i5-13600K',
    brand: 'Intel',
    socket: CpuSocket.lga1700,
    cores: 14,
    threads: 20,
    baseGhz: 3.5,
    tdpWatts: 125,
  ),
  CpuOption(
    name: 'Intel Core i7-13700K',
    brand: 'Intel',
    socket: CpuSocket.lga1700,
    cores: 16,
    threads: 24,
    baseGhz: 3.4,
    tdpWatts: 125,
  ),

  // Intel LGA1200 (10th/11th gen)
  CpuOption(
    name: 'Intel Core i5-10400F',
    brand: 'Intel',
    socket: CpuSocket.lga1200,
    cores: 6,
    threads: 12,
    baseGhz: 2.9,
    tdpWatts: 65,
  ),
  CpuOption(
    name: 'Intel Core i7-11700K',
    brand: 'Intel',
    socket: CpuSocket.lga1200,
    cores: 8,
    threads: 16,
    baseGhz: 3.6,
    tdpWatts: 125,
  ),

  // Intel LGA1155 (Ivy Bridge — for your hardware)
  CpuOption(
    name: 'Intel Core i5-3570',
    brand: 'Intel',
    socket: CpuSocket.lga1155,
    cores: 4,
    threads: 4,
    baseGhz: 3.4,
    tdpWatts: 77,
  ),
  CpuOption(
    name: 'Intel Core i7-3770',
    brand: 'Intel',
    socket: CpuSocket.lga1155,
    cores: 4,
    threads: 8,
    baseGhz: 3.4,
    tdpWatts: 77,
  ),
  CpuOption(
    name: 'Intel Core i7-3770K',
    brand: 'Intel',
    socket: CpuSocket.lga1155,
    cores: 4,
    threads: 8,
    baseGhz: 3.5,
    tdpWatts: 77,
  ),
];

const List<GpuOption> availableGpus = [
  // NVIDIA
  GpuOption(
    name: 'NVIDIA GeForce GTX 1660 Super',
    brand: 'NVIDIA',
    vramGb: 6,
    powerWatts: 125,
    recommendedPsuWatts: 450,
  ),
  GpuOption(
    name: 'NVIDIA GeForce RTX 3060',
    brand: 'NVIDIA',
    vramGb: 12,
    powerWatts: 170,
    recommendedPsuWatts: 550,
  ),
  GpuOption(
    name: 'NVIDIA GeForce RTX 3070',
    brand: 'NVIDIA',
    vramGb: 8,
    powerWatts: 220,
    recommendedPsuWatts: 650,
  ),
  GpuOption(
    name: 'NVIDIA GeForce RTX 4060',
    brand: 'NVIDIA',
    vramGb: 8,
    powerWatts: 115,
    recommendedPsuWatts: 550,
  ),
  GpuOption(
    name: 'NVIDIA GeForce RTX 4070',
    brand: 'NVIDIA',
    vramGb: 12,
    powerWatts: 200,
    recommendedPsuWatts: 650,
  ),
  GpuOption(
    name: 'NVIDIA GeForce RTX 4080',
    brand: 'NVIDIA',
    vramGb: 16,
    powerWatts: 320,
    recommendedPsuWatts: 750,
  ),

  // AMD
  GpuOption(
    name: 'AMD Radeon RX 6600',
    brand: 'AMD',
    vramGb: 8,
    powerWatts: 132,
    recommendedPsuWatts: 500,
  ),
  GpuOption(
    name: 'AMD Radeon RX 6700 XT',
    brand: 'AMD',
    vramGb: 12,
    powerWatts: 230,
    recommendedPsuWatts: 650,
  ),
  GpuOption(
    name: 'AMD Radeon RX 7600',
    brand: 'AMD',
    vramGb: 8,
    powerWatts: 165,
    recommendedPsuWatts: 550,
  ),
  GpuOption(
    name: 'AMD Radeon RX 7700 XT',
    brand: 'AMD',
    vramGb: 12,
    powerWatts: 245,
    recommendedPsuWatts: 700,
  ),
  GpuOption(
    name: 'AMD Radeon RX 7800 XT',
    brand: 'AMD',
    vramGb: 16,
    powerWatts: 263,
    recommendedPsuWatts: 700,
  ),
];

const List<RamOption> availableRam = [
  // DDR3 (for old systems like LGA1155)
  RamOption(
    name: 'Kingston HyperX Fury 8GB DDR3-1600',
    type: RamType.ddr3,
    capacityGb: 8,
    speedMhz: 1600,
  ),
  RamOption(
    name: 'Corsair Vengeance 16GB (2x8GB) DDR3-1600',
    type: RamType.ddr3,
    capacityGb: 16,
    speedMhz: 1600,
    kitCount: 2,
  ),

  // DDR4
  RamOption(
    name: 'Corsair Vengeance LPX 16GB (2x8GB) DDR4-3200',
    type: RamType.ddr4,
    capacityGb: 16,
    speedMhz: 3200,
    kitCount: 2,
  ),
  RamOption(
    name: 'G.Skill Ripjaws V 16GB (2x8GB) DDR4-3600',
    type: RamType.ddr4,
    capacityGb: 16,
    speedMhz: 3600,
    kitCount: 2,
  ),
  RamOption(
    name: 'Corsair Vengeance LPX 32GB (2x16GB) DDR4-3200',
    type: RamType.ddr4,
    capacityGb: 32,
    speedMhz: 3200,
    kitCount: 2,
  ),
  RamOption(
    name: 'G.Skill Trident Z 32GB (2x16GB) DDR4-3600',
    type: RamType.ddr4,
    capacityGb: 32,
    speedMhz: 3600,
    kitCount: 2,
  ),

  // DDR5
  RamOption(
    name: 'Corsair Vengeance 32GB (2x16GB) DDR5-5200',
    type: RamType.ddr5,
    capacityGb: 32,
    speedMhz: 5200,
    kitCount: 2,
  ),
  RamOption(
    name: 'G.Skill Trident Z5 32GB (2x16GB) DDR5-6000',
    type: RamType.ddr5,
    capacityGb: 32,
    speedMhz: 6000,
    kitCount: 2,
  ),
  RamOption(
    name: 'Corsair Dominator 64GB (2x32GB) DDR5-6000',
    type: RamType.ddr5,
    capacityGb: 64,
    speedMhz: 6000,
    kitCount: 2,
  ),
];

const List<StorageOption> availableStorage = [
  // HDD
  StorageOption(
    name: 'Seagate BarraCuda 2TB',
    brand: 'Seagate',
    kind: StorageKind.hdd,
    capacityGb: 2000,
  ),
  StorageOption(
    name: 'WD Blue 4TB',
    brand: 'Western Digital',
    kind: StorageKind.hdd,
    capacityGb: 4000,
  ),

  // SATA SSD
  StorageOption(
    name: 'Crucial MX500 500GB',
    brand: 'Crucial',
    kind: StorageKind.sataSsd,
    capacityGb: 500,
  ),
  StorageOption(
    name: 'Samsung 870 EVO 1TB',
    brand: 'Samsung',
    kind: StorageKind.sataSsd,
    capacityGb: 1000,
  ),
  StorageOption(
    name: 'Samsung 870 EVO 2TB',
    brand: 'Samsung',
    kind: StorageKind.sataSsd,
    capacityGb: 2000,
  ),

  // NVMe SSD
  StorageOption(
    name: 'Samsung 980 1TB NVMe',
    brand: 'Samsung',
    kind: StorageKind.nvmeSsd,
    capacityGb: 1000,
  ),
  StorageOption(
    name: 'WD Black SN850X 1TB NVMe',
    brand: 'Western Digital',
    kind: StorageKind.nvmeSsd,
    capacityGb: 1000,
  ),
  StorageOption(
    name: 'Samsung 990 Pro 2TB NVMe',
    brand: 'Samsung',
    kind: StorageKind.nvmeSsd,
    capacityGb: 2000,
  ),
  StorageOption(
    name: 'WD Black SN850X 4TB NVMe',
    brand: 'Western Digital',
    kind: StorageKind.nvmeSsd,
    capacityGb: 4000,
  ),
];

const List<int> availablePsuWattages = [
  450,
  500,
  550,
  650,
  750,
  850,
  1000,
  1200,
];
