import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/denuncia.dart';
import 'package:http_parser/http_parser.dart';

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

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${Constants.apiUrl}/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.statusCode} - ${response.body}');
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

  // Denuncias
  Future<List<Denuncia>> getDenuncias() async {
    final url = Uri.parse('${Constants.apiUrl}/denuncias');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Denuncia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load denuncias');
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
      return Denuncia.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create denuncia: ${response.body}');
    }
  }

  Future<void> uploadFotoDenuncia(int denunciaId, String imagePath) async {
    final token = await _getToken();
    final url = Uri.parse('${Constants.apiUrl}/fotos-denuncias');

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..fields['id_denuncia'] = denunciaId.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'caminho_foto',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ));

    var response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image: ${response.statusCode} - $respStr');
    }
  }
}
