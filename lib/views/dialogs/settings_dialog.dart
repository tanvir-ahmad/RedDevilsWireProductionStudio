import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/settings_state.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.gear, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'STUDIO SETTINGS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            
            // Provider Selection
            const Text(
              'AI PROVIDER',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildProviderChip(
                  context,
                  'Google Gemini',
                  AiProvider.gemini,
                  settings.activeProvider == AiProvider.gemini,
                  () => notifier.setProvider(AiProvider.gemini),
                  settings.providerStatuses[AiProvider.gemini]!,
                ),
                const SizedBox(width: 12),
                _buildProviderChip(
                  context,
                  'Groq (Llama 3.3)',
                  AiProvider.groq,
                  settings.activeProvider == AiProvider.groq,
                  () => notifier.setProvider(AiProvider.groq),
                  settings.providerStatuses[AiProvider.groq]!,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // API Key Inputs
            _buildKeyInput(
              context,
              'Gemini API Key',
              settings.geminiKey,
              'https://aistudio.google.com/app/apikey',
              (val) => notifier.setGeminiKey(val),
              settings.activeProvider == AiProvider.gemini,
            ),
            
            const SizedBox(height: 16),
            
            _buildKeyInput(
              context,
              'Groq API Key',
              settings.groqKey,
              'https://console.groq.com/keys',
              (val) => notifier.setGroqKey(val),
              settings.activeProvider == AiProvider.groq,
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text('SAVE & CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderChip(
    BuildContext context,
    String label,
    AiProvider provider,
    bool isSelected,
    VoidCallback onTap,
    ProviderStatus status,
  ) {
    Color statusColor = Colors.grey;
    String statusText = "Ready";
    
    switch (status) {
      case ProviderStatus.ready:
        statusColor = Colors.green;
        break;
      case ProviderStatus.quotaExceeded:
        statusColor = Colors.orange;
        statusText = "Quota Hit";
        break;
      case ProviderStatus.missingKey:
        statusColor = Colors.red;
        statusText = "No Key";
        break;
      case ProviderStatus.error:
        statusColor = Colors.red;
        statusText = "Error";
        break;
      default:
        break;
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyInput(
    BuildContext context,
    String label,
    String initialValue,
    String url,
    Function(String) onChanged,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(url)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Theme.of(context).primaryColor.withValues(alpha: isActive ? 1 : 0.2),
              ),
              child: const Text('GET KEY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initialValue)
            ..selection = TextSelection.fromPosition(TextPosition(offset: initialValue.length)),
          onChanged: onChanged,
          obscureText: true,
          enabled: true,
          style: TextStyle(color: isActive ? Colors.white : Colors.white24),
          decoration: InputDecoration(
            hintText: 'Paste your API key here...',
            prefixIcon: Icon(Icons.vpn_key, size: 18, color: isActive ? Colors.white38 : Colors.white10),
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
      ],
    );
  }
}
