import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/denuncia.dart';
import '../models/notificacao.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ─────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${Constants.apiUrl}/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final body = jsonDecode(response.body);
    
    if (response.statusCode == 200 && body['status'] == true) {
      return body;
    } else {
      // Extrair mensagem amigável do servidor
      final serverMsg = body['message'] ?? 'Erro ao realizar login.';
      throw Exception(serverMsg);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final url = Uri.parse('${Constants.apiUrl}/users');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 422) {
      final jsonResponse = jsonDecode(response.body);
      final errorsMap = jsonResponse['errors'] as Map<String, dynamic>;
      final errorMessages = errorsMap.values
          .map((e) => (e as List).join(', '))
          .join('\n');
      
      print('\n\n❌ ERRO DE CADASTRO (VALIDAÇÃO):');
      print(errorMessages);
      print('\n\n');
      
      throw Exception(errorMessages);
    } else {
      throw Exception('Failed to register: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> logout(int userId) async {
    final url = Uri.parse('${Constants.apiUrl}/logout/$userId');
    await http.post(url, headers: await _getHeaders());
  }

  // ── Denúncias ────────────────────────────────────

  Future<List<Denuncia>> getDenuncias() async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      final List<dynamic> data;
      if (responseData['denuncias'] is Map && responseData['denuncias']['data'] != null) {
        data = responseData['denuncias']['data'];
      } else if (responseData['denuncias'] is List) {
        data = responseData['denuncias'];
      } else {
        data = responseData['data'] ?? [];
      }

      return data.map((json) => Denuncia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load denuncias');
    }
  }

  Future<List<Denuncia>> getUserDenuncias(int userId) async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias?id_user=$userId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      final List<dynamic> data;
      if (responseData['denuncias'] is Map && responseData['denuncias']['data'] != null) {
        data = responseData['denuncias']['data'];
      } else {
        data = responseData['denuncias'] ?? [];
      }

      return data.map((json) => Denuncia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user denuncias');
    }
  }

  /// Busca denúncias atribuídas a um colaborador (status em andamento)
  Future<List<Denuncia>> getColaboradorDenuncias(int colaboradorId) async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias?id_colaborador=$colaboradorId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      final List<dynamic> data;
      if (responseData['denuncias'] is Map && responseData['denuncias']['data'] != null) {
        data = responseData['denuncias']['data'];
      } else {
        data = responseData['denuncias'] ?? [];
      }

      return data.map((json) => Denuncia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load colaborador denuncias');
    }
  }

  /// Colaborador inicia o trabalho (Status 5 → 2).
  Future<void> iniciarDenuncia(int denunciaId) async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias/$denunciaId/iniciar');
    final response = await http.post(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'Erro desconhecido';
      throw Exception('Falha ao iniciar: $msg');
    }
  }

  /// Colaborador interrompe o trabalho (Status 2 → 5).
  Future<void> pararDenuncia(int denunciaId) async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias/$denunciaId/parar');
    final response = await http.post(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'Erro desconhecido';
      throw Exception('Falha ao interromper: $msg');
    }
  }

  Future<Denuncia> createDenuncia(Map<String, dynamic> denunciaData) async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(denunciaData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Denuncia.fromJson(decoded['denuncia'] ?? decoded);
    } else if (response.statusCode == 422) {
      final jsonResponse = jsonDecode(response.body);
      final errorsMap = jsonResponse['errors'] as Map<String, dynamic>;
      final errorMessages = errorsMap.values
          .map((e) => (e as List).join('\n'))
          .join('\n');
      throw Exception(errorMessages);
    } else {
      throw Exception('Failed to create denuncia: ${response.body}');
    }
  }

  /// Colaborador pré-finaliza a denúncia (Status 2 → 3).
  Future<void> preFinalizarDenuncia(int denunciaId, {required String relatorio, List<XFile>? fotos}) async {
    final token = await _getToken();
    final url = Uri.parse('${Constants.apiUrl}/denuncias/$denunciaId/pre-finalizar');
    
    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..fields['relatorio'] = relatorio;

    if (fotos != null && fotos.isNotEmpty) {
      for (var foto in fotos) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'fotos[]', 
            await foto.readAsBytes(),
            filename: foto.name.isNotEmpty ? foto.name : 'foto.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'fotos[]', 
            foto.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      String msg = 'Erro desconhecido';
      try {
        final decoded = jsonDecode(respStr);
        msg = decoded['message'] ?? msg;
      } catch (e) {
        if (response.statusCode == 413) {
          msg = 'As fotos são muito grandes. Tente enviar fotos menores.';
        } else {
          msg = 'Erro no servidor (${response.statusCode}).';
        }
      }
      throw Exception('Falha ao pré-finalizar: $msg');
    }
  }

  // ── Fotos ────────────────────────────────────────

  Future<void> uploadFotoDenunciaXFile(int denunciaId, XFile imageFile) async {
    final token = await _getToken();
    final url = Uri.parse('${Constants.apiUrl}/fotos-denuncias');

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..fields['id_denuncia'] = denunciaId.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      await imageFile.readAsBytes(),
      filename: imageFile.name,
      contentType: MediaType('image', 'jpeg'),
    ));

    var response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image: ${response.statusCode} - $respStr');
    }
  }

  // ── Notificações ─────────────────────────────────

  /// Busca notificações do usuário autenticado.
  Future<List<Notificacao>> getNotificacoes() async {
    final url = Uri.parse('${Constants.apiUrl}/notificacoes');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> items;
      if (data['notificacoes'] is Map && data['notificacoes']['data'] != null) {
        items = data['notificacoes']['data'];
      } else if (data['notificacoes'] is List) {
        items = data['notificacoes'];
      } else {
        items = [];
      }

      return items.map((json) => Notificacao.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar notificações');
    }
  }

  /// Marca uma notificação como lida.
  Future<void> marcarNotificacaoLida(int notificacaoId) async {
    final url = Uri.parse('${Constants.apiUrl}/notificacoes/$notificacaoId/lida');
    final response = await http.put(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar notificação como lida');
    }
  }

  /// Marca todas as notificações como lidas.
  Future<void> marcarTodasNotificacoesLidas() async {
    final url = Uri.parse('${Constants.apiUrl}/notificacoes/marcar-todas-lidas');
    final response = await http.put(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar todas como lidas');
    }
  }

  /// Conta notificações não lidas.
  Future<int> contarNotificacoesNaoLidas() async {
    final url = Uri.parse('${Constants.apiUrl}/notificacoes/nao-lidas/count');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Falha ao contar notificações não lidas');
    }
  }
}
