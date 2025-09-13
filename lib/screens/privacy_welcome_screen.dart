import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class PrivacyWelcomeScreen extends StatefulWidget {
  const PrivacyWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  bool _acceptedPrivacy = false;
  bool _backgroundAccessHandled = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // If on privacy page and checkbox not checked, don't proceed
    if (_currentPage == 1 && !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the privacy policy to continue'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // If on background access page and not handled, show dialog
    if (_currentPage == 3 && !_backgroundAccessHandled) {
      _showBackgroundAccessDialog();
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _savePreferenceAndNavigate();
    }
  }

  void _savePreferenceAndNavigate() async {
    if (_acceptedPrivacy) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } else {
      // Show warning dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Privacy Policy Not Accepted',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: const Text(
              'You have not accepted the privacy policy. You can continue to use the app, but you will not receive support or help. Do you want to proceed?',
              style: TextStyle(color: Colors.white70),
            ),
            backgroundColor: AppTheme.primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('privacy_accepted', true);

                  if (mounted) {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Proceed Anyway',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showBackgroundAccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Background Access Required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Text(
            'For better app performance and to maintain VPN connection in background, please allow background access.',
            style: TextStyle(color: Colors.white70),
          ),
          backgroundColor: AppTheme.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Stay on the current page
              },
              child: const Text(
                'Stay',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                setState(() {
                  _backgroundAccessHandled = true;
                });
                _nextPage(); // Continue to next page
              },
              child: const Text(
                'Next',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openGeneralBatterySettings() async {
    print('Attempting to open general battery settings...');
    try {
      const platform = MethodChannel('com.cloud.pira/settings');
      final result = await platform.invokeMethod('openGeneralBatterySettings');
      print('General battery settings opened successfully: $result');
    } catch (e) {
      print('Error opening general battery settings: $e');
      // Final fallback: open app settings
      try {
        const platform = MethodChannel('com.cloud.pira/settings');
        final result = await platform.invokeMethod('openAppSettings');
        print('App settings opened as fallback: $result');
      } catch (e2) {
        print('All settings options failed: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open any settings: $e2'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _openBackgroundSettings() async {
    print('Attempting to open background settings...');
    try {
      // Use platform channel to open Android battery optimization settings
      const platform = MethodChannel('com.cloud.pira/settings');
      final result = await platform.invokeMethod('openBatteryOptimizationSettings');
      print('Settings opened successfully: $result');
    } catch (e) {
      print('Error opening battery optimization settings: $e');
      // Fallback: open general app settings
      try {
        const platform = MethodChannel('com.cloud.pira/settings');
        final result = await platform.invokeMethod('openAppSettings');
        print('App settings opened successfully: $result');
      } catch (e2) {
        print('Error opening app settings: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open settings: $e2'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryDark.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _savePreferenceAndNavigate,
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildPrivacyPage(),
                        _buildNoLimitsPage(),
                        _buildBackgroundAccessPage(),
                        _buildFreeToUsePage(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _totalPages,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Next button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_currentPage == 1 && !_acceptedPrivacy)
                                ? null
                                : _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: AppTheme.primaryGreen
                                  .withOpacity(0.3),
                            ),
                            child: Text(
                              _currentPage == _totalPages - 1
                                  ? 'Get Started'
                                  : (_currentPage == 3 && !_backgroundAccessHandled)
                                      ? 'Next'
                                      : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 100, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Proxy Cloud',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'An open-source VPN that\'s fast, unlimited, secure, and completely free.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.privacy_tip,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We don\'t track, store, or share your data. Your online activity remains private and secure.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedPrivacy,
                  onChanged: (value) {
                    setState(() {
                      _acceptedPrivacy = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'I accept the ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      InkWell(
                        onTap: () async {
                          // Open privacy policy link
                          final Uri url = Uri.parse(
                            'https://github.com/code3-dev/ProxyCloud/blob/master/PRIVACY.md',
                          );
                          try {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open Privacy Policy',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'privacy policy',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' and ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      InkWell(
                        onTap: () async {
                          // Open terms of service link
                          final Uri url = Uri.parse(
                            'https://github.com/code3-dev/ProxyCloud/blob/master/TERMS.md',
                          );
                          try {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open Terms of Service',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'terms of service',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLimitsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed, size: 100, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            const Text(
              'No Limits',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enjoy unlimited bandwidth and server switches. Browse, stream, and download without restrictions.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundAccessPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.battery_charging_full,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Background Access',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Allow the app to run in background for better VPN performance and connection stability.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Primary button - Open Settings
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openBackgroundSettings,
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                label: const Text(
                  'Open Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary button - Open Battery Settings
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openGeneralBatterySettings,
                icon: const Icon(
                  Icons.battery_charging_full,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text(
                  'Battery Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Disable battery optimization for ProxyCloud to ensure the VPN stays connected while the app is in background.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeToUsePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Fully Free',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This app is completely free to use. No hidden fees, no subscriptions, no ads.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
