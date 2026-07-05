import 'dart:io';
import 'dart:typed_data';

/// Sends a Wake-on-LAN "magic packet" to a target MAC address.
///
/// A magic packet is 102 bytes: 6 bytes of 0xFF followed by the target
/// 6-byte MAC repeated 16 times. We broadcast it on UDP port 9 — the
/// PC's network card listens for this even while powered off, as long
/// as WoL is enabled in BIOS and the network adapter driver.
class WolService {
  /// Sends a magic packet for [macAddress] in any common format:
  ///   AA:BB:CC:DD:EE:FF, AA-BB-CC-DD-EE-FF, AABBCCDDEEFF
  Future<void> wake(String macAddress) async {
    final mac = _parseMac(macAddress);
    if (mac == null) {
      throw WolException('Invalid MAC address: "$macAddress"');
    }

    final packet = Uint8List(6 + 16 * 6);
    for (int i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    for (int i = 0; i < 16; i++) {
      for (int j = 0; j < 6; j++) {
        packet[6 + i * 6 + j] = mac[j];
      }
    }

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      socket.broadcastEnabled = true;
      // Broadcast to the local subnet on UDP port 9 (and 7 for older NICs).
      socket.send(packet, InternetAddress('255.255.255.255'), 9);
      socket.send(packet, InternetAddress('255.255.255.255'), 7);
    } finally {
      socket.close();
    }
  }

  static List<int>? _parseMac(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[:\-\s]'), '').toUpperCase();
    if (cleaned.length != 12) return null;
    final bytes = <int>[];
    for (int i = 0; i < 12; i += 2) {
      final b = int.tryParse(cleaned.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      bytes.add(b);
    }
    return bytes;
  }
}

class WolException implements Exception {
  final String message;
  WolException(this.message);
  @override
  String toString() => message;
}
