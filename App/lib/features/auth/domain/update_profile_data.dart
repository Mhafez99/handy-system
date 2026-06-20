class UpdateProfileData {
  const UpdateProfileData({
    required this.fullName,
    required this.phone,
    required this.governorate,
    required this.area,
    required this.areaId,
    required this.address,
    this.profession,
    this.yearsExperience,
    this.bio,
  });

  final String fullName;
  final String phone;
  final String governorate;
  final String area;
  final int areaId;
  final String address;
  final String? profession;
  final int? yearsExperience;
  final String? bio;

  bool get includesWorkerFields =>
      profession != null && yearsExperience != null && bio != null;
}
