import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../viewmodels/studio_viewmodel.dart';
import '../../models/app_state.dart';
import '../../models/channel_info_state.dart';
import '../optimization_page.dart';
import '../settings_page.dart';
import '../dialogs/channel_info_dialog.dart';

class HeaderSection extends ConsumerWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(studioStatusProvider);
    final channelInfo = ref.watch(channelInfoProvider);
    final isAnyProcessing = status != StudioStatus.idle;

    String statusText;
    switch (status) {
      case StudioStatus.scripting: statusText = 'SCRIPTING...'; break;
      case StudioStatus.voicing: statusText = 'VOICEOVER...'; break;
      case StudioStatus.baking: statusText = 'BAKING...'; break;
      default: statusText = 'IDLE';
    }

    final isShortScreen = MediaQuery.of(context).size.height < 800;

    return Padding(
      padding: EdgeInsets.all(isShortScreen ? 16.0 : 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.solidCircleDot, color: Color(0xFFDA291C), size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${channelInfo.name} Studio',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Production & Automation Dashboard',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAnyProcessing ? const Color(0xFFDA291C).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAnyProcessing ? const Color(0xFFDA291C) : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAnyProcessing)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA291C)),
                    ),
                  )
                else
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: isAnyProcessing ? const Color(0xFFDA291C) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Studio Settings',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ChannelInfoDialog(),
              );
            },
            icon: const Icon(Icons.branding_watermark_outlined, color: Colors.white70),
            tooltip: 'Channel Identity',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OptimizationPage()),
              );
            },
            icon: const Icon(Icons.analytics_outlined, color: Colors.white70),
            tooltip: 'SEO Dashboard',
          ),
        ],
      ),
    );
  }
}
