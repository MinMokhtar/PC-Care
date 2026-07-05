import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/instructions.dart';
import '../services/youtube_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/notifications_dropdown.dart';
import 'main_shell.dart';
import 'settings_screen.dart';

class YoutubeVideoListScreen extends StatefulWidget {
  final MaintenanceGuide guide;

  const YoutubeVideoListScreen({super.key, required this.guide});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color thumbnailBg = Color(0xFF3F2E2A);
  static const Color titleBlue = Color(0xFF29ABE2);

  @override
  State<YoutubeVideoListScreen> createState() => _YoutubeVideoListScreenState();
}

class _YoutubeVideoListScreenState extends State<YoutubeVideoListScreen> {
  final GlobalKey _bellKey = GlobalKey();
  final TextEditingController _searchCtrl = TextEditingController();
  final YoutubeService _youtube = YoutubeService();
  bool _hasUnread = true;

  late String _query;
  YoutubeSortOrder _sort = YoutubeSortOrder.relevance;
  YoutubeDuration _duration = YoutubeDuration.any;

  late Future<List<YoutubeVideo>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _query = '${widget.guide.title} tutorial';
    _videosFuture = _runSearch();
  }

  Future<List<YoutubeVideo>> _runSearch() {
    return _youtube.search(_query, order: _sort, duration: _duration);
  }

  void _refetch() {
    setState(() {
      _videosFuture = _runSearch();
    });
  }

  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _query = trimmed;
    _refetch();
  }

  Future<void> _pickSort() async {
    final picked = await _showOptionsSheet<YoutubeSortOrder>(
      title: 'Sort by',
      options: YoutubeSortOrder.values,
      current: _sort,
      labelOf: (o) => o.label,
    );
    if (picked != null && picked != _sort) {
      _sort = picked;
      _refetch();
    }
  }

  Future<void> _pickFilter() async {
    final picked = await _showOptionsSheet<YoutubeDuration>(
      title: 'Filter by duration',
      options: YoutubeDuration.values,
      current: _duration,
      labelOf: (o) => o.label,
    );
    if (picked != null && picked != _duration) {
      _duration = picked;
      _refetch();
    }
  }

  Future<T?> _showOptionsSheet<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: YoutubeVideoListScreen.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final o in options)
                ListTile(
                  onTap: () => Navigator.of(ctx).pop(o),
                  title: Text(
                    labelOf(o),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  trailing: o == current
                      ? const Icon(Icons.check,
                          color: YoutubeVideoListScreen.titleBlue)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showNotifications() {
    showNotificationsDropdown(
      context: context,
      bellKey: _bellKey,
      onMarkAllRead: () => setState(() => _hasUnread = false),
    );
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openVideo(YoutubeVideo video) async {
    final uri = Uri.parse(video.watchUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open YouTube'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YoutubeVideoListScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                bellKey: _bellKey,
                hasUnread: _hasUnread,
                onBell: _showNotifications,
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _BackPill(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),
              _SearchBar(
                controller: _searchCtrl,
                onSubmitted: _onSearchSubmitted,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tutorials',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _Pill(
                    icon: Icons.filter_list,
                    label: _duration == YoutubeDuration.any
                        ? 'Filter'
                        : _duration.label,
                    onTap: _pickFilter,
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icons.swap_vert,
                    label: 'Sort: ${_sort.label}',
                    onTap: _pickSort,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<YoutubeVideo>>(
                future: _videosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: YoutubeVideoListScreen.titleBlue,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: 'Couldn\'t load videos.\n${snapshot.error}',
                      onRetry: _refetch,
                    );
                  }
                  final videos = snapshot.data ?? const [];
                  if (videos.isEmpty) {
                    return const _EmptyState();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final video in videos) ...[
                        _VideoCard(
                          video: video,
                          onTap: () => _openVideo(video),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppTab.guides,
        onHome: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.home);
        },
        onGuides: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onUpgrades: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.upgrades);
        },
      ),
    );
  }
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  final GlobalKey bellKey;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onSettings;

  const _Header({
    required this.bellKey,
    required this.hasUnread,
    required this.onBell,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guides',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Smart guides that'll help you",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _CircleIconButton(
                key: bellKey,
                icon: Icons.notifications_outlined,
                onTap: onBell,
                showBadge: hasUnread,
              ),
              const SizedBox(width: 10),
              _CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ],
          ),
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
        color: YoutubeVideoListScreen.iconBg,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: YoutubeVideoListScreen.iconBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(
                  color: YoutubeVideoListScreen.iconBg,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- Search bar ----------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _SearchBar({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YoutubeVideoListScreen.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search YouTube',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Filter / Sort pill ----------

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _Pill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YoutubeVideoListScreen.iconBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Video card ----------

class _VideoCard extends StatelessWidget {
  final YoutubeVideo video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YoutubeVideoListScreen.cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url: video.thumbnailUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YoutubeVideoListScreen.titleBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${video.channelTitle}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _Tag(label: 'Youtube'),
                        const SizedBox(width: 6),
                        if (video.duration.isNotEmpty)
                          _Tag(label: video.duration),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        height: 80,
        child: url.isEmpty
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _placeholder();
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A3A33), Color(0xFF6B4838)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_arrow, color: Colors.white70, size: 32),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: YoutubeVideoListScreen.titleBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text(
            'No videos found for this guide.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YoutubeVideoListScreen.iconBgInner,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
