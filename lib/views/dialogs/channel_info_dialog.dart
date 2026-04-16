import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel_info_state.dart';

class ChannelInfoDialog extends ConsumerStatefulWidget {
  const ChannelInfoDialog({super.key});

  @override
  ConsumerState<ChannelInfoDialog> createState() => _ChannelInfoDialogState();
}

class _ChannelInfoDialogState extends ConsumerState<ChannelInfoDialog> {
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _introController;
  late TextEditingController _outroController;
  late String _selectedVoice;

  @override
  void initState() {
    super.initState();
    final info = ref.read(channelInfoProvider);
    _nameController = TextEditingController(text: info.name);
    _subjectController = TextEditingController(text: info.subject);
    _introController = TextEditingController(text: info.introHook);
    _outroController = TextEditingController(text: info.outroHook);
    _selectedVoice = info.voice;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _introController.dispose();
    _outroController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(channelInfoProvider.notifier).updateInfo(
      name: _nameController.text,
      subject: _subjectController.text,
      introHook: _introController.text,
      outroHook: _outroController.text,
      voice: _selectedVoice,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                   const Icon(Icons.branding_watermark_outlined, color: Color(0xFFDA291C), size: 28),
                  const SizedBox(width: 16),
                  Text(
                    'CHANNEL IDENTITY',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildField('Channel Name', _nameController, 'e.g., The Anfield Report'),
              const SizedBox(height: 20),
              _buildField('Target Subject (Team)', _subjectController, 'e.g., Liverpool FC players'),
              const SizedBox(height: 24),
              
              const Text('AI VOICE PERSONALITY', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVoice,
                    dropdownColor: Colors.black,
                    isExpanded: true,
                    items: availableVoices.map((v) => DropdownMenuItem(
                      value: v['id'],
                      child: Text(v['name']!, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVoice = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildField('Intro Hook', _introController, 'e.g., Welcome back to The Anfield Report!', maxLines: 2),
              const SizedBox(height: 20),
              _buildField('Outro Hook', _outroController, 'e.g., Up the Reds! Subscribe for more.', maxLines: 2),
              
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDA291C),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('SAVE CHANNEL INFO'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
