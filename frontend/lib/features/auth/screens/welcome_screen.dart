import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Find Your Soulmate',
      'subtitle':
          'Join thousands of verified brides & grooms on Dil Kaa Rista.',
      'icon': 'favorite',
    },
    {
      'title': '100% Verified Profiles',
      'subtitle':
          'Safe and authentic profiles verified with government ID & phone.',
      'icon': 'verified_user',
    },
    {
      'title': 'Smart Match Filters',
      'subtitle':
          'Filter by religion, caste, education, horoscope, and location with ease.',
      'icon': 'tune',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Slides Carousel
            SizedBox(
              height: 380,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  IconData iconData = Icons.favorite_rounded;
                  if (slide['icon'] == 'verified_user') {
                    iconData = Icons.verified_user_rounded;
                  } else if (slide['icon'] == 'tune') {
                    iconData = Icons.tune_rounded;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 70,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide['title']!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text('Register Free'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
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
