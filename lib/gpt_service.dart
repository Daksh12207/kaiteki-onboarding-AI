import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'log_service.dart';

class GPTService {
  final String apiKey;
  final String endpoint;

  GPTService(this.apiKey, {this.endpoint = "https://api.openai.com/v1/chat/completions"});

  final List<String> _chatLog = [];

  Future<Map<String, dynamic>> askGPT(String userInput) async {
    _chatLog.add("User: $userInput");
    Log.i('GPT ask -> "$userInput"');

    // Inject saved profile memory before every call
    final memory = await StorageService.getUserData() ?? {};
    final memoryContext = memory.isNotEmpty
        ? "Current saved user profile JSON (use and update when relevant): ${jsonEncode(memory)}"
        : "No saved user profile yet. If user provides details, respond with JSON to update.";

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    };

    final payload = {
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
          "You are an onboarding/profile assistant. "
              "Use provided profile memory to personalize and to make updates. "
              "If updating profile fields (name, phone, role, birthday, screenTime, content filters), "
              "return JSON ONLY: {\"action\":\"update<Field>\", \"data\":{...}}. "
              "Allowed actions: updateUsername{name}, updatePhoneNumber{phone}, updateRole{role}, "
              "updateBirthday{birthday}, updateScreenTime{screenTime}, updateContentFilter{filters}. "
              "For normal chat, reply in plain text.\n\n$memoryContext"
        },
        {"role": "user", "content": userInput}
      ],
      "temperature": 0.5,
      "max_tokens": 300
    };

    Log.i('HTTP POST $endpoint');
    Log.i('Request headers: ${Log.pp(headers)}');
    Log.i('Request body: ${Log.pp(payload)}');

    try {
      final resp = await http.post(Uri.parse(endpoint), headers: headers, body: jsonEncode(payload));
      Log.i('Response status: ${resp.statusCode}');
      // Log raw response (truncate to avoid spam)
      final raw = resp.body;
      Log.i('Response body (first 1000 chars): ${raw.substring(0, raw.length > 1000 ? 1000 : raw.length)}${raw.length > 1000 ? '…' : ''}');

      if (resp.statusCode != 200) {
        final error = "API error: ${resp.statusCode}";
        _chatLog.add("K: $error");
        await StorageService.saveChatLog(_chatLog);
        return {"action": "error", "data": {"message": error}};
      }

      final decoded = json.decode(raw);
      // Token usage logging (if present)
      try {
        final usage = decoded['usage'] ?? {};
        Log.i('Token usage: ${Log.pp(usage)}');
      } catch (_) {}

      final reply = decoded['choices'][0]['message']['content'] ?? "";
      Log.i('LLM reply: ${reply.substring(0, reply.length > 400 ? 400 : reply.length)}${reply.length > 400 ? '…' : ''}');

      _chatLog.add("K: $reply");
      await StorageService.saveLatestGPT(reply);
      await StorageService.saveChatLog(_chatLog);

      // Try parse as JSON intent; fallback to chat
      try {
        final obj = json.decode(reply);
        if (obj is Map<String, dynamic>) {
          Log.i('Parsed JSON intent: ${Log.pp(obj)}');
          return obj;
        }
      } catch (_) {
        Log.i('Reply is not JSON intent; treating as chat.');
      }
      return {"action": "chat", "data": {"message": reply}};
    } catch (e, st) {
      Log.e('GPT request failed', e, st);
      final error = "Request failed: $e";
      _chatLog.add("K: $error");
      await StorageService.saveChatLog(_chatLog);
      return {"action": "error", "data": {"message": error}};
    }
  }
}