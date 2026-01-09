import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../core/config/app_config.dart';
import '../../widgets/scanlines_overlay.dart';
import '../../widgets/blinking_cursor.dart';
import '../../widgets/video_grid.dart';
import '../../providers/providers.dart';
import '../../providers/video_providers.dart';
import '../settings/settings_screen.dart';

/// Home screen with video grid and navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlinkingCursor(),
            const SizedBox(width: 4),
            Text(
              AppConfig.appName.toUpperCase(),
              style: GoogleFonts.shareTechMono(
                color: AppColors.neonGreen,
                fontSize: 20,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildAddButton(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          // CRT Scanlines overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: ScanlinesOverlay(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Open ingest modal
        _showIngestDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.neonGreen, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.neonGreen, size: 16),
            const SizedBox(width: 6),
            Text(
              'ADD VIDEO',
              style: GoogleFonts.shareTechMono(
                color: AppColors.neonGreen,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngestDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'ADD VIDEO',
          style: GoogleFonts.shareTechMono(color: AppColors.neonGreen),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.shareTechMono(color: AppColors.neonGreen),
          decoration: InputDecoration(
            hintText: 'Paste YouTube URL',
            hintStyle: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                await _ingestVideo(url);
              }
            },
            child: Text(
              'ADD',
              style: GoogleFonts.shareTechMono(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ingestVideo(String url) async {
    final repo = ref.read(videoRepositoryProvider);
    if (repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server not configured',
            style: GoogleFonts.shareTechMono(),
          ),
          backgroundColor: AppColors.statusFailed,
        ),
      );
      return;
    }

    try {
      await repo.ingestVideo(url);
      ref.read(videosProvider.notifier).loadVideos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video queued for download',
              style: GoogleFonts.shareTechMono(),
            ),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.shareTechMono(),
            ),
            backgroundColor: AppColors.statusFailed,
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const VideoGrid();
      case 1:
        return _buildFavoritesView();
      case 2:
        return _buildQueueView();
      case 3:
        return _buildSettingsView();
      default:
        return const VideoGrid();
    }
  }

  Widget _buildFavoritesView() {
    // Use same grid but with favorites filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(videosProvider);
      if (!state.favoritesOnly) {
        ref.read(videosProvider.notifier).toggleFavoritesOnly();
      }
    });
    return const VideoGrid();
  }

  Widget _buildQueueView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 60,
            color: AppColors.neonGreen.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'DOWNLOAD QUEUE',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in next phase',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return const SettingsScreen();
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Reset favorites filter when leaving favorites tab
            if (_currentIndex == 1 && index != 1) {
              final state = ref.read(videosProvider);
              if (state.favoritesOnly) {
                ref.read(videosProvider.notifier).toggleFavoritesOnly();
              }
            }
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'FAVORITES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.download_outlined),
              activeIcon: Icon(Icons.download),
              label: 'QUEUE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
