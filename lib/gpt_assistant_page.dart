import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';
import 'gpt_service.dart';
import 'intent_service.dart';
import 'log_service.dart';

class GPTAssistantPage extends StatefulWidget {
  const GPTAssistantPage({super.key});

  @override
  State<GPTAssistantPage> createState() => _GPTAssistantPageState();
}

class _GPTAssistantPageState extends State<GPTAssistantPage> {
  late final stt.SpeechToText _speech;
  late final FlutterTts _tts;
  late final GPTService _gpt;

  bool _sttReady = false;
  bool _isListening = false;

  String _output = "Tap and hold the mic to talk to Jack.";
  double _soundLevel = 0.0;
  final List<String> _chatLog = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _gpt = GPTService("open_ai_key");

    _boot();
  }

  Future<void> _boot() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    final v = await StorageService.loadTtsVoice();
    if (v != null) {
      await _tts.setVoice({"name": v['name']!, "locale": v['locale']!});
    }

    _sttReady = await _speech.initialize(
      onStatus: (s) => Log.i('Assistant STT status: $s'),
      onError: (e) => Log.e('Assistant STT error: $e'),
      debugLogging: false,
    );

    final history = await StorageService.loadChatLog();
    setState(() {
      _chatLog
        ..clear()
        ..addAll(history);
    });
    Log.i('Assistant boot complete. STT ready=$_sttReady history=${_chatLog.length} lines');
  }

  Future<void> _speak(String text) async {
    try { await _tts.stop(); } catch (_) {}
    Log.i('Assistant TTS: "${text.replaceAll('\n', ' ')}"');
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    if (!_sttReady || _isListening) return;
    setState(() => _isListening = true);
    Log.i('Assistant STT listen start');

    final c = Completer<void>();
    try { await _speech.cancel(); } catch (_) {}
    _speech.listen(
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        Log.i('Assistant STT final: "$text"');
        if (text.isEmpty) {
          await _speak("I didn’t hear anything.");
          _stopListening();
          return;
        }
        setState(() => _output = "You said: $text");
        _chatLog.add("🧑: $text");
        await StorageService.saveChatLog(_chatLog);

        await _handleText(text);
        c.complete();
      },
      listenMode: stt.ListenMode.dictation,
      localeId: "en_US",
      partialResults: false,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 2),
      onSoundLevelChange: (lvl) => _soundLevel = lvl,
    );

    await c.future;
    _stopListening();
  }

  void _stopListening() {
    try { _speech.stop(); } catch (_) {}
    _isListening = false;
    Log.i('Assistant STT stopped');
    setState(() {});
  }

  Future<void> _handleText(String input) async {
    Log.i('Assistant delegating to GPT: "$input"');
    final res = await _gpt.askGPT(input);

    if (res['action'] == 'chat') {
      final msg = (res['data']?['message'] ?? '').toString();
      if (msg.isNotEmpty) {
        await _speak(msg);
        _chatLog.add("🤖: $msg");
        await StorageService.saveChatLog(_chatLog);
        setState(() => _output = msg);
      }
      return;
    }

    final confirmation = await IntentService.applyIntent(res);
    await _speak(confirmation);
    _chatLog.add("🤖: $confirmation");
    await StorageService.saveChatLog(_chatLog);
    setState(() => _output = confirmation);
  }

  @override
  void dispose() {
    try { _speech.stop(); } catch (_) {}
    try { _speech.cancel(); } catch (_) {}
    try { _tts.stop(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final micColor = _isListening ? Colors.redAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(title: const Text("Jack – AI Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              _output,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Simple mic level bar
            Container(
              height: 8,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_soundLevel.clamp(0.0, 60.0)) / 60.0,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._chatLog.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            )),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPressStart: (_) => _startListening(),  // push-to-talk: hold
        onLongPressEnd: (_) => _stopListening(),
        child: FloatingActionButton(
          backgroundColor: micColor,
          onPressed: () async {
            // tap = single-shot toggle
            if (_isListening) {
              _stopListening();
            } else {
              await _startListening();
            }
          },
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.black),
        ),
      ),
    );
  }
}