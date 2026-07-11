import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Gives every install a stable anonymous ID (UUID v4, stored in
/// SharedPreferences) without requiring any login.  The ID is used for
/// local personalisation (e.g. keying recents/liked to this device) and
/// can be shown in Settings as a "Your ID" if you add cloud sync later.
class UserProvider extends ChangeNotifier {
  static const _key = 'beatverse:uid:v1';
  static const _uuid = Uuid();

  String _uid = '';
  String get uid => _uid;

  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_key, id);
    }
    _uid = id;
    _ready = true;
    notifyListeners();
  }

  /// Short 8-char prefix shown in the UI (e.g. "BV-A3F7C2B1").
  String get displayId => 'BV-${_uid.replaceAll('-', '').substring(0, 8).toUpperCase()}';
}
