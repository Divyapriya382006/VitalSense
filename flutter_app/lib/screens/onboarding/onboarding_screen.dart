import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  final _pages = [
    _OnboardPage(
      emoji: '🫀',
      title: 'Real-Time Vitals',
      desc: 'Monitor heart rate, SpO₂, ECG, and temperature live from sensors or your camera',
      color: VitalSenseTheme.alertRed,
    ),
    _OnboardPage(
      emoji: '🧠',
      title: 'AI Health Intelligence',
      desc: 'ML-powered PHI score, stress detection via HRV, and explainable AI alerts',
      color: VitalSenseTheme.primaryBlue,
    ),
    _OnboardPage(
      emoji: '👨‍⚕️',
      title: 'Doctor Connect',
      desc: 'Link with your doctor. They get live alerts when your vitals need attention',
      color: VitalSenseTheme.primaryGreen,
    ),
    _OnboardPage(
      emoji: '🆘',
      title: 'Emergency SOS',
      desc: 'Hold the SOS button to instantly alert nearby users via Bluetooth mesh — no internet needed',
      color: VitalSenseTheme.alertAmber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i].build(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? VitalSenseTheme.primaryBlue : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_page > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_page < _pages.length - 1) {
                              _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
                            } else {
                              context.go('/login');
                            }
                          },
                          child: Text(_page == _pages.length - 1 ? "Let's Go 🚀" : 'Next'),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String emoji, title, desc;
  final Color color;
  const _OnboardPage({required this.emoji, required this.title, required this.desc, required this.color});

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(title, style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(desc, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}
