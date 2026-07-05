import 'package:flutter/material.dart';

import '../widgets/placeholder_screen.dart';

class YoutubeTutorialScreen extends StatelessWidget {
  const YoutubeTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'YouTube Tutorial',
      icon: Icons.play_circle_outline,
      description:
          'Pick what you want to do, get a curated YouTube video walkthrough. Coming alongside the AR mode.',
    );
  }
}
