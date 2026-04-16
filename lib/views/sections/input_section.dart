import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/studio_viewmodel.dart';
import '../../models/app_state.dart';
import '../news_pool_page.dart';

class InputSection extends ConsumerStatefulWidget {
  const InputSection({super.key});

  @override
  ConsumerState<InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends ConsumerState<InputSection> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(newsStoriesProvider);
    final status = ref.watch(studioStatusProvider);
    final isAnyProcessing = status != StudioStatus.idle;
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RAW NEWS POOL',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white54,
                ),
              ),
              if (stories.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewsPoolPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA291C),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDA291C).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stories.length} STORIES',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'News Title (Source or Headline)',
              hintStyle: TextStyle(color: Colors.white24),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _bodyController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Paste news story content here...',
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAnyProcessing ? null : () {
                    if (_titleController.text.isNotEmpty && _bodyController.text.isNotEmpty) {
                      ref.read(newsStoriesProvider.notifier).addStory(
                        _titleController.text,
                        _bodyController.text,
                      );
                      _titleController.clear();
                      _bodyController.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('MERGE NEWS'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: isAnyProcessing ? null : () {
                  ref.read(newsStoriesProvider.notifier).clearAll();
                  ref.read(finalScriptProvider.notifier).clear();
                  ref.read(optimizationProvider.notifier).setData(OptimizationData.empty());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                child: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
