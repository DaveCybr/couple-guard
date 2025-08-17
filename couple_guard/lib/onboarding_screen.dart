// lib/core/screens/onboarding_screen.dart
import 'package:couple_guard/core/routes/app_navigator.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<OnboardingData> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      OnboardingData(
        title: 'Stay Connected',
        subtitle:
            'Keep track of your partner\'s location and ensure their safety wherever they go.',
        icon: Icons.location_on,
        color: AppColors.primary,
        backgroundPattern: const _LocationPattern(),
      ),
      OnboardingData(
        title: 'Smart Monitoring',
        subtitle:
            'Monitor device activity, app usage, and receive instant notifications when needed.',
        icon: Icons.visibility,
        color: AppColors.secondary,
        backgroundPattern: const _MonitoringPattern(),
      ),
      OnboardingData(
        title: 'Secure & Private',
        subtitle:
            'Your data is encrypted and secure. Only you and your partner have access to shared information.',
        icon: Icons.shield,
        color: AppColors.success,
        backgroundPattern: const _SecurityPattern(),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.mediumDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    // FIXED: Gunakan Navigator.of(context) dengan route yang benar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppNavigator.push(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            _buildHeader(),

            // Page indicator
            _buildPageIndicator(),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Skip button
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.defaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pages.length,
          (index) => AnimatedContainer(
            duration: AppConstants.shortDuration,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  _currentPage == index
                      ? _pages[_currentPage].color
                      : AppColors.grey300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Illustration area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background pattern
                  Positioned.fill(child: data.backgroundPattern),
                  // Main icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, size: 60, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Content area
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Flexible(
                  child: Text(
                    data.subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius,
                    ),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
          ],

          // Next/Get Started button
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_currentPage].color,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget backgroundPattern;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundPattern,
  });
}

// Background patterns for each page
class _LocationPattern extends StatelessWidget {
  const _LocationPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 30,
          child: Icon(
            Icons.place,
            color: AppColors.primary.withOpacity(0.2),
            size: 24,
          ),
        ),
        Positioned(
          top: 80,
          right: 40,
          child: Icon(
            Icons.my_location,
            color: AppColors.primary.withOpacity(0.15),
            size: 20,
          ),
        ),
        Positioned(
          bottom: 60,
          left: 50,
          child: Icon(
            Icons.location_searching,
            color: AppColors.primary.withOpacity(0.1),
            size: 28,
          ),
        ),
        Positioned(
          bottom: 30,
          right: 30,
          child: Icon(
            Icons.gps_fixed,
            color: AppColors.primary.withOpacity(0.2),
            size: 16,
          ),
        ),
      ],
    );
  }
}

class _MonitoringPattern extends StatelessWidget {
  const _MonitoringPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 30,
          right: 20,
          child: Icon(
            Icons.phone_android,
            color: AppColors.secondary.withOpacity(0.15),
            size: 24,
          ),
        ),
        Positioned(
          top: 100,
          left: 25,
          child: Icon(
            Icons.desktop_mac,
            color: AppColors.secondary.withOpacity(0.1),
            size: 20,
          ),
        ),
        Positioned(
          bottom: 80,
          right: 60,
          child: Icon(
            Icons.watch,
            color: AppColors.secondary.withOpacity(0.2),
            size: 18,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 40,
          child: Icon(
            Icons.tablet,
            color: AppColors.secondary.withOpacity(0.12),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _SecurityPattern extends StatelessWidget {
  const _SecurityPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 25,
          left: 35,
          child: Icon(
            Icons.lock,
            color: AppColors.success.withOpacity(0.15),
            size: 20,
          ),
        ),
        Positioned(
          top: 90,
          right: 30,
          child: Icon(
            Icons.security,
            color: AppColors.success.withOpacity(0.12),
            size: 24,
          ),
        ),
        Positioned(
          bottom: 70,
          left: 25,
          child: Icon(
            Icons.verified,
            color: AppColors.success.withOpacity(0.18),
            size: 18,
          ),
        ),
        Positioned(
          bottom: 35,
          right: 50,
          child: Icon(
            Icons.privacy_tip,
            color: AppColors.success.withOpacity(0.1),
            size: 26,
          ),
        ),
      ],
    );
  }
}
