import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../viewmodels/studio_viewmodel.dart';
import '../../models/app_state.dart';

class VoiceSection extends ConsumerWidget {
  const VoiceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(voiceoverReadyProvider);
    final rate = ref.watch(voiceoverRateProvider);
    final status = ref.watch(studioStatusProvider);
    final script = ref.watch(finalScriptProvider);
    final isVoicing = status == StudioStatus.voicing;
    final isAnyProcessing = status != StudioStatus.idle;
    final isScriptEmpty = script.trim().isEmpty;
    final audioState = ref.watch(isAudioPlayingProvider);
    final isPlaying = audioState.value == PlayerState.playing;
    final isShortScreen = MediaQuery.of(context).size.height < 800;

    return Container(
      padding: EdgeInsets.all(isShortScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VOICEOVER PRODUCTION',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white54,
                ),
              ),
              if (isReady)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          SizedBox(height: isShortScreen ? 12 : 20),
          
          // Speed Selection Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Playback Speed:', 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isScriptEmpty ? Colors.white24 : Colors.white70
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isScriptEmpty ? Colors.white.withAlpha(10) : const Color(0xFFDA291C).withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${rate.toStringAsFixed(1)}x', 
                      style: TextStyle(
                        color: isScriptEmpty ? Colors.white24 : const Color(0xFFDA291C), 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: isScriptEmpty ? Colors.white10 : const Color(0xFFDA291C),
                  inactiveTrackColor: Colors.white10,
                  thumbColor: isScriptEmpty ? Colors.white24 : Colors.white,
                ),
                child: Slider(
                  value: rate.clamp(0.1, 2.0),
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: (isAnyProcessing || isScriptEmpty) ? null : (val) {
                    ref.read(voiceoverRateProvider.notifier).setRate(val);
                  },
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          if (!isReady)
            ElevatedButton.icon(
              onPressed: (isAnyProcessing || isScriptEmpty)
                  ? null 
                  : () => StudioViewModel(ref).generateVoiceover(),
              icon: isVoicing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.mic_none),
              label: Text(isVoicing ? 'GENERATING AUDIO...' : 'GENERATE VOICEOVER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => StudioViewModel(ref).toggleVoiceover(),
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(isPlaying ? 'PAUSE' : 'LISTEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPlaying ? Colors.white12 : Colors.white,
                      foregroundColor: isPlaying ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (isPlaying || audioState.value == PlayerState.paused) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => StudioViewModel(ref).stopVoiceover(),
                    icon: const Icon(Icons.stop, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isAnyProcessing 
                      ? null 
                      : () => StudioViewModel(ref).exportVoiceover(),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('EXPORT'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white10),
                    foregroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isAnyProcessing 
                      ? null 
                      : () => StudioViewModel(ref).generateVoiceover(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('REGENERATE'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white10),
                    foregroundColor: Colors.white70,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
