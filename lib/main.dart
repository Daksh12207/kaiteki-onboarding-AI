import 'package:flutter/material.dart';
import 'voice_onboarding.dart';// ✅ Adjust this based on actual location


void main() {
  runApp(const KaitekiApp());
}

class KaitekiApp extends StatelessWidget {
  const KaitekiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaiteki Onboarding',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: VoiceOnboardingPage(),
    );
  }
}