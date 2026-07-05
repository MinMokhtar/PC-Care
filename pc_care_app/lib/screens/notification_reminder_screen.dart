import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../services/notifications_service.dart';
import '../services/reminders_service.dart';
import '../services/settings_prefs_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

class NotificationReminderScreen extends StatefulWidget {
  const NotificationReminderScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color divider = Color(0xFF1E2742);

  @override
  State<NotificationReminderScreen> createState() =>
      _NotificationReminderScreenState();
}

class _NotificationReminderScreenState
    extends State<NotificationReminderScreen> {
  final _service = RemindersService();
  final _notifications = NotificationsService.instance;
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.load();
    if (!mounted) return;
    setState(() {
      _reminders = list;
      _loading = false;
    });
  }

  Future<void> _persistAndReschedule() async {
    await _service.saveAll(_reminders);
    final globalOn = await SettingsPrefsService().loadNotifications();
    if (globalOn) {
      await _notifications.rescheduleAll(_reminders);
    } else {
      await _notifications.cancelAll();
    }
  }

  Future<void> _toggleEnabled(Reminder r, bool value) async {
    // If turning on a reminder, ensure permission has been granted AND
    // auto-enable the global Notifications switch so the reminder actually
    // fires. Otherwise users have to discover and flip the Settings toggle.
    if (value) {
      final granted = await _notifications.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied — reminder won\'t fire until allowed.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await SettingsPrefsService().saveNotifications(true);
    }
    setState(() {
      final i = _reminders.indexWhere((x) => x.id == r.id);
      if (i >= 0) {
        _reminders[i] = _reminders[i].copyWith(enabled: value);
      }
    });
    await _persistAndReschedule();
  }

  Future<void> _editReminder(Reminder r) async {
    final updated = await showDialog<Reminder>(
      context: context,
      builder: (_) => _ReminderEditDialog(initial: r),
    );
    if (updated == null) return;
    setState(() {
      final i = _reminders.indexWhere((x) => x.id == r.id);
      if (i >= 0) _reminders[i] = updated;
    });
    await _persistAndReschedule();
  }

  Future<void> _deleteReminder(Reminder r) async {
    if (r.isPreset) return; // presets just toggle off
    setState(() => _reminders.removeWhere((x) => x.id == r.id));
    await _persistAndReschedule();
  }

  Future<void> _addCustom() async {
    final created = await showDialog<Reminder>(
      context: context,
      builder: (_) => _ReminderEditDialog(
        initial: Reminder(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          frequency: ReminderFrequency.weekly,
          timeOfDay: const TimeOfDay(hour: 9, minute: 0),
          enabled: true,
        ),
        isNew: true,
      ),
    );
    if (created == null) return;
    setState(() => _reminders.add(created));
    await _persistAndReschedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder added'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _reminders.where((r) => r.isPreset).toList();
    final custom = _reminders.where((r) => !r.isPreset).toList();

    return Scaffold(
      backgroundColor: NotificationReminderScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Header(),
                    const SizedBox(height: 12),
                    _BackPill(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: 18),
                    const _SectionHeader(label: 'SUGGESTED PRESETS'),
                    const SizedBox(height: 10),
                    _RemindersCard(
                      reminders: presets,
                      onToggle: _toggleEnabled,
                      onEdit: _editReminder,
                      onDelete: null,
                    ),
                    const SizedBox(height: 18),
                    const _SectionHeader(label: 'CUSTOM'),
                    const SizedBox(height: 10),
                    if (custom.isEmpty)
                      const _EmptyCustomState()
                    else
                      _RemindersCard(
                        reminders: custom,
                        onToggle: _toggleEnabled,
                        onEdit: _editReminder,
                        onDelete: _deleteReminder,
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addCustom,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add custom reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NotificationReminderScreen.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: null,
        onHome: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.home);
        },
        onGuides: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.guides);
        },
        onUpgrades: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.upgrades);
        },
      ),
    );
  }
}

// ---------- Header + Back ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Schedule maintenance reminders that fire on your phone',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: NotificationReminderScreen.iconBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: NotificationReminderScreen.accentBlue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ---------- Reminders card ----------

class _RemindersCard extends StatelessWidget {
  final List<Reminder> reminders;
  final Future<void> Function(Reminder, bool) onToggle;
  final Future<void> Function(Reminder) onEdit;
  final Future<void> Function(Reminder)? onDelete;

  const _RemindersCard({
    required this.reminders,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NotificationReminderScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < reminders.length; i++) ...[
            _ReminderRow(
              reminder: reminders[i],
              onToggle: (v) => onToggle(reminders[i], v),
              onEdit: () => onEdit(reminders[i]),
              onDelete:
                  onDelete == null ? null : () => onDelete!(reminders[i]),
            ),
            if (i != reminders.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: NotificationReminderScreen.divider,
                  height: 1,
                  thickness: 1,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Reminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ReminderRow({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatTime(BuildContext context) {
    final t = reminder.timeOfDay;
    final mat = MaterialLocalizations.of(context);
    return mat.formatTimeOfDay(t, alwaysUse24HourFormat: false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NotificationReminderScreen.iconBgInner,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.alarm,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title.isEmpty
                                ? '(Untitled)'
                                : reminder.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${reminder.frequency.label} • ${_formatTime(context)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white54,
                size: 18,
              ),
              tooltip: 'Delete reminder',
              visualDensity: VisualDensity.compact,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Switch(
              value: reminder.enabled,
              onChanged: onToggle,
              activeColor: Colors.white,
              activeTrackColor: NotificationReminderScreen.accentBlue,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: const Color(0xFF2E3650),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomState extends StatelessWidget {
  const _EmptyCustomState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NotificationReminderScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: const Text(
        'No custom reminders yet. Tap "Add custom reminder" to create one.',
        style: TextStyle(color: Colors.white60, fontSize: 13),
      ),
    );
  }
}

// ---------- Edit dialog ----------

class _ReminderEditDialog extends StatefulWidget {
  final Reminder initial;
  final bool isNew;

  const _ReminderEditDialog({required this.initial, this.isNew = false});

  @override
  State<_ReminderEditDialog> createState() => _ReminderEditDialogState();
}

class _ReminderEditDialogState extends State<_ReminderEditDialog> {
  late TextEditingController _titleCtrl;
  late ReminderFrequency _frequency;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial.title);
    _frequency = widget.initial.frequency;
    _time = widget.initial.timeOfDay;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isPreset = widget.initial.isPreset;
    return AlertDialog(
      backgroundColor: NotificationReminderScreen.cardBg,
      title: Text(
        widget.isNew ? 'New reminder' : 'Edit reminder',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            enabled: !isPreset,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.white60),
              hintText: 'e.g., Clean fans',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Frequency',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          DropdownButton<ReminderFrequency>(
            value: _frequency,
            isExpanded: true,
            dropdownColor: NotificationReminderScreen.cardBg,
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white70,
            items: ReminderFrequency.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(
                        f.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _frequency = v);
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${MaterialLocalizations.of(context).formatTimeOfDay(_time)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap to change',
                    style: TextStyle(
                      color: NotificationReminderScreen.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            final updated = widget.initial.copyWith(
              title: _titleCtrl.text.trim(),
              frequency: _frequency,
              timeOfDay: _time,
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text(
            'Save',
            style: TextStyle(
              color: NotificationReminderScreen.accentBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
