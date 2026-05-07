import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/denuncia.dart';
import '../services/api_service.dart';

class ReportProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Denuncia> _allDenuncias = [];
  List<Denuncia> _userDenuncias = [];
  List<Denuncia> _colaboradorDenuncias = [];
  bool _isLoading = false;

  List<Denuncia> get allDenuncias => _allDenuncias;
  List<Denuncia> get userDenuncias => _userDenuncias;
  List<Denuncia> get colaboradorDenuncias => _colaboradorDenuncias;
  bool get isLoading => _isLoading;

  Future<void> fetchAllDenuncias() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allDenuncias = await _apiService.getDenuncias();
    } catch (e) {
      print('Error fetching all denuncias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserDenuncias(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _userDenuncias = await _apiService.getUserDenuncias(userId);
    } catch (e) {
      print('Error fetching user denuncias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchColaboradorDenuncias(int colaboradorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _colaboradorDenuncias = await _apiService.getColaboradorDenuncias(colaboradorId);
    } catch (e) {
      print('Error fetching colaborador denuncias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Colaborador inicia o trabalho (Status 5 → 2).
  Future<void> iniciarDenuncia(int denunciaId, int colaboradorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.iniciarDenuncia(denunciaId);
      await fetchColaboradorDenuncias(colaboradorId);
    } catch (e) {
      print('Error iniciando denuncia: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Colaborador interrompe o trabalho (Status 2 → 5).
  Future<void> pararDenuncia(int denunciaId, int colaboradorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.pararDenuncia(denunciaId);
      await fetchColaboradorDenuncias(colaboradorId);
    } catch (e) {
      print('Error parando denuncia: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Colaborador pré-finaliza a denúncia (Status 2 → 3).
  /// Envia um relatório descrevendo o que foi feito.
  Future<void> preFinalizarDenuncia(int denunciaId, int colaboradorId, {required String relatorio, List<XFile>? fotos}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.preFinalizarDenuncia(denunciaId, relatorio: relatorio, fotos: fotos);
      await fetchColaboradorDenuncias(colaboradorId);
    } catch (e) {
      print('Error pre-finalizando denuncia: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh both to ensure consistency
  Future<void> refreshAll(int? userId) async {
    await fetchAllDenuncias();
    if (userId != null) {
      await fetchUserDenuncias(userId);
    }
  }
}
