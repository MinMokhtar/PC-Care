import 'package:flutter/material.dart';

import '../data/instructions.dart';

class InstructionDetailScreen extends StatefulWidget {
  final MaintenanceGuide guide;

  const InstructionDetailScreen({super.key, required this.guide});

  @override
  State<InstructionDetailScreen> createState() =>
      _InstructionDetailScreenState();
}

class _InstructionDetailScreenState extends State<InstructionDetailScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final totalSteps = guide.steps.length;
    final progress = (_currentStep + 1) / totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          if (guide.safetyNote != null) _SafetyBanner(note: guide.safetyNote!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(guide.icon, size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${_currentStep + 1} of $totalSteps',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      guide.steps[_currentStep],
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NavigationBar(
            currentStep: _currentStep,
            totalSteps: totalSteps,
            onPrevious: _currentStep > 0
                ? () => setState(() => _currentStep--)
                : null,
            onNext: _currentStep < totalSteps - 1
                ? () => setState(() => _currentStep++)
                : null,
            onFinish: _currentStep == totalSteps - 1
                ? () => Navigator.of(context).pop()
                : null,
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  final String note;

  const _SafetyBanner({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.amber.withValues(alpha: 0.15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  const _NavigationBar({
    required this.currentStep,
    required this.totalSteps,
    this.onPrevious,
    this.onNext,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: onFinish != null
                  ? FilledButton.icon(
                      onPressed: onFinish,
                      icon: const Icon(Icons.check),
                      label: const Text('Finish'),
                    )
                  : FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
