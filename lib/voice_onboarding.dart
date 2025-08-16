import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import 'gpt_service.dart';
import 'intent_service.dart';
import 'gpt_assistant_page.dart';
import 'log_service.dart';

class OnboardingData {
  final String name;
  final String phone;
  final String role;
  final String birthday;
  final String? screenTime;
  final String? contentFilter;

  OnboardingData({
    required this.name,
    required this.phone,
    required this.role,
    required this.birthday,
    this.screenTime,
    this.contentFilter,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'role': role,
    'birthday': birthday,
    if (screenTime != null) 'screenTime': screenTime,
    if (contentFilter != null) 'contentFilter': contentFilter,
  };
}

class VoiceOnboardingPage extends StatefulWidget {
  const VoiceOnboardingPage({super.key});

  @override
  State<VoiceOnboardingPage> createState() => _VoiceOnboardingPageState();
}

class _VoiceOnboardingPageState extends State<VoiceOnboardingPage> {
  bool _navigatedAway = false;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late GPTService gpt;

  bool _isListening = false;
  bool showStartOptions = true;
  bool voiceOnboardingStarted = false;
  bool introFinished = false;

  String _output = "Press Start to begin voice onboarding";

  int onboardingStep = 0;
  int retryCount = 0;
  bool onboardingDone = false;

  String userName = '';
  String userPhone = '';
  String userType = '';
  String userBirthday = '';
  String screenTime = '';
  String contentFilter = '';

  List<Map<String, String>> voiceOptions = [];
  String selectedVoice = '';

  final String kaitekiIntro =
      "Welcome to Kaiteki, your trusted digital guardian for families. "
      "I’ll guide you through a quick setup. Shall we move ahead, or would you like me to repeat?";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    // Replace for testing
    gpt = GPTService("open_ai_key");

    _tts.setCompletionHandler(() {
      Log.i('TTS completed. introFinished=$introFinished onboardingDone=$onboardingDone navigatedAway=$_navigatedAway');
      if (!onboardingDone && introFinished && mounted && !_navigatedAway) {
        _startListening();
      }
    });

    _restoreProgressAndVoice();
    _fetchAvailableVoices();
  }

  Future<void> _restoreProgressAndVoice() async {
    onboardingStep = await StorageService.loadOnboardingStep();

    final saved = await StorageService.getUserData() ?? {};
    userName = (saved['name'] ?? '').toString();
    userPhone = (saved['phone'] ?? '').toString();
    userType = (saved['role'] ?? '').toString();
    userBirthday = (saved['birthday'] ?? '').toString();
    screenTime = (saved['screenTime'] ?? '').toString();
    contentFilter = (saved['contentFilter'] ?? '').toString();

    final v = await StorageService.loadTtsVoice();
    if (v != null) {
      selectedVoice = v['name']!;
      await _tts.setVoice({"name": v['name']!, "locale": v['locale']!});
    }
    Log.i('Onboarding restored. step=$onboardingStep user=$userName role=$userType');
    setState(() {});
  }

  bool _shouldDelegateToGPT(String input) {
    final triggers = ["my", "i'm", "change", "actually", "update", "set"];
    return triggers.any((p) => input.startsWith(p));
  }

  Future<void> _fetchAvailableVoices() async {
    final List<dynamic> voices = await _tts.getVoices;
    final filtered = voices
        .where((v) =>
    v is Map &&
        v.containsKey('name') &&
        v.containsKey('locale') &&
        (v['locale'] as String).startsWith('en'))
        .map<Map<String, String>>((v) => {
      'name': v['name'] as String,
      'voice': v['name'] as String,
      'locale': v['locale'] as String,
    })
        .toList();
    voiceOptions = filtered;
    Log.i('Fetched ${voiceOptions.length} TTS voices (en-*)');
    setState(() {});
  }

