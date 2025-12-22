class User {
  final int id;
  final String name;
  final String? email;
  final String? phone;  // Ajoutez ce champ
  final String? wilaya;
  final String? role;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,  // Ajoutez ce paramètre
    this.wilaya,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Distributeur',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),  // Ajoutez cette ligne
      wilaya: json['wilaya']?.toString(),
      role: json['role']?.toString() ?? 'distributor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,  // Ajoutez cette ligne
      'wilaya': wilaya,
      'role': role,
    };
  }
}