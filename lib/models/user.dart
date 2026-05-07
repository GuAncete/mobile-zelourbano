class User {
  final int id;
  final String nome;
  final String email;
  final String? documento;
  final String? telefone;
  final String tipo;
  final bool status;

  User({
    required this.id,
    required this.nome,
    required this.email,
    this.documento,
    this.telefone,
    required this.tipo,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Tratamento robusto para os tipos vindos do Laravel
    final int idVal = json['id_user'] ?? json['id'] ?? 0;
    
    // Converte status para bool seja ele vindo como inteiro(1/0) ou booleano(true/false)
    bool statusVal = true;
    if (json['status_usuario'] != null) {
      if (json['status_usuario'] is bool) {
        statusVal = json['status_usuario'];
      } else if (json['status_usuario'] is int) {
        statusVal = json['status_usuario'] == 1;
      }
    }

    return User(
      id: idVal,
      nome: json['nome_usuario'] ?? '',
      email: json['email_usuario'] ?? '',
      documento: json['documento_usuario']?.toString(),
      telefone: json['telefone_usuario']?.toString(),
      tipo: json['tipo_usuario']?.toString() ?? '1', 
      status: statusVal,
    );
  }

  /// Retorna true se o usuário é colaborador (tipo 2)
  bool get isColaborador => tipo == '2';

  Map<String, dynamic> toJson() {
    return {
      'id_user': id,
      'nome_usuario': nome,
      'email_usuario': email,
      'documento_usuario': documento,
      'telefone_usuario': telefone,
      'tipo_usuario': tipo,
      'status_usuario': status,
    };
  }
}
