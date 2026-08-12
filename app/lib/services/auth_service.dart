import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class AuthService {
  AuthService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const _tokenKey = 'jwt';
  static String? _cachedToken;
  static final _sessionExpiredController = StreamController<void>.broadcast();
  final FlutterSecureStorage _storage;
  final http.Client _client;

  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  static void notifySessionExpired() => _sessionExpiredController.add(null);

  static Map<String, String> get cachedHeaders => _cachedToken == null
      ? const {}
      : {'Authorization': 'Bearer $_cachedToken'};

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<Map<String, String>?> headers({bool json = false}) async {
    final token = await getToken();
    if (token == null) return null;
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> deleteToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${Constants.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': email.trim(), 'password': password},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await saveToken(data['access_token'] as String);
      return data;
    } catch (error) {
      debugPrint('Login error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${Constants.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;
    } catch (error) {
      debugPrint('Register error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final authHeaders = await headers();
    if (authHeaders == null) return null;
    try {
      final response = await _client
          .get(Uri.parse('${Constants.baseUrl}/auth/me'), headers: authHeaders)
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;
    } catch (error) {
      debugPrint('Get profile error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> values,
  ) async {
    final authHeaders = await headers(json: true);
    if (authHeaders == null) return null;
    try {
      final response = await _client.patch(
        Uri.parse('${Constants.baseUrl}/auth/me'),
        headers: authHeaders,
        body: jsonEncode(values),
      );
      return response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;
    } catch (error) {
      debugPrint('Update profile error: $error');
      return null;
    }
  }
}
