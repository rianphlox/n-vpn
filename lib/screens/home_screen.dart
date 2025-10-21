import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../widgets/connection_button.dart';
import '../widgets/server_selector.dart';
import '../widgets/background_gradient.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import '../services/v2ray_service.dart';
import 'subscription_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = ''; // Default to empty subscription URL

    // Ping functionality removed

    // Listen for connection state changes
    final v2rayProvider = Provider.of<V2RayProvider>(context, listen: false);
    v2rayProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    // Ping functionality removed
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Share V2Ray link to clipboard
  void _shareV2RayLink(BuildContext context) async {
    try {
      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final activeConfig = provider.activeConfig;

      if (activeConfig != null && activeConfig.fullConfig.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: activeConfig.fullConfig));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.connectedGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('home.v2ray_link_copied'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardDark,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('home.no_v2ray_config'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('home.error_copying')}: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Check config method to test connectivity to Google
  Future<void> _checkConfig(V2RayProvider provider) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(context.tr('home.checking_config')),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final startTime = DateTime.now();
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Close the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        // Show success message with ping time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.tr('home.config_ok')} (${duration.inMilliseconds}ms)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.connectedGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.tr('home.config_not_working')} (${response.statusCode})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${context.tr('home.config_not_working')}: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: BackgroundGradient(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(context.tr(TranslationKeys.homeTitle)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final provider = Provider.of<V2RayProvider>(
                        context,
                        listen: false,
                      );

                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('home.updating_subscriptions'),
                          ),
                        ),
                      );

                      // Update all subscriptions instead of just fetching servers
                      await provider.updateAllSubscriptions();
                      provider.fetchNotificationStatus();

                      // Show success message
                      if (provider.errorMessage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('home.subscriptions_updated'),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.errorMessage)),
                        );
                        provider.clearError();
                      }
                    },
                    tooltip: context.tr(TranslationKeys.homeRefresh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.vpn_key),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SubscriptionManagementScreen(),
                        ),
                      );
                    },
                    tooltip: context.tr(TranslationKeys.homeSubscriptions),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                    tooltip: context.tr(TranslationKeys.homeAbout),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Connection status removed as requested

                  // Main content
                  Expanded(
                    child: Consumer<V2RayProvider>(
                      builder: (context, provider, _) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Server selector (now includes Proxy Mode Switch)
                                const ServerSelector(),

                                const SizedBox(height: 20),

                                // Connection button
                                const ConnectionButton(),

                                const SizedBox(height: 40),

                                // Connection stats
                                if (provider.activeConfig != null)
                                  _buildConnectionStats(provider),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStats(V2RayProvider provider) {
    // Get the V2RayService instance
    final v2rayService = provider.v2rayService;

    // Use StreamBuilder to update the UI when statistics change
    return StreamBuilder(
      // Create a periodic stream to update the UI every second
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final ipInfo = v2rayService.ipInfo;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('home.connection_statistics'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.timer,
                context.tr(TranslationKeys.homeConnectionTime),
                v2rayService.getFormattedConnectedTime(),
              ),
              const Divider(height: 24),

              // Total traffic usage
              _buildTrafficRow(
                context.tr('home.traffic_usage'),
                v2rayService.getFormattedUpload(),
                v2rayService.getFormattedDownload(),
                v2rayService.getFormattedTotalTraffic(),
              ),
              const Divider(height: 24),
              // Server ping information removed
              if (v2rayService.isLoadingIpInfo)
                _buildLoadingIpInfoRow()
              else if (ipInfo != null && ipInfo.success)
                _buildIpInfoRow(ipInfo, provider)
              else
                _buildIpErrorRow(
                  context.tr('home.ip_information'),
                  ipInfo?.errorMessage ?? context.tr('home.cant_get_ip'),
                  () async {
                    // Retry fetching IP info
                    await v2rayService.fetchIpInfo();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Cached ping value and loading state
  // Ping functionality removed

  // Server ping row removed

  Widget _buildIpInfoRow(IpInfo ipInfo, V2RayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${ipInfo.country} - ${ipInfo.city}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _shareV2RayLink(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.share, size: 18, color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Check Config button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _checkConfig(provider),
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.tr('home.check_config')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textGrey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildIpErrorRow(
    String label,
    String errorMessage,
    VoidCallback onRetry,
  ) {
    return Row(
      children: [
        const Icon(Icons.public, size: 18, color: AppTheme.textGrey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        const Spacer(),
        Text(
          errorMessage,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.refresh,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIpInfoRow() {
    return Row(
      children: [
        const Icon(Icons.public, size: 18, color: AppTheme.textGrey),
        const SizedBox(width: 12),
        Text(
          context.tr('home.ip_information'),
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        const Spacer(),
        Text(
          context.tr('home.fetching'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficRow(
    String label,
    String upload,
    String download,
    String total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.data_usage, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppTheme.textGrey)),
            const Spacer(),
            Text(
              total,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      upload,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      ' ↑',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      download,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Text(
                      ' ↓',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
