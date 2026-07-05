import 'package:flutter/material.dart';

enum GuideCategory {
  installation('Installation', Icons.build_outlined),
  troubleshooting('Troubleshooting', Icons.healing_outlined);

  const GuideCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class MaintenanceGuide {
  final String id;
  final String title;
  final String shortDescription;
  final IconData icon;
  final GuideCategory category;
  final String component;
  final List<String> requiredComponents;
  final String? safetyNote;
  final List<String> steps;

  const MaintenanceGuide({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.icon,
    required this.category,
    required this.component,
    required this.requiredComponents,
    required this.steps,
    this.safetyNote,
  });
}

const String _powerSafetyNote =
    'Always power off the PC, unplug the power cable, and discharge residual current by holding the power button for 5 seconds before working inside the case. Avoid static — touch a metal part of the case before handling components.';

const List<MaintenanceGuide> motherboardGuides = [
  // ─────────────────────────────────────────────
  // INSTALLATION
  // ─────────────────────────────────────────────
  MaintenanceGuide(
    id: 'install_cpu',
    title: 'Install CPU',
    shortDescription: 'Seat a CPU into the LGA socket and lock the lever.',
    icon: Icons.memory_outlined,
    category: GuideCategory.installation,
    component: 'motherboard',
    requiredComponents: ['motherboard'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Lay the motherboard flat on a non-conductive surface (anti-static bag or its box).',
      'Locate the CPU socket (large square with pins or contacts) and lift the metal retention lever next to it.',
      'Open the load plate and remove the black plastic socket cover. Save it — reuse if you ever ship the board.',
      'Identify the gold triangle on one corner of the CPU. Match it to the matching triangle on the socket.',
      'Gently lower the CPU straight down into the socket. Do NOT force or wiggle — it should sit flat with no pressure.',
      'Close the load plate over the CPU and lower the retention lever back into its locked position.',
      'Apply a pea-sized drop of thermal paste in the center of the CPU, then mount the cooler on top.',
    ],
  ),
  MaintenanceGuide(
    id: 'install_ram',
    title: 'Install RAM',
    shortDescription: 'Seat memory sticks into the DIMM slots correctly.',
    icon: Icons.view_module_outlined,
    category: GuideCategory.installation,
    component: 'motherboard',
    requiredComponents: ['motherboard'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Locate the DIMM slots — long thin slots usually right of the CPU socket.',
      'Push the locking clips at both ends of the slot outward to open them.',
      'Identify the notch on the bottom edge of the RAM stick. The slot has a matching ridge.',
      'Align the RAM with the slot — the notch must match. If it doesn\'t fit, you have it backwards.',
      'Press down firmly and evenly on both ends of the stick until the clips snap up into the locked position.',
      'For dual channel: install matching sticks in slots of the same color (usually slots 2 and 4, but check your manual).',
      'Power on and verify in BIOS that all RAM is detected at the correct speed.',
    ],
  ),
  MaintenanceGuide(
    id: 'install_gpu',
    title: 'Install GPU',
    shortDescription: 'Seat a graphics card into the PCIe x16 slot.',
    icon: Icons.videogame_asset_outlined,
    category: GuideCategory.installation,
    component: 'motherboard',
    requiredComponents: ['motherboard'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Identify the top PCIe x16 slot (the longest one closest to the CPU).',
      'On your case, remove the metal slot covers behind the PCIe slot — usually 2 covers for a dual-slot card.',
      'Push the PCIe retention clip at the end of the slot down and outward to open it.',
      'Align the GPU with the slot, gold contacts facing down, display ports facing the case rear.',
      'Press down evenly until the GPU is fully seated — the retention clip will snap up.',
      'Screw the GPU bracket to the case to secure it.',
      'Connect required power cables from the PSU (typically 8-pin or 16-pin connectors on the top of the GPU).',
    ],
  ),
  MaintenanceGuide(
    id: 'install_nvme',
    title: 'Install M.2 NVMe SSD',
    shortDescription: 'Mount an NVMe drive into an M.2 slot under the heatsink.',
    icon: Icons.storage_outlined,
    category: GuideCategory.installation,
    component: 'motherboard',
    requiredComponents: ['motherboard'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Locate the M.2 slot — usually has a heatsink labeled "M.2" near the CPU or chipset.',
      'Remove the small screw holding the heatsink and lift it off. Peel the protective film from the thermal pad if present.',
      'Find the M.2 mounting standoff. If your motherboard uses a tool-less latch, skip the screw step later.',
      'Insert the NVMe drive at a ~30° angle into the slot — the notch on the drive must align with the slot key.',
      'Push gently until fully seated, then press the drive flat against the standoff.',
      'Secure the drive with the small M.2 screw (or click the latch).',
      'Replace the heatsink and reattach its screw. Boot and initialize the drive in Disk Management.',
    ],
  ),

  // ─────────────────────────────────────────────
  // TROUBLESHOOTING
  // ─────────────────────────────────────────────
  MaintenanceGuide(
    id: 'reseat_cmos',
    title: 'Reseat CMOS Battery',
    shortDescription: 'Reset BIOS settings by removing the coin battery.',
    icon: Icons.battery_alert_outlined,
    category: GuideCategory.troubleshooting,
    component: 'motherboard',
    requiredComponents: ['motherboard'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Locate the silver coin-shaped battery on the motherboard (CR2032).',
      'Use a small flathead screwdriver or your fingernail to gently push the metal retention clip away from the battery.',
      'The battery will pop up. Remove it carefully.',
      'Wait at least 30 seconds — this allows the BIOS to fully discharge and reset.',
      'Reinsert the battery with the "+" symbol facing UP (this matters).',
      'Press it down gently until the clip snaps back into place.',
      'Reconnect power and boot. Enter BIOS (usually DEL or F2) to reconfigure date, time, and any custom settings.',
    ],
  ),
  MaintenanceGuide(
    id: 'reseat_ram',
    title: 'Reseat RAM',
    shortDescription: 'Fix RAM detection issues by removing and reinstalling.',
    icon: Icons.refresh_outlined,
    category: GuideCategory.troubleshooting,
    component: 'motherboard',
    requiredComponents: ['motherboard', 'ram'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Open your case side panel and locate the RAM sticks.',
      'Push the locking clips at both ends of each RAM slot outward — the stick will rise up slightly.',
      'Lift each RAM stick straight up out of the slot.',
      'Inspect the gold contacts on the bottom of the stick. If dusty, gently wipe with a microfiber cloth — never touch contacts with bare fingers.',
      'Inspect the slot for dust. Use compressed air to blow it out if needed.',
      'Realign each stick — match the notch with the slot key — and press firmly until the clips snap up.',
      'Power on. If the issue persists, try one stick at a time in different slots to isolate a faulty stick or slot.',
    ],
  ),
  MaintenanceGuide(
    id: 'reseat_gpu',
    title: 'Reseat GPU',
    shortDescription: 'Fix GPU detection or display issues.',
    icon: Icons.refresh_outlined,
    category: GuideCategory.troubleshooting,
    component: 'motherboard',
    requiredComponents: ['motherboard', 'gpu'],
    safetyNote: _powerSafetyNote,
    steps: [
      'Disconnect the PCIe power cables from the top of the GPU.',
      'Remove the screws securing the GPU bracket to the case.',
      'Push the PCIe retention clip at the rear of the slot down — it locks the GPU in place.',
      'Pull the GPU straight out — do not rock or tilt, which can damage the slot.',
      'Inspect the gold contacts on the GPU edge for dust or oxidation. Wipe gently with a clean microfiber cloth.',
      'Inspect the PCIe slot. Blow out dust with compressed air if needed.',
      'Reinsert the GPU into the PCIe x16 slot and press firmly until the retention clip snaps up.',
      'Reattach the bracket screws and reconnect the PCIe power cables. Boot and check Device Manager.',
    ],
  ),
];

List<MaintenanceGuide> guidesForComponent(String component) {
  return motherboardGuides
      .where((g) => g.component.toLowerCase() == component.toLowerCase())
      .toList();
}
