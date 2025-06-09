import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  static late SharedPreferences _preferences;
  static String uuid = "user_id";

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future storeUserId(String userID) async {
    await _preferences.setString(uuid, userID);
  }

  static String? getUserId() {
    return _preferences.getString(uuid);
  }
}
