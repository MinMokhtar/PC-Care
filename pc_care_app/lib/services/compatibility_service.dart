import '../data/pc_components.dart';
import '../models/pc_specs.dart';

class CompatibilityService {
  static const int _baseSystemPowerWatts = 150;

  List<CpuOption> compatibleCpus(PcSpecs specs) {
    final socket = specs.motherboardSocket;
    if (socket == null) return availableCpus;
    return availableCpus.where((c) => c.socket == socket).toList();
  }

  List<RamOption> compatibleRam(PcSpecs specs) {
    final ramType = specs.motherboardRamType;
    if (ramType == null) return availableRam;
    return availableRam.where((r) => r.type == ramType).toList();
  }

  List<GpuOption> compatibleGpus(PcSpecs specs) {
    return availableGpus;
  }

  List<StorageOption> compatibleStorage(PcSpecs specs) {
    return availableStorage;
  }

  String? warningForGpu(PcSpecs specs, GpuOption gpu) {
    final psuWatts = specs.psuWatts;
    if (psuWatts == null) return null;
    if (psuWatts < gpu.recommendedPsuWatts) {
      return 'Needs ${gpu.recommendedPsuWatts}W PSU (you have ${psuWatts}W). Upgrade PSU first.';
    }
    final headroom = psuWatts - gpu.powerWatts - _baseSystemPowerWatts;
    if (headroom < 50) {
      return 'Tight PSU headroom (${headroom}W spare). Consider a higher-wattage PSU for safety.';
    }
    return null;
  }
}
