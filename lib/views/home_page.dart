import 'package:flutter/material.dart';
import 'sections/header_section.dart';
import 'sections/input_section.dart';
import 'sections/process_section.dart';
import 'sections/voice_section.dart';
import 'sections/voice_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isShortScreen = MediaQuery.of(context).size.height < 800;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isShortScreen ? 16.0 : 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Side: Input
                    const Expanded(
                      flex: 2,
                      child: InputSection(),
                    ),
                    SizedBox(width: isShortScreen ? 16 : 24),
                    // Right Side: Process, Voice & Production
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const Expanded(
                            flex: 1,
                            child: ProcessSection(),
                          ),
                          SizedBox(height: isShortScreen ? 12 : 16),
                          const Expanded(
                            flex: 1,
                            child: VoiceSection(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
