import '../core/constants/role_constants.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String? nis;
  final String? avatarUrl;
  final String role;
  final String? email;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    this.nis,
    this.avatarUrl,
    required this.role,
    this.email,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      nis: map['nis'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: normalizeRole(map['role'] as String?),
      email: map['email'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'nis': nis,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }

  bool get isBendahara => isTreasurerRole(role);
  bool get isSiswa => normalizeRole(role) == 'siswa';
}
