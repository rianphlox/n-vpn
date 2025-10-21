import 'package:flutter/material.dart';
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
  const PrivacyWelcomeScreen({super.key});

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2; // Language selection and Privacy pages only
  bool _acceptedPrivacy = false;

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
    if (_currentPage == 1 && !_acceptedPrivacy) {
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
                  style: const TextStyle(color: AppTheme.primaryBlue),
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
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          );
        },
      );
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
                        _buildLanguageSelectionPage(),
                        _buildPrivacyPage(),
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
                                  ? context.tr('privacy_welcome.get_started')
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
                              context.tr('about.privacy_policy'),
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
                              context.tr('about.terms_of_service'),
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
}
