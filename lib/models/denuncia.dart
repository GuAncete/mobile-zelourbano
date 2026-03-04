class Denuncia {
  final int id;
  final String data;
  final String titulo;
  final String tipo;
  final String descricao;
  final String status;
  final double latitude;
  final double longitude;
  final int idUser;
  // TODO: we can add fotos or user relationships later if returned by API

  Denuncia({
    required this.id,
    required this.data,
    required this.titulo,
    required this.tipo,
    required this.descricao,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.idUser,
  });

  factory Denuncia.fromJson(Map<String, dynamic> json) {
    return Denuncia(
      id: json['id_denuncia'] ?? 0,
      data: json['data_denuncia'] ?? '',
      titulo: json['titulo_denuncia'] ?? '',
      tipo: json['tipo_denuncia'] ?? '',
      descricao: json['descricao_denuncia'] ?? '',
      status: json['status_denuncia'] ?? 'pendente',
      latitude: double.tryParse(json['latitude_denuncia']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude_denuncia']?.toString() ?? '0') ?? 0.0,
      idUser: json['id_user'] ?? 0,
    );
  }
}
