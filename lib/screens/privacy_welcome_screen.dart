import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import '../utils/app_localizations.dart';
import '../models/app_language.dart';
import '../providers/language_provider.dart';

class PrivacyWelcomeScreen extends StatefulWidget {
  const PrivacyWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages =
      6; // Increased from 5 to 6 to accommodate language selection
  bool _acceptedPrivacy = false;
  bool _backgroundAccessHandled = false;
  AppLanguage? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Initialize with the current language or device language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      setState(() {
        _selectedLanguage = languageProvider.currentLanguage;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // If on language selection page and no language selected, don't proceed
    if (_currentPage == 0 && _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(TranslationKeys.selectLanguagePrompt)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // If on privacy page and checkbox not checked, don't proceed
    if (_currentPage == 2 && !_acceptedPrivacy) {
      // Changed from 1 to 2 because we added language page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.privacyWelcomeAcceptPrivacyPolicy),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // If on background access page and not handled, show dialog
    if (_currentPage == 4 && !_backgroundAccessHandled) {
      // Changed from 3 to 4
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
    // Save selected language if changed
    if (_selectedLanguage != null) {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      await languageProvider.changeLanguage(_selectedLanguage!);
    }

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
            title: Text(
              context.tr('privacy_welcome.privacy_not_accepted_title'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: Text(
              context.tr('privacy_welcome.privacy_not_accepted_content'),
              style: const TextStyle(color: Colors.white70),
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
                child: Text(
                  context.tr('common.cancel'),
                  style: const TextStyle(color: AppTheme.primaryGreen),
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
                child: Text(
                  context.tr('privacy_welcome.proceed_anyway'),
                  style: const TextStyle(color: AppTheme.primaryGreen),
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
          title: Text(
            context.tr('privacy_welcome.background_access_required'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            context.tr('privacy_welcome.background_access_content'),
            style: const TextStyle(color: Colors.white70),
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
              child: Text(
                context.tr('privacy_welcome.stay'),
                style: const TextStyle(color: Colors.white70),
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
              child: Text(
                context.tr('common.next'),
                style: const TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openGeneralBatterySettings() async {
    print(context.tr('privacy_welcome.opening_general_battery'));
    try {
      const platform = MethodChannel('com.cloud.pira/settings');
      final result = await platform.invokeMethod('openGeneralBatterySettings');
      print('${context.tr('privacy_welcome.general_battery_opened')}: $result');
    } catch (e) {
      print(
        '${context.tr('privacy_welcome.error_opening_general_battery')}: $e',
      );
      // Final fallback: open app settings
      try {
        const platform = MethodChannel('com.cloud.pira/settings');
        final result = await platform.invokeMethod('openAppSettings');
        print(
          '${context.tr('privacy_welcome.app_settings_opened_fallback')}: $result',
        );
      } catch (e2) {
        print('${context.tr('privacy_welcome.all_settings_failed')}: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr('privacy_welcome.could_not_open_settings')}: $e2',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _openBackgroundSettings() async {
    print(context.tr('privacy_welcome.opening_background_settings'));
    try {
      // Use platform channel to open Android battery optimization settings
      const platform = MethodChannel('com.cloud.pira/settings');
      final result = await platform.invokeMethod(
        'openBatteryOptimizationSettings',
      );
      print(
        '${context.tr('privacy_welcome.settings_opened_successfully')}: $result',
      );
    } catch (e) {
      print(
        '${context.tr('privacy_welcome.error_opening_battery_settings')}: $e',
      );
      // Fallback: open general app settings
      try {
        const platform = MethodChannel('com.cloud.pira/settings');
        final result = await platform.invokeMethod('openAppSettings');
        print('${context.tr('privacy_welcome.app_settings_opened')}: $result');
      } catch (e2) {
        print(
          '${context.tr('privacy_welcome.error_opening_app_settings')}: $e2',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr('privacy_welcome.could_not_open_settings')}: $e2',
              ),
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
                          child: Text(
                            context.tr('privacy_welcome.skip'),
                            style: const TextStyle(color: Colors.white70),
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
                        _buildLanguageSelectionPage(), // Added language selection page
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
                            onPressed:
                                (_currentPage == 2 &&
                                    !_acceptedPrivacy) // Changed from 1 to 2
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
                                  ? context.tr('privacy_welcome.get_started')
                                  : (_currentPage == 4 && // Changed from 3 to 4
                                        !_backgroundAccessHandled)
                                  ? context.tr('common.next')
                                  : context.tr('common.next'),
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

  Widget _buildLanguageSelectionPage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

        final languageNameStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn()
            : const TextStyle();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.language,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr(TranslationKeys.selectLanguageTitle),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(TranslationKeys.selectLanguageSubtitle),
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Language selection grid
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, child) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: AppLanguage.supportedLanguages.length,
                      itemBuilder: (context, index) {
                        final language = AppLanguage.supportedLanguages[index];
                        final isSelected =
                            _selectedLanguage?.code == language.code;

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              _selectedLanguage = language;
                            });

                            // Change language in real time
                            await langProvider.changeLanguage(language);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen.withOpacity(0.3)
                                  : AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  language.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  language.name,
                                  style: languageNameStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomePage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('privacy_welcome.welcome_title'),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('privacy_welcome.welcome_subtitle'),
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

        final checkboxTextStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(color: Colors.white70)
            : const TextStyle(color: Colors.white70);

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
                Text(
                  context.tr('privacy_welcome.privacy_title'),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('privacy_welcome.privacy_subtitle'),
                  style: subtitleStyle,
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
                          Text(
                            context.tr('privacy_welcome.i_accept'),
                            style: checkboxTextStyle,
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
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          'privacy_welcome.could_not_open_privacy',
                                        ),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              context.tr('privacy_welcome.privacy_policy'),
                              style: checkboxTextStyle.copyWith(
                                color: AppTheme.primaryGreen,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            context.tr('privacy_welcome.and'),
                            style: checkboxTextStyle,
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
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          'privacy_welcome.could_not_open_terms',
                                        ),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              context.tr('privacy_welcome.terms_of_service'),
                              style: checkboxTextStyle.copyWith(
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
      },
    );
  }

  Widget _buildNoLimitsPage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.speed,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('privacy_welcome.no_limits_title'),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('privacy_welcome.no_limits_subtitle'),
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundAccessPage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

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
                Text(
                  context.tr('privacy_welcome.background_access_title'),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('privacy_welcome.background_access_subtitle'),
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Primary button - Open Settings
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBackgroundSettings,
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: Text(
                      context.tr('privacy_welcome.open_settings'),
                      style: const TextStyle(
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
                    label: Text(
                      context.tr('privacy_welcome.battery_settings'),
                      style: const TextStyle(
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
                Text(
                  context.tr('privacy_welcome.battery_optimization_note'),
                  style: const TextStyle(
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
      },
    );
  }

  Widget _buildFreeToUsePage() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtlLanguage =
            languageProvider.currentLanguage.code == 'fa' ||
            languageProvider.currentLanguage.code == 'ar';

        final titleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              );

        final subtitleStyle = isRtlLanguage
            ? GoogleFonts.vazirmatn(fontSize: 16, color: Colors.white70)
            : const TextStyle(fontSize: 16, color: Colors.white70);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.money_off,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('privacy_welcome.free_to_use_title'),
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('privacy_welcome.free_to_use_subtitle'),
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
