import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/studio_viewmodel.dart';
import '../models/app_state.dart';

class OptimizationPage extends ConsumerWidget {
  const OptimizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(optimizationProvider);
    final status = ref.watch(studioStatusProvider);
    final isGenerating = status == StudioStatus.scripting;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('STUDIO OPTIMIZATION', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: data.isEmpty
          ? const Center(
              child: Text(
                'Generate a script first to see SEO insights.',
                style: TextStyle(color: Colors.white24, fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle(
                     'TITLE SUGGESTIONS',
                     action: isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDA291C)))
                      : TextButton.icon(
                        onPressed: () => StudioViewModel(ref).regenerateSEO(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('REGENERATE', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDA291C),
                        ),
                      ),
                   ),
                  const SizedBox(height: 12),
                  ...data.titles.map((title) => _buildTitleCard(context, title)),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('SEO DESCRIPTION'),
                  const SizedBox(height: 12),
                  _buildDescriptionBox(context, data.description),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle(
                    'KEYWORDS',
                    action: _buildCopyAction(context, 'KEYWORDS', data.keywords.join(', ')),
                  ),
                  const SizedBox(height: 12),
                  _buildTagCloud(context, data.keywords, isHashtag: false),
                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    'HASHTAGS',
                    action: _buildCopyAction(context, 'HASHTAGS', data.hashtags.map((h) => '#$h').join(' ')),
                  ),
                  const SizedBox(height: 12),
                  _buildTagCloud(context, data.hashtags, isHashtag: true),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDA291C),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildCopyAction(BuildContext context, String label, String text) {
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label copied to clipboard!'),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
        ));
      },
      icon: const Icon(Icons.copy_all, size: 16),
      label: Text('COPY ALL', style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(foregroundColor: Colors.white54),
    );
  }

  Widget _buildTitleCard(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: title));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title copied!')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(BuildContext context, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: description));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description copied!')));
              },
              icon: const Icon(Icons.copy_all, size: 18),
              label: const Text('COPY DESCRIPTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCloud(BuildContext context, List<String> tags, {required bool isHashtag}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHashtag ? const Color(0xFFDA291C).withAlpha(25) : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isHashtag ? const Color(0xFFDA291C).withAlpha(75) : Colors.white10),
        ),
        child: Text(
          isHashtag ? "#$tag" : tag,
          style: TextStyle(
            color: isHashtag ? const Color(0xFFDA291C) : Colors.white70,
            fontSize: 12,
            fontWeight: isHashtag ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      )).toList(),
    );
  }
}
