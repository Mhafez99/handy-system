import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/profiles_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildProfileRouter(ProfilesRepository repository) {
  final router = Router()
    ..get('/', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final profile = await repository.getProfile(userId);
      return jsonOk(profile);
    })
    ..patch('/', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);

      final fullName = body['full_name'];
      final phone = body['phone'];
      final governorate = body['governorate'];
      final area = body['area'];
      final areaId = body['area_id'];
      final address = body['address'];

      if (fullName is! String ||
          phone is! String ||
          governorate is! String ||
          area is! String ||
          areaId is! int ||
          address is! String) {
        return jsonError(400, 'Invalid profile payload');
      }

      final worker = body['worker'];
      String? profession;
      int? yearsExperience;
      String? bio;

      if (worker is Map) {
        profession = worker['profession'] as String?;
        yearsExperience = worker['years_experience'] as int?;
        bio = worker['bio'] as String?;
      }

      final profile = await repository.updateProfile(
        userId,
        fullName: fullName,
        phone: phone,
        governorate: governorate,
        area: area,
        areaId: areaId,
        address: address,
        profession: profession,
        yearsExperience: yearsExperience,
        bio: bio,
      );

      return jsonOk(profile);
    });

  return router.call;
}
