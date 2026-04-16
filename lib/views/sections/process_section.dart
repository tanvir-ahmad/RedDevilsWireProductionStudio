import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/studio_viewmodel.dart';
import '../../models/app_state.dart';
import '../dialogs/script_viewer_dialog.dart';

class ProcessSection extends ConsumerStatefulWidget {
  const ProcessSection({super.key});

  @override
  ConsumerState<ProcessSection> createState() => _ProcessSectionState();
}

class _ProcessSectionState extends ConsumerState<ProcessSection> {
  late TextEditingController _scriptController;

  @override
  void initState() {
    super.initState();
    final script = ref.read(finalScriptProvider);
    _scriptController = TextEditingController(text: script);
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(studioStatusProvider);
    final script = ref.watch(finalScriptProvider);
    
    // Update controller text if it's different (e.g., script newly generated)
    if (_scriptController.text != script) {
      _scriptController.text = script;
    }

    final isScripting = status == StudioStatus.scripting;
    final isAnyProcessing = status != StudioStatus.idle;
    final storiesCount = ref.watch(newsStoriesProvider).length;

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
            'SCRIPT GENERATION',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _scriptController,
              maxLines: null,
              expands: true,
              readOnly: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: isScripting ? 'AI is thinking...' : 'Generated script will appear here...',
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: isScripting 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (script.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                      onPressed: isAnyProcessing ? null : () => StudioViewModel(ref).generateScript(),
                      tooltip: 'Regenerate',
                    ) : null),
              ),
              style: const TextStyle(height: 1.5, fontSize: 14, fontFamily: 'Courier'),
            ),
          ),
          const SizedBox(height: 16),
          if (script.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ScriptViewerDialog(script: script),
                ),
                icon: const Icon(Icons.fullscreen, size: 20),
                label: const Text('READ FULL SCRIPT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ElevatedButton(
            onPressed: isAnyProcessing || storiesCount == 0
                ? null 
                : () => StudioViewModel(ref).generateScript(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDA291C),
              disabledBackgroundColor: Colors.white10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScripting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(script.isEmpty ? Icons.psychology_outlined : Icons.auto_awesome),
                const SizedBox(width: 12),
                Text(isScripting 
                  ? 'GENERATING...' 
                  : (script.isEmpty ? 'GENERATE SCRIPT' : 'REGENERATE SCRIPT')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
