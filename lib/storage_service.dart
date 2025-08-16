import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'log_service.dart';

class StorageService {
  static const _s = FlutterSecureStorage();

  // -------- Profile (encrypted JSON) --------
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    await _s.write(key: 'user_data', value: jsonEncode(data));
    Log.i('Saved user_data to secure storage:\n${Log.pp(data)}');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final v = await _s.read(key: 'user_data');
    if (v == null) {
      Log.i('No user_data found in secure storage.');
      return null;
    }
    final map = Map<String, dynamic>.from(jsonDecode(v));
    Log.i('Loaded user_data from secure storage:\n${Log.pp(map)}');
    return map;
  }

  static Future<void> clearUserData() async {
    await _s.delete(key: 'user_data');
    Log.i('Cleared user_data from secure storage.');
  }

  // -------- Chat Log (encrypted JSON list) --------
  static Future<void> saveChatLog(List<String> chatLog) async {
    await _s.write(key: 'chatLog', value: jsonEncode(chatLog));
    Log.i('Saved chatLog (${chatLog.length} lines).');
  }

  static Future<List<String>> loadChatLog() async {
    final v = await _s.read(key: 'chatLog');
    if (v == null) {
      Log.i('No chatLog found in secure storage.');
      return <String>[];
    }
    final list = List<String>.from(jsonDecode(v));
    Log.i('Loaded chatLog (${list.length} lines).');
    return list;
  }

  // -------- Latest GPT --------
  static Future<void> saveLatestGPT(String reply) async {
    await _s.write(key: 'lastGptResponse', value: reply);
    Log.i('Saved lastGptResponse: ${reply.substring(0, reply.length > 200 ? 200 : reply.length)}${reply.length > 200 ? '…' : ''}');
  }

  static Future<String?> loadLatestGPT() async {
    final v = await _s.read(key: 'lastGptResponse');
    Log.i('Loaded lastGptResponse: ${v == null ? '(none)' : v.substring(0, v.length > 200 ? 200 : v.length)}${v != null && v.length > 200 ? '…' : ''}');
    return v;
  }

  // -------- Onboarding progress --------
  static Future<void> saveOnboardingStep(int step) async {
    await _s.write(key: 'onboarding_step', value: step.toString());
    Log.i('Saved onboarding_step: $step');
  }

  static Future<int> loadOnboardingStep() async {
    final v = await _s.read(key: 'onboarding_step');
    final step = v == null ? 0 : (int.tryParse(v) ?? 0);
    Log.i('Loaded onboarding_step: $step');
    return step;
  }

  static Future<void> clearOnboardingStep() async {
    await _s.delete(key: 'onboarding_step');
    Log.i('Cleared onboarding_step.');
  }

  // -------- TTS Voice preference --------
  static Future<void> saveTtsVoice(String voiceName, String locale) async {
    await _s.write(
      key: 'tts_voice',
      value: jsonEncode({'name': voiceName, 'locale': locale}),
    );
    Log.i('Saved tts_voice: name=$voiceName, locale=$locale');
  }

  static Future<Map<String, String>?> loadTtsVoice() async {
    final v = await _s.read(key: 'tts_voice');
    if (v == null) {
      Log.i('No tts_voice saved.');
      return null;
    }
    final m = Map<String, dynamic>.from(jsonDecode(v));
    final out = {'name': m['name'] as String, 'locale': m['locale'] as String};
    Log.i('Loaded tts_voice: ${Log.pp(out)}');
    return out;
  }
}