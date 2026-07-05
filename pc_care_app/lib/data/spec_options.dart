import '../models/pc_specs.dart';

/// Curated data tables for the spec entry cascading dropdowns.
/// Not exhaustive — common popular options per category.

// ---------- CPU ----------

const List<String> cpuBrands = ['AMD', 'Intel'];

const Map<String, List<CpuSocket>> cpuSocketsByBrand = {
  'AMD': [CpuSocket.am4, CpuSocket.am5],
  'Intel': [CpuSocket.lga1155, CpuSocket.lga1200, CpuSocket.lga1700],
};

const Map<CpuSocket, List<String>> cpuModelsBySocket = {
  CpuSocket.am4: [
    'Ryzen 3 3100',
    'Ryzen 5 3600',
    'Ryzen 5 5600',
    'Ryzen 5 5600X',
    'Ryzen 7 3700X',
    'Ryzen 7 5700X',
    'Ryzen 7 5800X',
    'Ryzen 7 5800X3D',
    'Ryzen 9 5900X',
    'Ryzen 9 5950X',
  ],
  CpuSocket.am5: [
    'Ryzen 5 7600',
    'Ryzen 5 7600X',
    'Ryzen 7 7700',
    'Ryzen 7 7700X',
    'Ryzen 7 7800X3D',
    'Ryzen 9 7900X',
    'Ryzen 9 7950X',
    'Ryzen 9 7950X3D',
  ],
  CpuSocket.lga1155: [
    'Core i3-3220',
    'Core i5-3470',
    'Core i5-3570K',
    'Core i7-3770',
    'Core i7-3770K',
  ],
  CpuSocket.lga1200: [
    'Core i3-10100',
    'Core i5-10400',
    'Core i5-11400',
    'Core i7-10700K',
    'Core i7-11700K',
    'Core i9-10900K',
    'Core i9-11900K',
  ],
  CpuSocket.lga1700: [
    'Core i3-12100',
    'Core i5-12400',
    'Core i5-13400',
    'Core i5-13600K',
    'Core i7-12700K',
    'Core i7-13700K',
    'Core i9-12900K',
    'Core i9-13900K',
    'Core i9-14900K',
  ],
};

// ---------- Motherboard ----------

const Map<CpuSocket, List<String>> motherboardChipsetsBySocket = {
  CpuSocket.am4: ['A320', 'A520', 'B450', 'B550', 'X470', 'X570'],
  CpuSocket.am5: ['A620', 'B650', 'B650E', 'X670', 'X670E'],
  CpuSocket.lga1155: ['H61', 'B75', 'H77', 'Z77'],
  CpuSocket.lga1200: ['H410', 'B460', 'B560', 'H570', 'Z490', 'Z590'],
  CpuSocket.lga1700: ['H610', 'B660', 'B760', 'Z690', 'Z790'],
};

const List<String> motherboardSizes = [
  'Mini-ITX',
  'mATX',
  'ATX',
  'eATX',
];

/// Determines which RAM type a chipset supports.
const Map<String, RamType> ramTypeByChipset = {
  // AM4 → DDR4
  'A320': RamType.ddr4,
  'A520': RamType.ddr4,
  'B450': RamType.ddr4,
  'B550': RamType.ddr4,
  'X470': RamType.ddr4,
  'X570': RamType.ddr4,
  // AM5 → DDR5
  'A620': RamType.ddr5,
  'B650': RamType.ddr5,
  'B650E': RamType.ddr5,
  'X670': RamType.ddr5,
  'X670E': RamType.ddr5,
  // LGA1155 → DDR3
  'H61': RamType.ddr3,
  'B75': RamType.ddr3,
  'H77': RamType.ddr3,
  'Z77': RamType.ddr3,
  // LGA1200 → DDR4
  'H410': RamType.ddr4,
  'B460': RamType.ddr4,
  'B560': RamType.ddr4,
  'H570': RamType.ddr4,
  'Z490': RamType.ddr4,
  'Z590': RamType.ddr4,
  // LGA1700 → mix (defaulting to DDR5 for top-tier chipsets, DDR4 for budget)
  'H610': RamType.ddr4,
  'B660': RamType.ddr4,
  'B760': RamType.ddr5,
  'Z690': RamType.ddr5,
  'Z790': RamType.ddr5,
};

// ---------- GPU ----------

const List<String> gpuBrands = ['NVIDIA GeForce', 'AMD Radeon', 'Intel Arc'];

const Map<String, List<String>> gpuModelsByBrand = {
  'NVIDIA GeForce': [
    'GTX 1650',
    'GTX 1660',
    'GTX 1660 Super',
    'RTX 3050',
    'RTX 3060',
    'RTX 3060 Ti',
    'RTX 3070',
    'RTX 3080',
    'RTX 3090',
    'RTX 4060',
    'RTX 4060 Ti',
    'RTX 4070',
    'RTX 4070 Super',
    'RTX 4070 Ti',
    'RTX 4080',
    'RTX 4090',
  ],
  'AMD Radeon': [
    'RX 580',
    'RX 5600 XT',
    'RX 5700 XT',
    'RX 6600',
    'RX 6700 XT',
    'RX 6800',
    'RX 6900 XT',
    'RX 7600',
    'RX 7700 XT',
    'RX 7800 XT',
    'RX 7900 XT',
    'RX 7900 XTX',
  ],
  'Intel Arc': [
    'Arc A380',
    'Arc A580',
    'Arc A750',
    'Arc A770',
  ],
};

// ---------- RAM ----------

const Map<RamType, List<String>> ramModulesByType = {
  RamType.ddr3: [
    '4GB DDR3 1600MHz',
    '8GB DDR3 1600MHz',
    '8GB DDR3 1866MHz',
    '16GB DDR3 1600MHz',
  ],
  RamType.ddr4: [
    '8GB DDR4 2400MHz',
    '8GB DDR4 3000MHz',
    '8GB DDR4 3200MHz',
    '16GB DDR4 2666MHz',
    '16GB DDR4 3000MHz',
    '16GB DDR4 3200MHz',
    '16GB DDR4 3600MHz',
    '32GB DDR4 3200MHz',
    '32GB DDR4 3600MHz',
    '64GB DDR4 3200MHz',
  ],
  RamType.ddr5: [
    '16GB DDR5 4800MHz',
    '16GB DDR5 5200MHz',
    '32GB DDR5 5200MHz',
    '32GB DDR5 6000MHz',
    '32GB DDR5 6400MHz',
    '64GB DDR5 5600MHz',
    '64GB DDR5 6000MHz',
  ],
};

// ---------- Storage ----------

const List<String> storageTypes = [
  'HDD',
  'SATA SSD',
  'M.2 SATA',
  'NVMe M.2',
];

const List<String> storageSizes = [
  '128GB',
  '256GB',
  '500GB',
  '1TB',
  '2TB',
  '4TB',
  '8TB',
];

// ---------- PSU ----------

const List<int> psuWattages = [
  300,
  400,
  500,
  600,
  650,
  750,
  850,
  1000,
  1200,
  1500,
];

// ---------- Quantities (for GPU / RAM / Storage) ----------

const List<int> componentQuantities = [1, 2, 3, 4];
