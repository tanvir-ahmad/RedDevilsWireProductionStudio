import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelInfo {
  final String name;
  final String subject;
  final String introHook;
  final String outroHook;
  final String voice;

  ChannelInfo({
    required this.name,
    required this.subject,
    required this.introHook,
    required this.outroHook,
    required this.voice,
  });

  ChannelInfo copyWith({
    String? name,
    String? subject,
    String? introHook,
    String? outroHook,
    String? voice,
  }) {
    return ChannelInfo(
      name: name ?? this.name,
      subject: subject ?? this.subject,
      introHook: introHook ?? this.introHook,
      outroHook: outroHook ?? this.outroHook,
      voice: voice ?? this.voice,
    );
  }

  factory ChannelInfo.defaultInfo() {
    return ChannelInfo(
      name: "RedDevilsWire",
      subject: "Manchester United players",
      introHook: "Welcome back to RedDevilsWire!",
      outroHook: "Don't forget to like and subscribe for more United updates!",
      voice: "en-GB-RyanNeural",
    );
  }
}

class ChannelInfoNotifier extends Notifier<ChannelInfo> {
  @override
  ChannelInfo build() {
    _loadInfo();
    return ChannelInfo.defaultInfo();
  }

  Future<void> _loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    state = ChannelInfo(
      name: prefs.getString('channel_name') ?? "RedDevilsWire",
      subject: prefs.getString('channel_subject') ?? "Manchester United players",
      introHook: prefs.getString('channel_intro') ?? "Welcome back to RedDevilsWire!",
      outroHook: prefs.getString('channel_outro') ?? "Don't forget to like and subscribe for more United updates!",
      voice: prefs.getString('channel_voice') ?? "en-GB-RyanNeural",
    );
  }

  Future<void> updateInfo({
    String? name,
    String? subject,
    String? introHook,
    String? outroHook,
    String? voice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('channel_name', name);
    if (subject != null) await prefs.setString('channel_subject', subject);
    if (introHook != null) await prefs.setString('channel_intro', introHook);
    if (outroHook != null) await prefs.setString('channel_outro', outroHook);
    if (voice != null) await prefs.setString('channel_voice', voice);

    state = state.copyWith(
      name: name,
      subject: subject,
      introHook: introHook,
      outroHook: outroHook,
      voice: voice,
    );
  }
}

final channelInfoProvider = NotifierProvider<ChannelInfoNotifier, ChannelInfo>(() {
  return ChannelInfoNotifier();
});

const List<Map<String, String>> availableVoices = [
  {"name": "Ryan (UK - Male)", "id": "en-GB-RyanNeural"},
  {"name": "Sonia (UK - Female)", "id": "en-GB-SoniaNeural"},
  {"name": "Libby (UK - Female)", "id": "en-GB-LibbyNeural"},
  {"name": "Guy (US - Male)", "id": "en-US-GuyNeural"},
  {"name": "Aria (US - Female)", "id": "en-US-AriaNeural"},
  {"name": "Christopher (US - Male)", "id": "en-US-ChristopherNeural"},
  {"name": "Liam (Canada - Male)", "id": "en-CA-LiamNeural"},
  {"name": "Natasha (Australia - Female)", "id": "en-AU-NatashaNeural"},
];
