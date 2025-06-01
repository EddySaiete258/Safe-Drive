import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  static late SharedPreferences _preferences;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();
  
}