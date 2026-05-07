import 'prioridade.dart';

class Denuncia {
  final int id;
  final String titulo;
  final String tipo; // Alterado para String para compatibilidade com TypeHelper
  final String descricao;
  final double latitude;
  final double longitude;
  final String status;
  final String data;
  final List<String> imagens;
  final List<String> fotosCidadao;
  final List<String> fotosColaborador;
  final String descricaoAdmin;
  final String justificativaCancelamento;
  final String mensagemCidadao;
  final String? relatorioColaborador;
  final Prioridade? prioridade;

  final String? dataInicioAtendimento;
  final String? dataFimAtendimento;
  final int tempoAcumulado;

  Denuncia({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.data,
    required this.imagens,
    required this.fotosCidadao,
    required this.fotosColaborador,
    required this.descricaoAdmin,
    required this.justificativaCancelamento,
    required this.mensagemCidadao,
    this.relatorioColaborador,
    this.prioridade,
    this.dataInicioAtendimento,
    this.dataFimAtendimento,
    this.tempoAcumulado = 0,
  });

  factory Denuncia.fromJson(Map<String, dynamic> json) {
    // Pegar fotos do relacionamento 'fotos' se existir
    List<String> imgs = [];
    List<String> imgsCidadao = [];
    List<String> imgsColab = [];

    if (json['fotos'] != null && json['fotos'] is List) {
      for (var f in (json['fotos'] as List)) {
        String caminho = f['caminho_foto'].toString();
        imgs.add(caminho);
        
        // tipo 1 = Cidadão, tipo 2 = Colaborador
        int tipoFoto = int.tryParse(f['tipo']?.toString() ?? '1') ?? 1;
        if (tipoFoto == 2) {
          imgsColab.add(caminho);
        } else {
          imgsCidadao.add(caminho);
        }
      }
    } else if (json['imagens'] != null) {
      imgs = List<String>.from(json['imagens']);
      imgsCidadao = imgs; // Fallback
    }

    // Pegar datas de atendimento do relacionamento 'atendimentos' se existir
    String? start;
    String? end;
    String? relatorio;
    int acc = 0;

    if (json['atendimentos'] != null && json['atendimentos'] is List && (json['atendimentos'] as List).isNotEmpty) {
      // Pega o último atendimento (mais recente)
      final lastAtendimento = (json['atendimentos'] as List).last;
      start = lastAtendimento['data_inicio_atendimento'];
      end = lastAtendimento['data_fim_atendimento'];
      acc = lastAtendimento['tempo_acumulado'] ?? 0;
      relatorio = lastAtendimento['relatorio_colaborador'];
    }

    return Denuncia(
      id: json['id_denuncia'] ?? json['id'] ?? 0,
      titulo: json['titulo_denuncia'] ?? '',
      tipo: json['tipo_denuncia']?.toString() ?? '6',
      descricao: json['descricao_denuncia'] ?? '',
      latitude: json['latitude_denuncia'] != null ? double.parse(json['latitude_denuncia'].toString()) : 0.0,
      longitude: json['longitude_denuncia'] != null ? double.parse(json['longitude_denuncia'].toString()) : 0.0,
      status: json['status_denuncia'].toString(),
      data: json['data_denuncia'] ?? '',
      imagens: imgs,
      fotosCidadao: imgsCidadao,
      fotosColaborador: imgsColab,
      descricaoAdmin: json['mensagem_admin'] ?? '',
      justificativaCancelamento: json['justificativa_cancelamento'] ?? '',
      mensagemCidadao: json['mensagem_cidadao'] ?? '',
      relatorioColaborador: relatorio,
      prioridade: json['prioridade'] != null ? Prioridade.fromJson(json['prioridade']) : null,
      dataInicioAtendimento: start,
      dataFimAtendimento: end,
      tempoAcumulado: acc,
    );
  }
}
