import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService with ChangeNotifier {
  static const String _userKey = 'current_user';
  Map<String, dynamic>? _currentUser;
  SharedPreferences? _prefs;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      _currentUser = Map<String, dynamic>.from(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      // Check if user already exists
      final usersJson = _prefs?.getStringList('users') ?? [];
      final users = usersJson.map((json) => Map<String, dynamic>.from(jsonDecode(json))).toList();
      
      if (users.any((user) => user['email'] == email)) {
        throw Exception('User already exists');
      }

      // Create new user
      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'password': password, // Note: In a real app, you should hash the password
      };

      // Save user to users list
      usersJson.add(jsonEncode(newUser));
      await _prefs?.setStringList('users', usersJson);

      // Set as current user
      _currentUser = newUser;
      await _prefs?.setString(_userKey, jsonEncode(newUser));
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final usersJson = _prefs?.getStringList('users') ?? [];
      final users = usersJson.map((json) => Map<String, dynamic>.from(jsonDecode(json))).toList();
      
      final user = users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );

      if (user.isEmpty) {
        throw Exception('Invalid email or password');
      }

      _currentUser = user;
      await _prefs?.setString(_userKey, jsonEncode(user));
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _prefs?.remove(_userKey);
    notifyListeners();
  }
} 