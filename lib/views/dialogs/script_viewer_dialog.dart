import 'dart:ui';
import 'package:flutter/material.dart';

class ScriptViewerDialog extends StatelessWidget {
  final String script;

  const ScriptViewerDialog({super.key, required this.script});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Stack(
        children: [
          // Glassy Background
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFFDA291C)),
                          const SizedBox(width: 12),
                          const Text(
                            'FULL PRODUCTION SCRIPT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.of(context).pop(),
                            hoverColor: Colors.white10,
                          ),
                        ],
                      ),
                    ),
                    
                    // Script Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: SelectableText(
                          script,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.8,
                            fontFamily: 'Georgia', // More readable for long text
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Optional: Add copy functionality
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('COPY TO CLIPBOARD'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white54),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDA291C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('DONE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
