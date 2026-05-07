import 'package:flutter/material.dart';

/// Status fixos das denúncias no sistema Zelo Urbano.
///
/// 0 = Cancelado | 1 = Pendente | 5 = Atribuído | 2 = Em Andamento | 3 = Aguardando Revisão | 4 = Finalizado
class StatusDenuncia {
  final int id;
  final String nome;
  final Color cor;
  final String corHex;

  const StatusDenuncia._({
    required this.id,
    required this.nome,
    required this.cor,
    required this.corHex,
  });

  static const cancelado = StatusDenuncia._(id: 0, nome: 'Cancelado', cor: Color(0xFF6B7280), corHex: '#6b7280');
  static const pendente = StatusDenuncia._(id: 1, nome: 'Pendente', cor: Color(0xFFEF4444), corHex: '#ef4444');
  static const atribuido = StatusDenuncia._(id: 5, nome: 'Atribuído', cor: Color(0xFF8B5CF6), corHex: '#8b5cf6');
  static const emAndamento = StatusDenuncia._(id: 2, nome: 'Em Andamento', cor: Color(0xFFF59E0B), corHex: '#f59e0b');
  static const aguardandoRevisao = StatusDenuncia._(id: 3, nome: 'Aguardando Revisão', cor: Color(0xFF3B82F6), corHex: '#3b82f6');
  static const finalizado = StatusDenuncia._(id: 4, nome: 'Finalizado', cor: Color(0xFF10B981), corHex: '#10b981');

  static const List<StatusDenuncia> todos = [
    cancelado,
    pendente,
    atribuido,
    emAndamento,
    aguardandoRevisao,
    finalizado,
  ];

  /// Busca um status pelo ID numérico (string ou int).
  static StatusDenuncia getById(dynamic statusId) {
    final id = int.tryParse(statusId.toString()) ?? 1;
    return todos.firstWhere(
      (s) => s.id == id,
      orElse: () => pendente,
    );
  }

  /// Retorna a cor de um status pelo ID.
  static Color getColor(String statusId) => getById(statusId).cor;

  /// Retorna o nome de um status pelo ID.
  static String getNome(String statusId) => getById(statusId).nome;
}
