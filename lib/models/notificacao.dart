/// Model de notificação para o cidadão.
class Notificacao {
  final int id;
  final int idUser;
  final int idDenuncia;
  final String titulo;
  final String mensagem;
  final bool lida;
  final String tipo; // 'cancelamento', 'finalizado', 'atualizacao'
  final String createdAt;
  final String? tituloDenuncia;

  Notificacao({
    required this.id,
    required this.idUser,
    required this.idDenuncia,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.tipo,
    required this.createdAt,
    this.tituloDenuncia,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'] ?? 0,
      idUser: json['id_user'] ?? 0,
      idDenuncia: json['id_denuncia'] ?? 0,
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      lida: json['lida'] == true || json['lida'] == 1,
      tipo: json['tipo'] ?? 'atualizacao',
      createdAt: json['created_at'] ?? '',
      tituloDenuncia: json['denuncia']?['titulo_denuncia'],
    );
  }
}
