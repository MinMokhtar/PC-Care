import 'package:flutter/material.dart';

import '../data/instructions.dart';
import 'instruction_detail_screen.dart';

class InstructionListScreen extends StatelessWidget {
  final String component;

  const InstructionListScreen({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final guides = guidesForComponent(component);

    final installation = guides
        .where((g) => g.category == GuideCategory.installation)
        .toList();
    final troubleshooting = guides
        .where((g) => g.category == GuideCategory.troubleshooting)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalize(component)} Guides'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (installation.isNotEmpty) ...[
            _SectionHeader(category: GuideCategory.installation),
            const SizedBox(height: 8),
            ...installation.map((g) => _GuideCard(guide: g)),
            const SizedBox(height: 24),
          ],
          if (troubleshooting.isNotEmpty) ...[
            _SectionHeader(category: GuideCategory.troubleshooting),
            const SizedBox(height: 8),
            ...troubleshooting.map((g) => _GuideCard(guide: g)),
          ],
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SectionHeader extends StatelessWidget {
  final GuideCategory category;

  const _SectionHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(category.icon,
            color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          category.label.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final MaintenanceGuide guide;

  const _GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InstructionDetailScreen(guide: guide),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(guide.icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.shortDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${guide.steps.length} steps',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
