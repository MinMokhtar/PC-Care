import 'dart:io';

import '../config/companion_config.dart';
import 'companion_service.dart';

/// A PC found on the local subnet running the PC Care companion app.
class DiscoveredPc {
  final String ip;
  final String hostname;
  final String mac;
  const DiscoveredPc({
    required this.ip,
    required this.hostname,
    required this.mac,
  });
}

/// Sweeps the phone's local /24 subnet for PCs running the companion.
/// On a typical home/hotspot network this completes in ~3-5 seconds.
class NetworkScanService {
  final CompanionService _companion;

  NetworkScanService({CompanionService? companion})
      : _companion = companion ?? CompanionService();

  /// Returns the phone's first non-loopback IPv4 address, or null.
  static Future<String?> _localIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return null;
  }

  /// Returns "192.168.0" given "192.168.0.42". Null if [ip] is malformed.
  static String? _subnetPrefix(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  /// Scans the subnet the phone is currently on for PCs running the
  /// companion app. Returns whatever it finds — usually 0 or 1 entries.
  Future<List<DiscoveredPc>> scan() async {
    final me = await _localIp();
    if (me == null) return const [];
    final prefix = _subnetPrefix(me);
    if (prefix == null) return const [];

    // Skip my own IP and the broadcast address (255).
    final myLast = int.tryParse(me.split('.').last);
    final candidates = <String>[
      for (int i = 1; i <= 254; i++)
        if (i != myLast) '$prefix.$i',
    ];

    // Probe all candidates in parallel via /identify. Most return null
    // (connection refused / timeout). The few that succeed are our PCs.
    final futures = candidates.map((ip) async {
      final identity = await _companion.identify(ip);
      if (identity == null) return null;
      return DiscoveredPc(
        ip: ip,
        hostname: identity.hostname,
        mac: identity.mac,
      );
    });

    final results = await Future.wait(futures);
    return results.whereType<DiscoveredPc>().toList();
  }

  /// Convenience: returns the configured port the companion listens on.
  static int get port => CompanionConfig.port;
}
