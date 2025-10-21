import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_snackbar.dart';
import '../utils/app_localizations.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final String _storeUrl =
      'https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/refs/heads/main/store.json';
  List<dynamic> _storeItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(_storeUrl))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                context.tr(TranslationKeys.errorConnectionTimeout),
              );
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _storeItems = data;
          _filteredItems = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = context.tr(
            TranslationKeys.storeScreenFailedToLoad,
            parameters: {'code': response.statusCode.toString()},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            context.tr(TranslationKeys.errorNetwork) + ': ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _storeItems.where((item) {
        final name = item['name'].toString().toLowerCase();
        final dev = item['dev'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) || dev.contains(query);
      }).toList();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(TranslationKeys.storeScreenUrlCopied))),
    );
  }

  Future<void> _addToSubscriptions(String name, String url) async {
    final provider = Provider.of<V2RayProvider>(context, listen: false);

    try {
      // Check if subscription with this name already exists
      if (provider.subscriptions.any((s) => s.name == name)) {
        ErrorSnackbar.show(
          context,
          context.tr(TranslationKeys.storeScreenSubscriptionExists),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.storeScreenAddingSubscription),
          ),
        ),
      );

      // Add subscription
      await provider.addSubscription(name, url.trim());

      // Check if there was an error
      if (provider.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        provider.clearError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.storeScreenSubscriptionAdded),
            ),
          ),
        );
      }
    } catch (e) {
      ErrorSnackbar.show(
        context,
        context.tr(TranslationKeys.errorUnknown) + ': ${e.toString()}',
      );
    }
  }

  Future<void> _launchTelegramUrl() async {
    final Uri url = Uri.parse('https://t.me/h3dev');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          context.tr(TranslationKeys.storeScreenCouldNotLaunch),
        );
      }
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppTheme.secondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(TranslationKeys.storeScreenAddNew),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.telegram,
                    color: Colors.blue,
                    size: 28,
                  ),
                  title: Text(
                    context.tr(TranslationKeys.storeScreenContactTelegram),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchTelegramUrl();
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.tr(TranslationKeys.storeScreenCancel),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.storeScreenSubscriptionStore)),
        backgroundColor: AppTheme.surfaceContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStoreData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.surfaceDark, AppTheme.surfaceDarker],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.tr(TranslationKeys.storeScreenSearchHint),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterItems();
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchStoreData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                            child: Text(
                              context.tr(TranslationKeys.storeScreenRetry),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        context.tr(TranslationKeys.storeScreenNoSubscriptions),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withOpacity(0.1),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['name'] ??
                                            context.tr(
                                              TranslationKeys
                                                  .storeScreenUnknown,
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                // Developer name below subscription name
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    item['dev'] ??
                                        context.tr(
                                          TranslationKeys.storeScreenUnknown,
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.link,
                                        color: Colors.white54,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['url'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: AppTheme.primaryBlue,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _copyToClipboard(item['url'] ?? ''),
                                        tooltip: context.tr(
                                          TranslationKeys.storeScreenCopyUrl,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                        context.tr(
                                          TranslationKeys.storeScreenAddToApp,
                                        ),
                                      ),
                                      onPressed: () => _addToSubscriptions(
                                        item['name'] ??
                                            context.tr(
                                              TranslationKeys
                                                  .storeScreenUnknown,
                                            ),
                                        item['url'] ?? '',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showContactDialog,
        backgroundColor: AppTheme.primaryBlue,
        mini: true,
        child: const Icon(Icons.contact_support, color: Colors.white),
      ),
    );
  }
}
