import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthStatus status = AuthStatus.unknown;
  int? userId;
  String? token;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider(this._api, this._storage);

  // Called once at app start to restore a previous session from secure storage.
  Future<void> tryRestoreSession() async {
    final savedToken  = await _storage.read(key: 'auth_token');
    final savedUserId = await _storage.read(key: 'user_id');
    if (savedToken != null && savedUserId != null) {
      token  = savedToken;
      userId = int.tryParse(savedUserId);
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _authCall(() => _api.login(email, password));

  Future<bool> register(String email, String password) =>
      _authCall(() => _api.register(email, password));

  Future<void> logout() async {
    await _storage.deleteAll();
    token  = null;
    userId = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Shared logic for login and register: call the API, persist on success,
  // surface the error message on failure.
  Future<bool> _authCall(Future<Map<String, dynamic>> Function() call) async {
    isLoading     = true;
    errorMessage  = null;
    notifyListeners();

    try {
      final data = await call();
      await _persist(data['token'] as String, data['userId'] as int);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } on NetworkException {
      errorMessage = 'No network connection';
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> _persist(String t, int id) async {
    token  = t;
    userId = id;
    // Write both keys in parallel; neither depends on the other.
    await Future.wait([
      _storage.write(key: 'auth_token', value: t),
      _storage.write(key: 'user_id',    value: id.toString()),
    ]);
    status = AuthStatus.authenticated;
  }
}
