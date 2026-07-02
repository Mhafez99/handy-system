import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:postgres/postgres.dart';

class ProfilesRepository {
  ProfilesRepository(this._database);

  final Database _database;

  static const _allowedProfessions = {
    'سباك',
    'كهربائي',
    'نجار',
    'نقاش',
    'فني تكييف',
  };

  Future<Map<String, Object?>> getProfile(String userId) {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            p.id,
            p.role,
            p.full_name,
            p.phone,
            p.governorate,
            p.area,
            p.area_id,
            p.address,
            p.status,
            p.created_at,
            p.updated_at,
            wp.profession,
            wp.years_experience,
            wp.bio,
            wp.approval_status
          from public.profiles p
          left join public.worker_profiles wp on wp.user_id = p.id
          where p.id = @userId::uuid
        '''),
        parameters: {'userId': userId},
      );

      if (result.isEmpty) {
        throw const RequestActionException('Profile was not found');
      }

      return _mapProfileRow(result.first);
    });
  }

  Future<Map<String, Object?>> updateProfile(
    String userId, {
    required String fullName,
    required String phone,
    required String governorate,
    required String area,
    required int areaId,
    required String address,
    String? profession,
    int? yearsExperience,
    String? bio,
  }) async {
    final trimmedFullName = fullName.trim();
    final trimmedPhone = phone.trim();
    final trimmedGovernorate = governorate.trim();
    final trimmedArea = area.trim();
    final trimmedAddress = address.trim();

    if (trimmedFullName.length < 3) {
      throw const RequestActionException('Full name is required');
    }
    if (!RegExp(r'^01[0-9]{9}$').hasMatch(trimmedPhone)) {
      throw const RequestActionException('Invalid phone number');
    }
    if (trimmedGovernorate.length < 2) {
      throw const RequestActionException('Governorate is required');
    }
    if (trimmedArea.length < 2) {
      throw const RequestActionException('Area is required');
    }
    if (trimmedAddress.length < 5) {
      throw const RequestActionException('Address is required');
    }

    final includesWorkerFields =
        profession != null && yearsExperience != null && bio != null;
    final trimmedProfession = profession?.trim();
    final trimmedBio = bio?.trim();

    if (includesWorkerFields) {
      if (!_allowedProfessions.contains(trimmedProfession)) {
        throw const RequestActionException('Invalid profession');
      }
      if (yearsExperience < 0 || yearsExperience > 70) {
        throw const RequestActionException('Invalid years of experience');
      }
      if ((trimmedBio ?? '').length < 10) {
        throw const RequestActionException('Bio is too short');
      }
    }

    return _database.withConnection((connection) async {
      await connection.runTx((session) async {
        final updated = await session.execute(
          Sql.named('''
            update public.profiles
            set full_name = @fullName,
                phone = @phone,
                governorate = @governorate,
                area = @area,
                area_id = @areaId,
                address = @address,
                updated_at = now()
            where id = @userId::uuid
          '''),
          parameters: {
            'userId': userId,
            'fullName': trimmedFullName,
            'phone': trimmedPhone,
            'governorate': trimmedGovernorate,
            'area': trimmedArea,
            'areaId': areaId,
            'address': trimmedAddress,
          },
        );

        if (updated.affectedRows == 0) {
          throw const RequestActionException('Profile was not found');
        }

        if (includesWorkerFields) {
          final workerUpdate = await session.execute(
            Sql.named('''
              update public.worker_profiles
              set profession = @profession,
                  years_experience = @yearsExperience,
                  bio = @bio
              where user_id = @userId::uuid
            '''),
            parameters: {
              'userId': userId,
              'profession': trimmedProfession,
              'yearsExperience': yearsExperience,
              'bio': trimmedBio,
            },
          );

          if (workerUpdate.affectedRows == 0) {
            throw const RequestActionException('Worker profile was not found');
          }
        }
      });

      return getProfile(userId);
    });
  }

  Map<String, Object?> _mapProfileRow(ResultRow row) {
    final profession = row[11];
    final approvalStatus = row[14];
    final hasWorker = profession != null || approvalStatus != null;

    return {
      'id': row[0]?.toString(),
      'role': row[1],
      'full_name': row[2],
      'phone': row[3],
      'governorate': row[4],
      'area': row[5],
      'area_id': row[6],
      'address': row[7],
      'status': row[8],
      'created_at': _formatTimestamp(row[9]),
      'updated_at': _formatTimestamp(row[10]),
      'worker': hasWorker
          ? {
              'profession': profession,
              'years_experience': row[12],
              'bio': row[13],
              'approval_status': approvalStatus,
            }
          : null,
    };
  }

  String? _formatTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value?.toString();
  }
}
