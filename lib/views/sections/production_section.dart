import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/studio_viewmodel.dart';
import '../../models/app_state.dart';

class ProductionSection extends ConsumerWidget {
  const ProductionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(productionLogsProvider);

    final status = ref.watch(studioStatusProvider);
    final isBaking = status == StudioStatus.baking;
    final isAnyProcessing = status != StudioStatus.idle;
    final isVoiceReady = ref.watch(voiceoverReadyProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FINAL PRODUCTION',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Ready for production...',
                        style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '> ',
                                style: TextStyle(color: Color(0xFFDA291C), fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                              ),
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (isAnyProcessing || !isVoiceReady)
                ? null 
                : () => StudioViewModel(ref).bakeVideo(),
            icon: isBaking 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.movie_creation, size: 28),
            label: Text(
              isBaking ? 'BAKING VIDEO...' : 'BAKE FINAL VIDEO',
              style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDA291C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
