// models/school.dart
class School {
  final int id;
  final String name;
  final String? managerName;
  final String? district;
  final String? commune;
  final String? address;
  final String? phone;
  final int? studentCount;
  final String? wilaya;
  final double? latitude;
  final double? longitude;
  final double? radius;

  School({
    required this.id,
    required this.name,
    this.managerName,
    required this.district,
    this.commune,
    this.address,
    this.phone,
    this.studentCount,
    this.wilaya,
    this.latitude,
    this.longitude,
    this.radius,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'École sans nom',
      managerName: json['manager_name']?.toString(),
      district: json['district']?.toString() ?? '',
      commune: json['commune']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      studentCount: json['student_count'] is int
          ? json['student_count']
          : int.tryParse(json['student_count']?.toString() ?? ''),
      wilaya: json['wilaya']?.toString(),
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.tryParse(json['longitude']?.toString() ?? ''),
      radius: json['radius'] is double
          ? json['radius']
          : double.tryParse(json['radius']?.toString() ?? ''),
    );
  }
}