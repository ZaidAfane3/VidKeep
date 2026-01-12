import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/colors.dart';
import '../providers/video_providers.dart';

/// Channel filter dropdown widget
class ChannelFilter extends ConsumerWidget {
  const ChannelFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider);
    final videosState = ref.watch(videosProvider);
    final selectedChannel = videosState.channelFilter;

    return channels.when(
      data: (channelList) {
        if (channelList.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedChannel,
              hint: Text(
                'ALL CHANNELS',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.neonGreen,
                  fontSize: 12,
                ),
              ),
              dropdownColor: AppColors.cardBg,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonGreen),
              isDense: true,
              items: [
                // "All" option
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'ALL CHANNELS',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Channel list
                ...channelList.map((channel) => DropdownMenuItem<String?>(
                  value: channel.channelName,
                  child: Text(
                    '${channel.channelName.toUpperCase()} (${channel.videoCount})',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
              onChanged: (value) {
                ref.read(videosProvider.notifier).setChannelFilter(value);
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
