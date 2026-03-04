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
    return User(
      id: json['id_user'] ?? json['id'] ?? 0,
      nome: json['nome_usuario'] ?? '',
      email: json['email_usuario'] ?? '',
      documento: json['documento_usuario'],
      telefone: json['telefone_usuario'],
      tipo: json['tipo_usuario'] ?? 'cidadao',
      status: json['status_usuario'] ?? true,
    );
  }

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
