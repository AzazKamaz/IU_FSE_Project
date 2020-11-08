import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';

class OauthModel extends ChangeNotifier {
  OauthModel() : super() {
    load();
  }

  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  TokenResponse _token;

  TokenResponse get token => _token;

  Map<String, dynamic> get user {
    if (_token?.accessToken == null) return null;

    final parts = _token.accessToken.split(r'.');

    if (parts.length != 3) return null;

    return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
  }

  Future<Map<String, dynamic>> get userDetails async {
    if (_token?.accessToken == null) return null;

    final response = await http.get(
      'https://graph.microsoft.com/v1.0/me/',
      headers: {'Authorization': 'Bearer ${_token.accessToken}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user details');
    }
  }

  Future<void> load() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return;

    final TokenResponse token = await _appAuth
        .token(
          TokenRequest(
            'f55fe8fe-74c4-45d6-bccc-e29aba32b102',
            'university.innopolis.attendance://innopolis.university/',
            serviceConfiguration: AuthorizationServiceConfiguration(
              'https://login.microsoftonline.com/8b33a0fd-354e-48f9-b6fa-b85f0b6e3e55/oauth2/v2.0/authorize',
              'https://login.microsoftonline.com/8b33a0fd-354e-48f9-b6fa-b85f0b6e3e55/oauth2/v2.0/token',
            ),
            refreshToken: refreshToken,
          ),
        )
        .catchError((error) => null);


    if (token == null) {
      _token = null;
      await _secureStorage.delete(key: 'refresh_token');
    } else {
      _token = token;
      await _secureStorage.write(
          key: 'refresh_token', value: token.refreshToken);
    }
    notifyListeners();
  }

  Future<void> login() async {
    final TokenResponse token = await _appAuth
        .authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            'f55fe8fe-74c4-45d6-bccc-e29aba32b102',
            'university.innopolis.attendance://innopolis.university/',
            serviceConfiguration: AuthorizationServiceConfiguration(
              'https://login.microsoftonline.com/8b33a0fd-354e-48f9-b6fa-b85f0b6e3e55/oauth2/v2.0/authorize',
              'https://login.microsoftonline.com/8b33a0fd-354e-48f9-b6fa-b85f0b6e3e55/oauth2/v2.0/token',
            ),
            scopes: ['email', 'openid', 'profile', 'User.Read', 'offline_access'],
            promptValues: ['login'],
          ),
        )
        .catchError((error) => null);

    if (token == null) {
      _token = null;
      await _secureStorage.delete(key: 'refresh_token');
    } else {
      _token = token;
      await _secureStorage.write(
          key: 'refresh_token', value: token.refreshToken);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    await _secureStorage.delete(key: 'refresh_token');
    notifyListeners();
  }
}
