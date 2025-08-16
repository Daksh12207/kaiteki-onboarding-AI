import 'storage_service.dart';
import 'log_service.dart';

class IntentService {
  static Future<String> applyIntent(Map<String, dynamic> gptResponse) async {
    final String? action = gptResponse['action'];
    final Map<String, dynamic>? data = gptResponse['data'] is Map
        ? Map<String, dynamic>.from(gptResponse['data'])
        : null;

    Log.i('Applying intent: action=$action data=${Log.pp(data)}');

    if (action == null || data == null) {
      return "I received something but I’m not sure how to update it.";
    }

    final current = await StorageService.getUserData() ?? <String, dynamic>{};

    switch (action) {
      case 'updateUsername':
        current['name'] = data['name'];
        await StorageService.saveUserData(current);
        return "Updated your name to ${data['name']}.";
      case 'updatePhoneNumber':
        current['phone'] = data['phone'];
        await StorageService.saveUserData(current);
        return "Updated your phone number.";
      case 'updateBirthday':
        current['birthday'] = data['birthday'];
        await StorageService.saveUserData(current);
        return "Birthday updated.";
      case 'updateRole':
        current['role'] = data['role'];
        await StorageService.saveUserData(current);
        return "Updated your role to ${data['role']}.";
      case 'updateScreenTime':
        current['screenTime'] = data['screenTime'];
        await StorageService.saveUserData(current);
        return "Screen time updated.";
      case 'updateContentFilter':
        current['contentFilter'] = data['filters'];
        await StorageService.saveUserData(current);
        return "Content filters updated.";
      default:
        return "I received something but I’m not sure how to update it.";
    }
  }
}