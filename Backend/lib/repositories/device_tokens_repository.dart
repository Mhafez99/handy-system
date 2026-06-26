import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:postgres/postgres.dart';

class DeviceTokensRepository {
  DeviceTokensRepository(this._database);

  final Database _database;

  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.length < 20) {
      throw const RequestActionException('Invalid device token');
    }

    const allowedPlatforms = {'android', 'ios', 'web'};
    if (!allowedPlatforms.contains(platform)) {
      throw const RequestActionException('Invalid device platform');
    }

    await _database.withConnection((connection) async {
      await connection.execute(
        Sql.named('''
          insert into public.device_tokens (
            user_id,
            token,
            platform
          )
          values (
            @userId::uuid,
            @token,
            @platform
          )
          on conflict (user_id, token) do update
          set platform = excluded.platform,
              updated_at = now()
        '''),
        parameters: {
          'userId': userId,
          'token': trimmedToken,
          'platform': platform,
        },
      );
    });
  }

  Future<void> deleteToken({
    required String userId,
    required String token,
  }) {
    return _database.withConnection((connection) async {
      await connection.execute(
        Sql.named('''
          delete from public.device_tokens
          where user_id = @userId::uuid
            and token = @token
        '''),
        parameters: {'userId': userId, 'token': token.trim()},
      );
    });
  }

  Future<List<String>> listTokensForUser(String userId) {
    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select token
          from public.device_tokens
          where user_id = @userId::uuid
          order by updated_at desc
        '''),
        parameters: {'userId': userId},
      );

      return result
          .map((row) => row[0]?.toString() ?? '')
          .where((token) => token.isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<void> deleteTokenEverywhere(String token) {
    return _database.withConnection((connection) async {
      await connection.execute(
        Sql.named('''
          delete from public.device_tokens
          where token = @token
        '''),
        parameters: {'token': token.trim()},
      );
    });
  }
}
