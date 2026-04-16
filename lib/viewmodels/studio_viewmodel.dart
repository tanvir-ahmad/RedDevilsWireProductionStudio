import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_state.dart';
import '../models/settings_state.dart';
import '../models/channel_info_state.dart';
import '../views/dialogs/settings_dialog.dart';
import '../main.dart';

// Providers
final newsStoriesProvider = NotifierProvider<NewsStoriesNotifier, List<NewsStory>>(() {
  return NewsStoriesNotifier();
});

final studioStatusProvider = NotifierProvider<StudioStatusNotifier, StudioStatus>(() {
  return StudioStatusNotifier();
});

final finalScriptProvider = NotifierProvider<FinalScriptNotifier, String>(() {
  return FinalScriptNotifier();
});

final productionLogsProvider = NotifierProvider<LogsNotifier, List<ProductionLog>>(() {
  return LogsNotifier();
});

final optimizationProvider = NotifierProvider<OptimizationNotifier, OptimizationData>(() {
  return OptimizationNotifier();
});

final voiceoverReadyProvider = NotifierProvider<VoiceoverReadyNotifier, bool>(() {
  return VoiceoverReadyNotifier();
});

final voiceoverRateProvider = NotifierProvider<VoiceoverRateNotifier, double>(() {
  return VoiceoverRateNotifier();
});

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  return player;
});

final isAudioPlayingProvider = StreamProvider<PlayerState>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.onPlayerStateChanged;
});

class VoiceoverReadyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setReady(bool ready) => state = ready;
}

class VoiceoverRateNotifier extends Notifier<double> {
  @override
  double build() => 1.0; // Default 1.0x
  void setRate(double rate) => state = rate;
}

class OptimizationNotifier extends Notifier<OptimizationData> {
  @override
  OptimizationData build() => OptimizationData.empty();

  void setData(OptimizationData data) => state = data;
}

class StudioStatusNotifier extends Notifier<StudioStatus> {
  @override
  StudioStatus build() => StudioStatus.idle;

  void setStatus(StudioStatus status) => state = status;
}

class FinalScriptNotifier extends Notifier<String> {
  @override
  String build() => "";

  void setScript(String script) {
    if (script.trim().isEmpty) return; 
    state = script;
    // Reset voiceover when script changes
    ref.read(voiceoverReadyProvider.notifier).setReady(false);
  }

  void clear() {
    state = "";
    ref.read(voiceoverReadyProvider.notifier).setReady(false);
  }
}

class NewsStoriesNotifier extends Notifier<List<NewsStory>> {
  @override
  List<NewsStory> build() => [];

  void addStory(String title, String body) {
    if (title.trim().isNotEmpty && body.trim().isNotEmpty) {
      state = [...state, NewsStory(title: title, body: body)];
    }
  }

  void removeStory(int index) {
    if (index >= 0 && index < state.length) {
      final newList = List<NewsStory>.from(state);
      newList.removeAt(index);
      state = newList;
    }
  }

  void clearAll() {
    state = [];
  }
}

class LogsNotifier extends Notifier<List<ProductionLog>> {
  @override
  List<ProductionLog> build() => [];

  void addLog(String message) {
    state = [...state, ProductionLog(message)];
  }

  void clear() {
    state = [];
  }
}

// Logic ViewModel
class StudioViewModel {
  final WidgetRef ref;
  StudioViewModel(this.ref);

  Future<void> generateScript() async {
    final settings = ref.read(settingsProvider);
    if (!settings.isKeyPresent) {
      _showError("ACTION REQUIRED: Please provide an API key in Studio Settings first.");
      _openSettings();
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
      return;
    }

    ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.scripting);

    final stories = ref.read(newsStoriesProvider);
    if (stories.isEmpty) {
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
      return;
    }

    final activeKey = settings.activeProvider == AiProvider.gemini ? settings.geminiKey : settings.groqKey;
    final providerName = settings.activeProvider.name;

    final channelInfo = ref.read(channelInfoProvider);

    final mergedText = stories.map((s) => "Title: ${s.title}\nBody: ${s.body}").join("\n\n");
    
