import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        _token = null;
        await prefs.remove('token');
      }
    } else if (_token != null) {
      // Se tiver token mas não tiver user salvo (versão antiga do cache), desloga forçado.
      _token = null;
      await prefs.remove('token');
    }
    
    notifyListeners();
  }

  /// Retorna null se login OK, ou uma mensagem de erro se falhar.
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      if (response['access_token'] == null) {
          throw Exception('Token ausente na resposta');
      }
      
      if (response['user'] != null) {
        try {
          _user = User.fromJson(response['user']);
        } catch (e) {
          print('!!! ERRO AO PARSEAR USUARIO DA API: $e !!!');
          print('Dados recebidos da API: ${response['user']}');
          throw Exception('Erro ao processar dados do usuário: $e');
        }
      } else {
        print('!!! API RETORNOU USUARIO NULO !!!');
        throw Exception('Dados do usuário ausentes na resposta');
      }

      // Se passou pelas validações, definimos o token com segurança
      _token = response['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(response['user']));
      
      _isLoading = false;
      notifyListeners();
      return null; // sucesso
    } catch (e) {
      print('Login error: $e');
      _token = null;
      _user = null;
      _isLoading = false;
      notifyListeners();
      // Extrair mensagem limpa (remover "Exception: " do inicio)
      String msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      try {
        await _apiService.logout(_user!.id);
      } catch (e) {
        // Ignore logout errors
      }
    }
    
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
