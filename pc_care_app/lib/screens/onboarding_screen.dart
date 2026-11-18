import 'package:flutter/material.dart';

import '../services/onboarding_prefs_service.dart';
import 'terms_screen.dart';

/// First-launch onboarding — a 4-page carousel introducing PC Care.
/// On the last page's "Get Started", marks onboarding done and pushes
/// the Terms screen (user must still agree before entering the app).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color accent = Color(0xFF29ABE2);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = [
    _Slide(
      image: 'carousel/App_logo.png',
      title: 'Welcome to PICARE',
      body: 'Your all-in-one PC maintenance companion. Everything you need '
          'to keep your PC healthy, from your phone.',
      fit: BoxFit.contain, // logo stays centered/small on a dark bg
    ),
    _Slide(
      image: 'carousel/AR_Guide.png',
      title: 'Augmented Reality Guide',
      body: 'Point your camera at your PC internals. Get real-time component '
          'detection with step-by-step guides.',
    ),
    _Slide(
      image: 'carousel/Live_Temp.png',
      title: 'Live Temperature Monitoring',
      body: 'See your CPU, GPU, motherboard, and Storage temperatures live '
          'from your phone. Know before things overheat.',
    ),
    _Slide(
      image: 'carousel/Upgrade_Planning.png',
      title: 'Upgrade Planning',
      body: 'Plan upgrades component by component with real-time compatibility '
          'warnings — never buy the wrong part again.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await OnboardingPrefsService().setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingScreen.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background — the darker galaxy image behind every slide
          Image.asset(
            'carousel/Background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: OnboardingScreen.bg),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top logo + name
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Image.asset(
                    'carousel/Logo_Top.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
                // Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),
                // Dots indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DotsIndicator(count: _slides.length, index: _index),
                ),
                // Title + body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        _slides[_index].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _slides[_index].body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom action row: Back + Next / Get Started
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Row(
                    children: [
                      _BackPill(
                        enabled: _index > 0,
                        onTap: _back,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _NextButton(
                          label: _index == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                          onTap: _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Slide model + view ----------

class _Slide {
  final String image;
  final String title;
  final String body;
  /// How the image scales inside the carousel viewport. Full-bleed frames
  /// use `cover`; the small centered welcome logo uses `contain`.
  final BoxFit fit;
  const _Slide({
    required this.image,
    required this.title,
    required this.body,
    this.fit = BoxFit.cover,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        slide.image,
        fit: slide.fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          color: Colors.white24,
          size: 96,
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? OnboardingScreen.accent
                  : Colors.white30,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _BackPill extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _BackPill({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: const Color(0xFF1E2742),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OnboardingScreen.accent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