    try {
      // Save merged text to file to avoid CLI argument limits on Windows
      final inputFile = File('news_input.txt');
      await inputFile.writeAsString(mergedText);

      final process = await Process.run('python', [
        'reddevils_engine.py',
        '--file', 'news_input.txt',
        '--metadata-only',
        '--provider', providerName,
        '--api-key', activeKey,
        '--channel-name', channelInfo.name,
        '--subject', channelInfo.subject,
        '--intro-hook', channelInfo.introHook,
        '--outro-hook', channelInfo.outroHook,
      ]);
      
      if (process.exitCode == 0) {
        String output = process.stdout.toString().trim();
        const startTag = "---METADATA_START---";
        const endTag = "---METADATA_END---";
        
        if (output.contains(startTag) && output.contains(endTag)) {
          try {
            final jsonStr = output.split(startTag)[1].split(endTag)[0].trim();
            final decoded = jsonDecode(jsonStr);
            ref.read(finalScriptProvider.notifier).setScript(decoded['script']);
            ref.read(optimizationProvider.notifier).setData(OptimizationData.fromJson(decoded['seo']));
          } catch (e) {
            debugPrint("JSON Decode Error: $e");
            _showError("Data Error: Received malformed response from engine.");
          }
        } else {
          _showError("Data Error: Metadata markers not found in engine output.");
        }
      } else {
        final error = process.stderr.toString();
        debugPrint("Python Error: $error");
        
        if (error.contains("429") || error.contains("ResourceExhausted") || error.contains("rate_limit")) {
          ref.read(settingsProvider.notifier).setProviderStatus(settings.activeProvider, ProviderStatus.quotaExceeded);
        }

        _showError("Generation Failed: $error");
      }
    } catch (e) {
      debugPrint("Execution Exception: $e");
      _showError("Execution Error: $e");
    } finally {
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
    }
  }

  void _openSettings() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => const SettingsDialog(),
      );
    }
  }

  void _showError(String message) {
    // Only show the most relevant part of the error to avoid "Red Screen of Death" UI
    String cleanMessage = message;
    if (message.contains('ResourceExhausted')) {
      cleanMessage = "Quota Exceeded: Please wait a moment before trying again.";
    } else if (message.contains('NOT_FOUND')) {
      cleanMessage = "Model not found. Please check configuration.";
    } else {
      // Get the first couple of lines if it's a long traceback
      final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();
      cleanMessage = lines.isNotEmpty ? lines.last : message;
      if (cleanMessage.contains('details = ')) {
        cleanMessage = cleanMessage.split('details = ')[1].replaceAll('"', '');
      }
    }

    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(cleanMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFDA291C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> regenerateSEO() async {
    final script = ref.read(finalScriptProvider);
    if (script.isEmpty) return;

    final settings = ref.read(settingsProvider);
    if (!settings.isKeyPresent) {
      _showError("API key required to regenerate SEO.");
      _openSettings();
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
      return;
    }

    final activeKey = settings.activeProvider == AiProvider.gemini ? settings.geminiKey : settings.groqKey;
    final providerName = settings.activeProvider.name;

    ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.scripting);

    final channelInfo = ref.read(channelInfoProvider);

    try {
      final process = await Process.run('python', [
        'reddevils_engine.py',
        '--text', "Regenerating SEO...",
        '--script', script,
        '--metadata-only',
        '--provider', providerName,
        '--api-key', activeKey,
        '--channel-name', channelInfo.name,
      ]);
      
      if (process.exitCode == 0) {
        String output = process.stdout.toString().trim();
        const startTag = "---METADATA_START---";
        const endTag = "---METADATA_END---";
        
        if (output.contains(startTag) && output.contains(endTag)) {
          try {
            final jsonStr = output.split(startTag)[1].split(endTag)[0].trim();
            final decoded = jsonDecode(jsonStr);
            ref.read(optimizationProvider.notifier).setData(OptimizationData.fromJson(decoded['seo']));
          } catch (e) {
            debugPrint("JSON Decode Error: $e");
            _showError("Data Error: Received malformed response from engine.");
          }
        } else {
          _showError("Data Error: Metadata markers not found in engine output.");
        }
      } else {
        final error = process.stderr.toString();
        debugPrint("Regen Python Error: $error");
        _showError("Regen Failed: $error");
      }
    } catch (e) {
      debugPrint("Regen Execution Exception: $e");
      _showError("Execution Error: $e");
    } finally {
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
    }
  }

  Future<void> generateVoiceover() async {
    final script = ref.read(finalScriptProvider);
    if (script.trim().isEmpty) {
      debugPrint("REJECTED: Cannot generate voiceover with empty script.");
      return;
    }

    ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.voicing);
    final settings = ref.read(settingsProvider);
    final activeKey = settings.activeProvider == AiProvider.gemini ? settings.geminiKey : settings.groqKey;
    final providerName = settings.activeProvider.name;

    final multiplier = ref.read(voiceoverRateProvider);
    final percentage = ((multiplier - 1.0) * 100).round();
    final rateStr = "${percentage >= 0 ? '+' : ''}$percentage%";

    final channelInfo = ref.read(channelInfoProvider);

    try {
      final process = await Process.run('python', [
        'reddevils_engine.py',
        '--text', "Generating voiceover...",
        '--script', script,
        '--only-audio',
        '--rate', rateStr,
        '--provider', providerName,
        '--api-key', activeKey,
        '--voice', channelInfo.voice,
      ]);

      if (process.exitCode == 0) {
        ref.read(voiceoverReadyProvider.notifier).setReady(true);
      } else {
        debugPrint("Voiceover Python Error: ${process.stderr}");
      }
    } catch (e) {
      debugPrint("Voiceover Exception: $e");
    } finally {
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
    }
  }

  Future<void> exportVoiceover() async {
    final status = ref.read(studioStatusProvider);
    if (status != StudioStatus.idle) return;

    final channelInfo = ref.read(channelInfoProvider);
    final now = DateTime.now();
    final dateStr = "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
    final defaultFileName = "${channelInfo.name.replaceAll(' ', '_')}_$dateStr.mp3";

    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Voiceover Audio',
        fileName: defaultFileName,
        type: FileType.audio,
        lockParentWindow: true,
      );

      if (outputPath != null) {
        final sourceFile = File('audio.mp3');
        if (await sourceFile.exists()) {
          // Normalize extension if user forgot it
          if (!outputPath.toLowerCase().endsWith('.mp3')) {
            outputPath += '.mp3';
          }
          await sourceFile.copy(outputPath);
          
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Voiceover exported successfully! 🎙️✅'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError("Export Failed: Source audio file not found. Generate it first.");
        }
      }
    } catch (e) {
      debugPrint("Export Error: $e");
      _showError("Export Error: Could not save file.");
    }
  }

  Future<void> toggleVoiceover() async {
    final player = ref.read(audioPlayerProvider);
    try {
      if (player.state == PlayerState.playing) {
        await player.pause();
      } else {
        await player.play(DeviceFileSource('audio.mp3'));
      }
    } catch (e) {
      debugPrint("Playback Toggle Exception: $e");
    }
  }

  Future<void> stopVoiceover() async {
    final player = ref.read(audioPlayerProvider);
    try {
      await player.stop();
    } catch (e) {
      debugPrint("Stop Exception: $e");
    }
  }

  Future<void> bakeVideo() async {
    final logsNotifier = ref.read(productionLogsProvider.notifier);
    logsNotifier.clear();
    
    final script = ref.read(finalScriptProvider);
    if (script.isEmpty) return;

    // Guard: Voiceover must be ready
    if (!ref.read(voiceoverReadyProvider)) {
      logsNotifier.addLog("ERROR: Voiceover not ready. Please generate voiceover first.");
      return;
    }

    ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.baking);

    try {
      final settings = ref.read(settingsProvider);
      final activeKey = settings.activeProvider == AiProvider.gemini ? settings.geminiKey : settings.groqKey;
      final providerName = settings.activeProvider.name;

      final multiplier = ref.read(voiceoverRateProvider);
      final percentage = ((multiplier - 1.0) * 100).round();
      final rateStr = "${percentage >= 0 ? '+' : ''}$percentage%";
      
      final process = await Process.start('python', [
        'reddevils_engine.py',
        '--text', "Baking production video...", 
        '--script', script,
        '--rate', rateStr,
        '--provider', providerName,
        '--api-key', activeKey,
      ]);

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          logsNotifier.addLog(line.trim());
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          logsNotifier.addLog("ERR: ${line.trim()}");
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        logsNotifier.addLog("SUCCESS: Production Complete!");
      } else {
        logsNotifier.addLog("ERROR: Production failed (Code $exitCode)");
      }
    } catch (e) {
      logsNotifier.addLog("CRITICAL: $e");
    } finally {
      ref.read(studioStatusProvider.notifier).setStatus(StudioStatus.idle);
    }
  }
}