  Future<bool> _checkMicPermission() async {
    var status = await Permission.microphone.status;
    Log.i('Mic permission status: $status');
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      Log.i('Mic permission after request: $status');
    }
    return status.isGranted;
  }

  Future<void> _startVoiceOnboarding() async {
    final micOk = await _checkMicPermission();
    if (!micOk) {
      _output = "Microphone permission denied.";
      setState(() {});
      return;
    }

    onboardingStep = onboardingStep == 0 ? 1 : onboardingStep; // resume or start
    retryCount = 0;
    onboardingDone = false;
    introFinished = false;
    _output = "Voice onboarding starting...";
    showStartOptions = false;
    voiceOnboardingStarted = true;

    await StorageService.saveOnboardingStep(onboardingStep);
    Log.i('Starting onboarding. step=$onboardingStep');
    await _speak(kaitekiIntro);
    introFinished = true;
    setState(() {});
  }

  Future<void> _setSelectedVoice(String name, String locale) async {
    await _tts.setVoice({"name": name, "locale": locale});
    await StorageService.saveTtsVoice(name, locale);
    Log.i('Voice selected: $name ($locale)');
  }

  Future<void> _speak(String text) async {
    Log.i('TTS speak: "${text.replaceAll('\n', ' ')}"');
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  void _showVoiceChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Choose Your Voice"),
          content: voiceOptions.isEmpty
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: voiceOptions.length,
              itemBuilder: (_, index) {
                final voice = voiceOptions[index];
                return ListTile(
                  title: Text(voice['name']!),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await _setSelectedVoice(voice['voice']!, voice['locale']!);
                      await _tts.speak("Welcome to Kaiteki");
                    },
                    child: const Text("Preview"),
                  ),
                  onTap: () async {
                    selectedVoice = voice['voice']!;
                    await _setSelectedVoice(voice['voice']!, voice['locale']!);
                    Navigator.pop(context);
                    await _startVoiceOnboarding();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _startListening() async {
    Log.i('STT initialize & listen (step=$onboardingStep)');
    final available = await _speech.initialize(
      onStatus: (s) => Log.i('STT status: $s'),
      onError: (e) => Log.e('STT error: ${e.errorMsg}'),
    );

    if (available && !onboardingDone && !_navigatedAway) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final text = result.recognizedWords.toLowerCase().trim();
            Log.i('STT final result: "$text"');
            retryCount = 0;
            _handleVoiceInput(text);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: "en_US",
        partialResults: false,
      );
    } else {
      Log.i('STT not available or onboardingDone/navigatedAway.');
    }
  }

  void _stopListening() {
    try { _speech.stop(); } catch (_) {}
    _isListening = false;
    Log.i('STT stopped (step=$onboardingStep)');
    setState(() {});
  }

  Future<void> _delegateToGPT(String input) async {
    Log.i('Delegating to GPT: "$input"');
    final res = await gpt.askGPT(input);
    if (res['action'] == 'chat') {
      final msg = (res['data']?['message'] ?? '').toString();
      if (msg.isNotEmpty) await _speak(msg);
      return;
    }
    final confirmation = await IntentService.applyIntent(res);
    await _speak(confirmation);
  }

  Future<void> _saveProfileSnapshot() async {
    final data = {
      'name': userName,
      'phone': userPhone,
      'role': userType,
      'birthday': userBirthday,
      'screenTime': screenTime,
      'contentFilter': contentFilter,
    };
    Log.i('Saving profile snapshot:\n${Log.pp(data)}');
    await StorageService.saveUserData(data);
  }

  Future<void> _handleVoiceInput(String input) async {
    if (_shouldDelegateToGPT(input)) {
      await _delegateToGPT(input);
      return;
    }

    switch (onboardingStep) {
      case 1:
        if (input.contains("yes")) {
          await _speak("Great! What is your name?");
          onboardingStep = 2;
        } else if (input.contains("repeat")) {
          await _speak(kaitekiIntro);
        } else {
          retryCount++; await _speak("Please say yes to proceed or repeat to hear it again.");
        }
        break;

      case 2:
        userName = input;
        _output = "Name: $userName";
        await _speak("Thanks $userName. What is your phone number?");
        onboardingStep = 3;
        break;

      case 3:
        final phoneDigits = input.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.length >= 7) { // relaxed for testing
          userPhone = phoneDigits;
          _output = "Phone: $userPhone";
          await _speak("Are you a parent or a child?");
          onboardingStep = 4;
          retryCount = 0;
        } else {
          retryCount++;
          if (retryCount >= 3) {
            await _speak("Let's try this later.");
            onboardingDone = true; _stopListening();
          } else {
            await _speak("That doesn't sound like a valid phone number. Please say it again.");
          }
        }
        break;

      case 4:
        if (input.contains("child")) {
          userType = "child";
          _output = "User Type: Child";
          await _speak("What is your birthday?");
          onboardingStep = 10;
        } else if (input.contains("parent")) {
          userType = "parent";
          _output = "User Type: Parent";
          await _speak("What is your birthday?");
          onboardingStep = 20;
        } else {
          retryCount++; await _speak("Please say parent or child.");
        }
        break;

    // Child flow
      case 10:
        userBirthday = input;
        onboardingDone = true;
        _stopListening();
        await _saveProfileSnapshot();
        _output =
        "Name: $userName\nBirthday: $userBirthday\nPlease ask your parent to complete setup if not already done.";
        await StorageService.clearOnboardingStep();
        _navigatedAway = true;
        Log.i('Onboarding complete (child). Navigating to assistant.');
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GPTAssistantPage()));
        break;

    // Parent flow
      case 20:
        userBirthday = input;
        await _speak("How many hours of screen time should we allow per day?");
        onboardingStep = 21;
        break;

      case 21:
        screenTime = input;
        await _speak("Which types of content would you like to block? For example: nudity, violence, gambling.");
        onboardingStep = 22;
        break;

      case 22:
        contentFilter = input;
        onboardingDone = true;
        _stopListening();
        await _saveProfileSnapshot();
        _output =
        "Setup complete.\nName: $userName\nPhone: $userPhone\nBirthday: $userBirthday\nScreen Time: $screenTime\nBlocked Content: $contentFilter";
        await _speak("Setup complete. Thank you $userName! Enjoy Kaiteki.");
        await StorageService.clearOnboardingStep();
        _navigatedAway = true;
        Log.i('Onboarding complete (parent). Navigating to assistant.');
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GPTAssistantPage()));
        break;
    }

    await StorageService.saveOnboardingStep(onboardingStep);
    Log.i('Onboarding step advanced to $onboardingStep');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: showStartOptions
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "WELCOME TO KAITEKI",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                "Would you like to have a voice-based experience?",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showVoiceChoiceDialog(context),
                child: const Text("Yes"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showStartOptions = false;
                    voiceOnboardingStarted = false;
                    _output = "You’ve chosen not to continue with voice onboarding.";
                  });
                  Log.i('User chose not to use voice onboarding.');
                },
                child: const Text("No"),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "WELCOME TO KAITEKI",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              if (voiceOnboardingStarted)
                Text(
                  _output,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}