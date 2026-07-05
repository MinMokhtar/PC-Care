import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/companion_config.dart';
import 'device_info_service.dart';

/// Component temperatures returned by `/api/temps`.
/// Any field may be null if the sensor isn't available on this system.
class CompanionTemps {
  final int? cpu;
  final int? gpu;
  final int? motherboard;
  final int? storage;

  const CompanionTemps({this.cpu, this.gpu, this.motherboard, this.storage});

  factory CompanionTemps.fromJson(Map<String, dynamic> json) {
    int? readInt(String key) => (json[key] as num?)?.toInt();
    return CompanionTemps(
      cpu: readInt('cpu'),
      gpu: readInt('gpu'),
      motherboard: readInt('motherboard'),
      storage: readInt('storage'),
    );
  }
}

/// A drive returned by the companion's `/api/storage` endpoint.
class CompanionDrive {
  final String letter;       // "C:"
  final String name;         // "Acer", "nugget", "Local Disk"
  final double totalGB;
  final double freeGB;

  const CompanionDrive({
    required this.letter,
    required this.name,
    required this.totalGB,
    required this.freeGB,
  });

  double get usedGB => totalGB - freeGB;
  double get usedPercent => totalGB > 0 ? usedGB / totalGB : 0;

  factory CompanionDrive.fromJson(Map<String, dynamic> json) {
    return CompanionDrive(
      letter: json['letter'] as String? ?? '',
      name: json['name'] as String? ?? 'Drive',
      totalGB: (json['totalGB'] as num?)?.toDouble() ?? 0,
      freeGB: (json['freeGB'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Result of the Connect-screen pair flow's PIN check.
enum VerifyResult { ok, wrongPin, revoked }

/// Identity info returned by the companion's `/` endpoint.
class CompanionIdentity {
  final String hostname;
  final String app;
  final String mac;
  const CompanionIdentity({
    required this.hostname,
    required this.app,
    required this.mac,
  });

  factory CompanionIdentity.fromJson(Map<String, dynamic> json) =>
      CompanionIdentity(
        hostname: json['hostname'] as String? ?? 'Unknown',
        app: json['app'] as String? ?? 'PC Care Companion',
        mac: json['mac'] as String? ?? '',
      );
}

/// Talks to the PC Care Windows companion app over local HTTP.
///
/// Singleton — all screens share the same instance so transient state
/// (like "user just hit Sleep on the power screen") is visible everywhere.
class CompanionService {
  static final CompanionService _instance = CompanionService._internal();
  factory CompanionService() => _instance;
  CompanionService._internal();

  static const Duration _timeout = Duration(seconds: 4);
  static const Duration _pingTimeout = Duration(seconds: 2);

  final DeviceInfoService _deviceInfo = DeviceInfoService();

  /// Set when the user sends a Sleep command, so the Home indicator can
  /// distinguish "PC is sleeping" from "PC is just offline" for a while.
  DateTime? _sleepRequestedAt;
  bool get isSleepRecentlyRequested {
    final t = _sleepRequestedAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(minutes: 5);
  }

  /// Builds the authentication + identity headers sent on every API call.
  /// X-Pin authenticates the request; X-Device-Id + X-Device-Name let the
  /// PC track which phone(s) are connected (used by the Connected Devices
  /// panel + revoke flow).
  Future<Map<String, String>> _buildAuthHeaders() async {
    final id = await _deviceInfo.getId();
    final name = await _deviceInfo.getName();
    return {
      'X-Pin': CompanionConfig.pin,
      'X-Device-Id': id,
      'X-Device-Name': name,
    };
  }

  /// Quick health check — true if companion responds at `/` within 2 sec.
  /// (No PIN required for this endpoint.)
  Future<bool> ping({String? host}) async {
    final base = host == null
        ? CompanionConfig.baseUrl
        : 'http://$host:${CompanionConfig.port}';
    try {
      final res = await http.get(Uri.parse('$base/')).timeout(_pingTimeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Hits `/` on the given host and parses the identity JSON.
  /// Used by subnet scanning to know which PC is which.
  Future<CompanionIdentity?> identify(String host) async {
    try {
      final res = await http
          .get(Uri.parse('http://$host:${CompanionConfig.port}/'))
          .timeout(_pingTimeout);
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      return CompanionIdentity.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  /// Verifies that [pin] works against [host].
  /// Returns:
  ///   - `VerifyResult.ok` on 200
  ///   - `VerifyResult.revoked` if the PC has revoked this device id
  ///   - `VerifyResult.wrongPin` otherwise (401 without revoke header, or any other failure)
  Future<VerifyResult> verifyCredentials(String host, String pin) async {
    try {
      final id = await _deviceInfo.getId();
      final name = await _deviceInfo.getName();
      final res = await http
          .get(
            Uri.parse('http://$host:${CompanionConfig.port}/api/storage'),
            headers: {
              'X-Pin': pin,
              'X-Device-Id': id,
              'X-Device-Name': name,
            },
          )
          .timeout(_pingTimeout);
      if (res.statusCode == 200) return VerifyResult.ok;
      if (res.statusCode == 401 && res.headers['x-revoked'] == '1') {
        return VerifyResult.revoked;
      }
      return VerifyResult.wrongPin;
    } catch (_) {
      return VerifyResult.wrongPin;
    }
  }

  /// Fetches the drive list from the companion.
  Future<List<CompanionDrive>> fetchStorage() async {
    final uri = Uri.parse('${CompanionConfig.baseUrl}/api/storage');
    final res = await http.get(uri, headers: await _buildAuthHeaders()).timeout(_timeout);
    _checkRevoked(res);
    if (res.statusCode != 200) {
      throw CompanionException(
        'Storage request failed (${res.statusCode})',
      );
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = (body['drives'] as List?) ?? const [];
    return list
        .map((e) => CompanionDrive.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches component temperatures from the companion.
  Future<CompanionTemps> fetchTemps() async {
    final uri = Uri.parse('${CompanionConfig.baseUrl}/api/temps');
    final res = await http.get(uri, headers: await _buildAuthHeaders()).timeout(_timeout);
    _checkRevoked(res);
    if (res.statusCode != 200) {
      throw CompanionException(
        'Temps request failed (${res.statusCode})',
      );
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return CompanionTemps.fromJson(body);
  }

  // ----- Power control -----

  Future<void> shutdown() => _power('shutdown');
  Future<void> restart() => _power('restart');
  Future<void> sleep() {
    _sleepRequestedAt = DateTime.now();
    return _power('sleep');
  }
  Future<void> cancelShutdown() => _power('cancel');

  Future<void> _power(String action) async {
    final uri = Uri.parse('${CompanionConfig.baseUrl}/api/power/$action');
    final res = await http.post(uri, headers: await _buildAuthHeaders()).timeout(_timeout);
    _checkRevoked(res);
    if (res.statusCode != 200) {
      throw CompanionException('$action failed (${res.statusCode})');
    }
  }

  // ----- Quick actions -----

  /// Clears `%TEMP%` on the PC. Returns the reported message
  /// (e.g. "Deleted 23 files (412.5 MB)").
  Future<String> clearCache() async {
    final uri =
        Uri.parse('${CompanionConfig.baseUrl}/api/actions/clear-cache');
    final res = await http
        .post(uri, headers: await _buildAuthHeaders())
        .timeout(const Duration(seconds: 30));
    _checkRevoked(res);
    if (res.statusCode != 200) {
      throw CompanionException('Clear cache failed (${res.statusCode})');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return (body['message'] as String?) ?? 'Cache cleared';
  }

  /// Best-effort notify the PC that this device is disconnecting voluntarily,
  /// so the PC GUI removes this entry from its Connected Devices list.
  /// Doesn't throw — disconnect should succeed even if PC is offline.
  Future<void> forgetMe() async {
    try {
      final uri =
          Uri.parse('${CompanionConfig.baseUrl}/api/devices/me/forget');
      await http
          .post(uri, headers: await _buildAuthHeaders())
          .timeout(_pingTimeout);
    } catch (_) {/* offline / network — best effort only */}
  }

  /// Kicks off Defrag/Optimize on C: in the background.
  Future<String> defrag() async {
    final uri = Uri.parse('${CompanionConfig.baseUrl}/api/actions/defrag');
    final res = await http.post(uri, headers: await _buildAuthHeaders()).timeout(_timeout);
    _checkRevoked(res);
    if (res.statusCode != 200) {
      throw CompanionException('Defrag failed (${res.statusCode})');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return (body['message'] as String?) ?? 'Defrag started';
  }

  /// Throws [CompanionRevokedException] on any 401 from an authenticated
  /// endpoint — covers BOTH cases:
  ///   - Explicit revoke (PC tapped Disconnect; sends `X-Revoked: 1`)
  ///   - PIN changed underneath us (PC tapped Regenerate; just sends 401)
  /// Either way, our stored credentials are dead. The UI catches this,
  /// wipes credentials, and bounces to Connect.
  void _checkRevoked(http.Response res) {
    if (res.statusCode == 401) {
      throw CompanionRevokedException();
    }
  }
}

class CompanionException implements Exception {
  final String message;
  CompanionException(this.message);
  @override
  String toString() => message;
}

/// Thrown when the PC owner has revoked this device. Listeners should wipe
/// credentials and send the user back to the Connect screen.
class CompanionRevokedException implements Exception {
  @override
  String toString() => 'Device revoked by PC owner';
}
