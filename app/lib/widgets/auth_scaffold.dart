import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return Row(
          children: [
            if (wide) const Expanded(child: _FashionPanel()),
            Expanded(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 480 ? 22 : 48,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton.outlined(
                                tooltip: 'Back',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const Spacer(),
                              if (!wide)
                                Row(
                                  children: [
                                    const Text(
                                      'DressMate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Hero(
                                      tag: 'brand-logo',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          'assets/logo.png',
                                          width: 42,
                                          height: 42,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          SizedBox(height: wide ? 70 : 48),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 36),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _FashionPanel extends StatelessWidget {
  const _FashionPanel();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/onboarding_2.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9111217)],
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 32,
            child: Row(
              children: [
                Hero(
                  tag: 'brand-logo',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 46,
                      height: 46,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'DressMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 42,
            right: 42,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'YOUR CLOSET, REIMAGINED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Less deciding.\nMore wearing.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
