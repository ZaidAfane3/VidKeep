import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../providers/providers.dart';

/// Settings screen for server configuration
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
          'SERVER CONFIG',
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const Spacer(),
          Text(
            'Examples:\n'
            '• Local: http://192.168.1.100:3001\n'
            '• Tailscale: http://vidkeep.ts.net:3001\n'
            '• HTTPS: https://vidkeep.yourdomain.com',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
