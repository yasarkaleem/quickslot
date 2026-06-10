import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  static const List<String> allUsers = ['u1', 'u2', 'u3'];

  String _selectedUserId = allUsers.first;
  String get selectedUserId => _selectedUserId;

  void selectUser(String userId) {
    if (_selectedUserId == userId) return;
    _selectedUserId = userId;
    notifyListeners();
  }
}
