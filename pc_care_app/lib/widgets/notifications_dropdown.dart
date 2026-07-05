import 'package:flutter/material.dart';

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String time;
  final String body;

  const NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.time,
    required this.body,
  });
}

const List<NotificationItem> mockNotifications = [
  NotificationItem(
    icon: Icons.warning_amber_rounded,
    iconColor: Color(0xFFFFA726),
    iconBg: Color(0xFF3F2E16),
    title: 'Storage Warning',
    time: '2 mins ago',
    body: 'Your C: drive is 85% full. Cleaning up might improve performance.',
  ),
  NotificationItem(
    icon: Icons.info_outline,
    iconColor: Color(0xFF60A5FA),
    iconBg: Color(0xFF1E2E4F),
    title: 'System Update',
    time: '1 hour ago',
    body: 'A new security update is available for your system.',
  ),
];

/// Opens the notifications dropdown anchored below [bellKey]. Calls
/// [onMarkAllRead] after the user taps "Mark all as read".
void showNotificationsDropdown({
  required BuildContext context,
  required GlobalKey bellKey,
  required VoidCallback onMarkAllRead,
}) {
  final overlay = Overlay.of(context);
  final bellCtx = bellKey.currentContext;
  if (bellCtx == null) return;
  final box = bellCtx.findRenderObject() as RenderBox;
  final bellTopLeft = box.localToGlobal(Offset.zero);
  final bellSize = box.size;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => entry.remove(),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: bellTopLeft.dy + bellSize.height + 8,
          left: 16,
          right: 16,
          child: NotificationsPanel(
            items: mockNotifications,
            onMarkAllRead: () {
              entry.remove();
              onMarkAllRead();
            },
          ),
        ),
      ],
    ),
  );
  overlay.insert(entry);
}

class NotificationsPanel extends StatefulWidget {
  final List<NotificationItem> items;
  final VoidCallback onMarkAllRead;

  const NotificationsPanel({
    super.key,
    required this.items,
    required this.onMarkAllRead,
  });

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sizeAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _sizeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnim,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1932),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < widget.items.length; i++) ...[
                  _NotificationRow(item: widget.items[i]),
                  if (i != widget.items.length - 1)
                    const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: widget.onMarkAllRead,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;

  const _NotificationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    item.time,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
