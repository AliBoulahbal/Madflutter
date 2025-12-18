class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? distributorId;
  final String? wilaya;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.distributorId,
    this.wilaya,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Le log montre que l'user est parfois dans json['user']
    final userData = json['user'] ?? json;
    return User(
      id: userData['id'] ?? 0,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      role: userData['role'] ?? 'user',
      distributorId: userData['distributor_id'],
      wilaya: userData['wilaya'], // Extraction de "Batna" par exemple
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'distributor_id': distributorId,
      'wilaya': wilaya,
    };
  }

  bool get isDistributor => role == 'distributor';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
}