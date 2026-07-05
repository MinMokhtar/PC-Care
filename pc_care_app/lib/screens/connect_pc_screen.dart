import 'package:flutter/material.dart';

import '../config/companion_config.dart';
import '../services/app_mode_service.dart';
import '../services/companion_service.dart';
import '../services/network_scan_service.dart';
import 'main_shell.dart';

class ConnectPcScreen extends StatefulWidget {
  const ConnectPcScreen({super.key});

  @override
  State<ConnectPcScreen> createState() => _ConnectPcScreenState();
}

class _ConnectPcScreenState extends State<ConnectPcScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF06112E);
  static const Color _accent = Color(0xFF29ABE2);
  static const Color _demoBlue = Color(0xFF1E3A8A);
  static const double _circleSize = 260;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickMode(AppMode mode) async {
    await AppModeService().save(mode);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _onConnectTap() async {
    // Step 1: Scan
    final found = await showDialog<List<DiscoveredPc>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ScanDialog(),
    );
    if (!mounted || found == null || found.isEmpty) return;

    // Step 2: User picks a PC (or skips into manual entry)
    final picked = await showDialog<DiscoveredPc>(
      context: context,
      builder: (_) => _PickPcDialog(found: found),
    );
    if (!mounted || picked == null) return;

    // Step 3: PIN entry + verify
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinDialog(host: picked.ip, hostname: picked.hostname),
    );
    if (!mounted || pin == null || pin.isEmpty) return;

    // Step 4: Save + go to MainShell
    await CompanionConfig.setConnection(picked.ip, pin, picked.mac);
    await _pickMode(AppMode.real);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'assets/icon/pc_care_masthead.png',
                height: 110,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: _circleSize,
                height: _circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _PulseRing(
                      controller: _pulseController,
                      baseSize: _circleSize,
                      color: _accent,
                    ),
                    _ConnectCircle(
                      size: _circleSize,
                      color: _accent,
                      onTap: _onConnectTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'SEARCH FOR A NEARBY PC',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(flex: 4),
              _DemoTestButton(
                color: _demoBlue,
                onTap: () => _pickMode(AppMode.demo),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectCircle extends StatelessWidget {
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _ConnectCircle({
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final double baseSize;
  final Color color;

  const _PulseRing({
    required this.controller,
    required this.baseSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final scale = 1.0 + (t * 0.55);
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;
        return IgnorePointer(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: baseSize,
                height: baseSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DemoTestButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _DemoTestButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          child: Text(
            'Demo Test',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Scan dialog ----------

class _ScanDialog extends StatefulWidget {
  const _ScanDialog();

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog> {
  static const Color _bg = Color(0xFF11182C);
  static const Color _accent = Color(0xFF29ABE2);

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  Future<void> _kickoff() async {
    final found = await NetworkScanService().scan();
    if (!mounted) return;
    Navigator.of(context).pop(found);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _bg,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: _accent, strokeWidth: 3),
          ),
          SizedBox(height: 18),
          Text(
            'Searching for a nearby PC…',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Scanning local network',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------- Pick PC dialog ----------

class _PickPcDialog extends StatelessWidget {
  static const Color _bg = Color(0xFF11182C);
  static const Color _accent = Color(0xFF29ABE2);

  final List<DiscoveredPc> found;
  const _PickPcDialog({required this.found});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _bg,
      title: Text(
        found.length == 1
            ? 'Found nearby PC'
            : 'Found ${found.length} nearby PCs',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final pc in found)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.desktop_windows_outlined,
                  color: _accent, size: 28),
              title: Text(
                pc.hostname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                pc.ip,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () => Navigator.of(context).pop(pc),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

// ---------- PIN entry dialog ----------

class _PinDialog extends StatefulWidget {
  final String host;
  final String hostname;
  const _PinDialog({required this.host, required this.hostname});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  static const Color _bg = Color(0xFF11182C);
  static const Color _accent = Color(0xFF29ABE2);

  final TextEditingController _ctrl = TextEditingController();
  final CompanionService _companion = CompanionService();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _ctrl.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'PIN must be 6 digits');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final result = await _companion.verifyCredentials(widget.host, pin);
    if (!mounted) return;
    switch (result) {
      case VerifyResult.ok:
        Navigator.of(context).pop(pin);
        break;
      case VerifyResult.revoked:
        setState(() {
          _verifying = false;
          _error =
              "This phone was disconnected by the PC owner.\nAsk them to regenerate the PIN to allow it again.";
        });
        break;
      case VerifyResult.wrongPin:
        setState(() {
          _verifying = false;
          _error = 'Wrong PIN. Check the code shown on your PC.';
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _bg,
      title: Text(
        'Pair with ${widget.hostname}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the 6-digit PIN shown in the companion app window on your PC.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            enabled: !_verifying,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 6,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(color: Colors.white24, letterSpacing: 6),
              counterText: '',
              filled: true,
              fillColor: Color(0xFF1E2742),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            autofocus: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifying ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _verifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
          ),
          child: _verifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Verify & Connect'),
        ),
      ],
    );
  }
}
