import 'package:handy_app/features/auth/domain/account_role.dart';

class RegistrationData {
  const RegistrationData({
    required this.role,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.governorate,
    required this.area,
    required this.address,
    this.profession,
    this.yearsExperience,
    this.bio,
  });

  final AccountRole role;
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String governorate;
  final String area;
  final String address;
  final String? profession;
  final int? yearsExperience;
  final String? bio;

  Map<String, dynamic> toMetadata() {
    return {
      'role': role.value,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'governorate': governorate.trim(),
      'area': area.trim(),
      'address': address.trim(),
      if (profession != null) 'profession': profession,
      if (yearsExperience != null) 'years_experience': yearsExperience,
      if (bio != null && bio!.trim().isNotEmpty) 'bio': bio!.trim(),
    };
  }
}
