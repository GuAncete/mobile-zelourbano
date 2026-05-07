class Prioridade {
  final int id;
  final String nome;
  final String cor;
  final int ordem;

  Prioridade({
    required this.id,
    required this.nome,
    required this.cor,
    required this.ordem,
  });

  factory Prioridade.fromJson(Map<String, dynamic> json) {
    return Prioridade(
      id: json['id'] ?? 0,
      nome: json['nome_prioridade'] ?? '',
      cor: json['cor_prioridade'] ?? '#808080',
      ordem: json['ordem'] ?? 0,
    );
  }
}
