import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('STUDIO SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // API Key Generation Section
              const Text(
                'API KEY GENERATION',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                   Expanded(
                    child: _buildKeyGenerationButton(
                      context,
                      'Google Gemini',
                      'https://aistudio.google.com/app/apikey',
                      const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildKeyGenerationButton(
                      context,
                      'Groq API',
                      'https://console.groq.com/keys',
                      const FaIcon(FontAwesomeIcons.bolt, color: Colors.white, size: 20),
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 48),

              // AI Provider Selection
              const Text(
                'AI PROVIDER CONFIGURATION',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildProviderOption(
                    context,
                    'Gemini',
                    AiProvider.gemini,
                    settings.activeProvider == AiProvider.gemini,
                    () => notifier.setProvider(AiProvider.gemini),
                  ),
                  const SizedBox(width: 16),
                  _buildProviderOption(
                    context,
                    'Groq',
                    AiProvider.groq,
                    settings.activeProvider == AiProvider.groq,
                    () => notifier.setProvider(AiProvider.groq),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // API Key Inputs
              _buildModernKeyInput(
                context,
                'Gemini API Key',
                settings.geminiKey,
                (val) => notifier.setGeminiKey(val),
                settings.activeProvider == AiProvider.gemini,
              ),
              const SizedBox(height: 20),
              _buildModernKeyInput(
                context,
                'Groq API Key',
                settings.groqKey,
                (val) => notifier.setGroqKey(val),
                settings.activeProvider == AiProvider.groq,
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDA291C),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RETURN TO STUDIO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
   );
  }

  Widget _buildKeyGenerationButton(
    BuildContext context,
    String label,
    String url,
    Widget icon,
    Color accentColor,
  ) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Generate Key',
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderOption(
    BuildContext context,
    String label,
    AiProvider provider,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDA291C).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFDA291C) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernKeyInput(
    BuildContext context,
    String label,
    String initialValue,
    Function(String) onChanged,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.white70 : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: TextEditingController(text: initialValue)
            ..selection = TextSelection.fromPosition(TextPosition(offset: initialValue.length)),
          onChanged: onChanged,
          obscureText: true,
          style: TextStyle(color: isActive ? Colors.white : Colors.white24, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter API Key...',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            prefixIcon: Icon(Icons.vpn_key_outlined, size: 18, color: isActive ? const Color(0xFFDA291C) : Colors.white10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
