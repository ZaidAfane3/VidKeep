import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../providers/download_providers.dart';
import '../../data/models/download_settings.dart';

/// Settings screen for server configuration and download settings
class SettingsScreen extends ConsumerStatefulWidget {
  final bool embedded; // If true, embedded in tab view (no back button)
  
  const SettingsScreen({super.key, this.embedded = true});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    // Load saved server URL
    final savedUrl = ref.read(serverUrlProvider);
    if (savedUrl != null) {
      _urlController.text = savedUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _testResult = 'Please enter a URL');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // Save URL first so provider creates client
      await ref.read(serverUrlProvider.notifier).setServerUrl(url);
      
      // Test connection
      final apiClient = ref.read(apiClientProvider);
      if (apiClient != null) {
        final success = await apiClient.testConnection();
        setState(() {
          _testResult = success ? '✓ CONNECTION SUCCESSFUL' : '✗ CONNECTION FAILED';
        });
      }
    } catch (e) {
      setState(() => _testResult = '✗ ERROR: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ref.read(serverUrlProvider.notifier).setServerUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server URL saved',
              style: GoogleFonts.shareTechMono(),
            ),
            backgroundColor: AppColors.darkGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // When embedded, just show the content without scaffold/appbar
    if (widget.embedded) {
      return _buildContent();
    }
    
    // When pushed as a route, show full scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neonGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildServerSection(),
          const SizedBox(height: 32),
          _buildDownloadsSection(),
          const SizedBox(height: 32),
          _buildHelpSection(),
        ],
      ),
    );
  }

  Widget _buildServerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SERVER CONFIGURATION',
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your VidKeep server URL:',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'http://192.168.1.100:3001',
            hintStyle: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: const Icon(Icons.dns, color: AppColors.neonGreen),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isTesting ? null : _testConnection,
                child: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neonGreen,
                        ),
                      )
                    : Text(
                        'TEST',
                        style: GoogleFonts.shareTechMono(fontSize: 12),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveUrl,
                child: Text(
                  'SAVE',
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(
                color: _testResult!.contains('✓')
                    ? AppColors.neonGreen
                    : AppColors.statusFailed,
              ),
            ),
            child: Text(
              _testResult!,
              style: GoogleFonts.shareTechMono(
                color: _testResult!.contains('✓')
                    ? AppColors.neonGreen
                    : AppColors.statusFailed,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadsSection() {
    final settingsAsync = ref.watch(downloadSettingsProvider);
    final storageUsedAsync = ref.watch(downloadStorageUsedProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DOWNLOADS',
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        settingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonGreen),
          ),
          error: (err, stack) => Text(
            'Error loading settings: $err',
            style: GoogleFonts.shareTechMono(color: AppColors.statusFailed, fontSize: 12),
          ),
          data: (settings) => Column(
            children: [
              // WiFi only toggle
              _buildSettingsTile(
                icon: Icons.wifi,
                title: 'WIFI ONLY',
                subtitle: 'Only download on WiFi connections',
                trailing: Switch(
                  value: settings.wifiOnly,
                  onChanged: (value) {
                    ref.read(downloadSettingsNotifierProvider.notifier).setWifiOnly(value);
                  },
                  activeTrackColor: AppColors.neonGreen,
                ),
              ),
              const Divider(color: AppColors.borderColor, height: 1),
              
              // Pause on low battery toggle
              _buildSettingsTile(
                icon: Icons.battery_alert,
                title: 'PAUSE ON LOW BATTERY',
                subtitle: 'Pause downloads when battery is low',
                trailing: Switch(
                  value: settings.pauseOnLowBattery,
                  onChanged: (value) {
                    ref.read(downloadSettingsNotifierProvider.notifier).setPauseOnLowBattery(value);
                  },
                  activeTrackColor: AppColors.neonGreen,
                ),
              ),
              const Divider(color: AppColors.borderColor, height: 1),
              
              // Concurrent downloads picker
              _buildSettingsTile(
                icon: Icons.download,
                title: 'CONCURRENT DOWNLOADS',
                subtitle: 'Max simultaneous downloads: ${settings.maxConcurrent}',
                trailing: DropdownButton<int>(
                  value: settings.maxConcurrent,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.shareTechMono(color: AppColors.neonGreen),
                  underline: const SizedBox(),
                  items: [1, 2, 3, 4, 5].map((value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value'),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(downloadSettingsNotifierProvider.notifier).setMaxConcurrent(value);
                    }
                  },
                ),
              ),
              const Divider(color: AppColors.borderColor, height: 1),
              
              // Storage limit picker
              _buildSettingsTile(
                icon: Icons.storage,
                title: 'STORAGE LIMIT',
                subtitle: settings.formattedStorageLimit,
                trailing: DropdownButton<int?>(
                  value: DownloadSettingsModel.storageLimitOptions.contains(settings.storageLimitMB) 
                      ? settings.storageLimitMB 
                      : null,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.shareTechMono(color: AppColors.neonGreen),
                  underline: const SizedBox(),
                  items: DownloadSettingsModel.storageLimitOptions.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(DownloadSettingsModel.getLimitLabel(value)),
                  )).toList(),
                  onChanged: (value) {
                    ref.read(downloadSettingsNotifierProvider.notifier).setStorageLimit(value);
                  },
                ),
              ),
              const Divider(color: AppColors.borderColor, height: 1),
              
              // Storage used display
              storageUsedAsync.when(
                loading: () => _buildSettingsTile(
                  icon: Icons.folder,
                  title: 'STORAGE USED',
                  subtitle: 'Calculating...',
                  trailing: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
                  ),
                ),
                error: (err, stack) => _buildSettingsTile(
                  icon: Icons.folder,
                  title: 'STORAGE USED',
                  subtitle: 'Error calculating',
                  trailing: const Icon(Icons.error, color: AppColors.statusFailed),
                ),
                data: (usedBytes) {
                  final usedMB = usedBytes / (1024 * 1024);
                  final usedText = usedMB >= 1024 
                      ? '${(usedMB / 1024).toStringAsFixed(2)} GB'
                      : '${usedMB.toStringAsFixed(1)} MB';
                  
                  final limitMB = settings.storageLimitMB;
                  final percentUsed = limitMB != null ? (usedMB / limitMB).clamp(0.0, 1.0) : 0.0;
                  
                  return Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.folder,
                        title: 'STORAGE USED',
                        subtitle: limitMB != null 
                            ? '$usedText of ${settings.formattedStorageLimit}'
                            : usedText,
                        trailing: const SizedBox(),
                      ),
                      if (limitMB != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percentUsed,
                              backgroundColor: AppColors.darkGreen,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentUsed > 0.9 ? AppColors.statusFailed : AppColors.neonGreen,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const Divider(color: AppColors.borderColor, height: 1),
              
              // Clear All Downloads button
              InkWell(
                onTap: () => _showClearAllConfirmation(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: AppColors.statusFailed, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CLEAR ALL DOWNLOADS',
                              style: GoogleFonts.shareTechMono(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Delete all downloaded videos and free storage',
                              style: GoogleFonts.shareTechMono(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.terminalBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.neonGreen, width: 1),
        ),
        title: Text(
          'CLEAR ALL DOWNLOADS?',
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 14,
          ),
        ),
        content: Text(
          'This will delete all downloaded videos from your device. '
          'Videos will still be available on the server.',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.shareTechMono(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(downloadActionsProvider.notifier).deleteAllDownloads();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'ALL DOWNLOADS CLEARED' : 'FAILED TO CLEAR DOWNLOADS',
                      style: GoogleFonts.shareTechMono(fontSize: 12),
                    ),
                    backgroundColor: success ? AppColors.darkGreen : AppColors.statusFailed,
                  ),
                );
                // Refresh storage display
                ref.invalidate(downloadStorageUsedProvider);
              }
            },
            child: Text(
              'CLEAR ALL',
              style: GoogleFonts.shareTechMono(
                color: AppColors.statusFailed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server URL Examples:',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '• Local: http://192.168.1.100:3001\n'
          '• Tailscale: http://vidkeep.ts.net:3001\n'
          '• HTTPS: https://vidkeep.yourdomain.com',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
