import 'package:flutter/material.dart';
import '../models/notificacao.dart';
import '../services/api_service.dart';

class NotificacaoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Notificacao> _notificacoes = [];
  int _naoLidasCount = 0;
  bool _isLoading = false;

  List<Notificacao> get notificacoes => _notificacoes;
  int get naoLidasCount => _naoLidasCount;
  bool get isLoading => _isLoading;

  /// Busca todas as notificações do usuário autenticado.
  Future<void> fetchNotificacoes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notificacoes = await _apiService.getNotificacoes();
      _naoLidasCount = _notificacoes.where((n) => !n.lida).length;
    } catch (e) {
      debugPrint('Erro ao buscar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca apenas a contagem de não lidas (para badge).
  Future<void> fetchNaoLidasCount() async {
    try {
      _naoLidasCount = await _apiService.contarNotificacoesNaoLidas();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao contar notificações: $e');
    }
  }

  /// Marca uma notificação como lida.
  Future<void> marcarComoLida(int notificacaoId) async {
    try {
      await _apiService.marcarNotificacaoLida(notificacaoId);
      final idx = _notificacoes.indexWhere((n) => n.id == notificacaoId);
      if (idx != -1) {
        // Recriar a notificação com lida = true
        final old = _notificacoes[idx];
        _notificacoes[idx] = Notificacao(
          id: old.id,
          idUser: old.idUser,
          idDenuncia: old.idDenuncia,
          titulo: old.titulo,
          mensagem: old.mensagem,
          lida: true,
          tipo: old.tipo,
          createdAt: old.createdAt,
          tituloDenuncia: old.tituloDenuncia,
        );
        _naoLidasCount = _notificacoes.where((n) => !n.lida).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }

  /// Marca todas como lidas.
  Future<void> marcarTodasComoLidas() async {
    try {
      await _apiService.marcarTodasNotificacoesLidas();
      _notificacoes = _notificacoes.map((n) => Notificacao(
        id: n.id,
        idUser: n.idUser,
        idDenuncia: n.idDenuncia,
        titulo: n.titulo,
        mensagem: n.mensagem,
        lida: true,
        tipo: n.tipo,
        createdAt: n.createdAt,
        tituloDenuncia: n.tituloDenuncia,
      )).toList();
      _naoLidasCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao marcar todas como lidas: $e');
    }
  }
}
