import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { gemini, groq }

enum ProviderStatus { idle, ready, quotaExceeded, missingKey, error }

class SettingsData {
  final AiProvider activeProvider;
  final String geminiKey;
  final String groqKey;
  final Map<AiProvider, ProviderStatus> providerStatuses;

  SettingsData({
    required this.activeProvider,
    required this.geminiKey,
    required this.groqKey,
    required this.providerStatuses,
  });

  SettingsData copyWith({
    AiProvider? activeProvider,
    String? geminiKey,
    String? groqKey,
    Map<AiProvider, ProviderStatus>? providerStatuses,
  }) {
    return SettingsData(
      activeProvider: activeProvider ?? this.activeProvider,
      geminiKey: geminiKey ?? this.geminiKey,
      groqKey: groqKey ?? this.groqKey,
      providerStatuses: providerStatuses ?? this.providerStatuses,
    );
  }

  bool get isKeyPresent {
    if (activeProvider == AiProvider.gemini) return geminiKey.isNotEmpty;
    if (activeProvider == AiProvider.groq) return groqKey.isNotEmpty;
    return false;
  }
}

class SettingsNotifier extends Notifier<SettingsData> {
  @override
  SettingsData build() {
    // Initial state
    final initialData = SettingsData(
      activeProvider: AiProvider.gemini,
      geminiKey: "",
      groqKey: "",
      providerStatuses: {
        AiProvider.gemini: ProviderStatus.idle,
        AiProvider.groq: ProviderStatus.idle,
      },
    );
    
    // Load persisted settings
    _loadSettings();
    
    return initialData;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerIndex = prefs.getInt('activeProvider') ?? 0;
    final geminiKey = prefs.getString('geminiKey') ?? "";
    final groqKey = prefs.getString('groqKey') ?? "";

    state = state.copyWith(
      activeProvider: AiProvider.values[providerIndex],
      geminiKey: geminiKey,
      groqKey: groqKey,
      providerStatuses: {
        AiProvider.gemini: geminiKey.isNotEmpty ? ProviderStatus.ready : ProviderStatus.missingKey,
        AiProvider.groq: groqKey.isNotEmpty ? ProviderStatus.ready : ProviderStatus.missingKey,
      },
    );
  }

  Future<void> setProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeProvider', provider.index);
    state = state.copyWith(activeProvider: provider);
  }

  Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiKey', key);
    state = state.copyWith(
      geminiKey: key,
      providerStatuses: {
        ...state.providerStatuses,
        AiProvider.gemini: key.isNotEmpty ? ProviderStatus.ready : ProviderStatus.missingKey,
      },
    );
  }

  Future<void> setGroqKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groqKey', key);
    state = state.copyWith(
      groqKey: key,
      providerStatuses: {
        ...state.providerStatuses,
        AiProvider.groq: key.isNotEmpty ? ProviderStatus.ready : ProviderStatus.missingKey,
      },
    );
  }

  void setProviderStatus(AiProvider provider, ProviderStatus status) {
    state = state.copyWith(
      providerStatuses: {
        ...state.providerStatuses,
        provider: status,
      },
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsData>(() {
  return SettingsNotifier();
});
