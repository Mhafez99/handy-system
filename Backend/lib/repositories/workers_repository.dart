import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:postgres/postgres.dart';

class WorkersRepository {
  WorkersRepository(this._database);

  final Database _database;

  Future<List<Map<String, Object?>>> getWorkerRatingSummary(
    List<String> workerIds,
  ) async {
    if (workerIds.isEmpty) {
      return const [];
    }

    final connection = await _database.connect();
    final result = await connection.execute(
      Sql.named('''
        select
          sr.worker_id,
          round(avg(sr.rating)::numeric, 1) as average_rating,
          count(*)::bigint as review_count
        from public.service_reviews sr
        where sr.worker_id = any(@workerIds::uuid[])
        group by sr.worker_id
      '''),
      parameters: {'workerIds': workerIds},
    );

    return result
        .map(
          (row) => {
            'worker_id': row[0]?.toString(),
            'average_rating': row[1],
            'review_count': row[2],
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, Object?>> getWorkerPublicDetails(String workerId) async {
    final connection = await _database.connect();
    final profileResult = await connection.execute(
      Sql.named('''
        select
          p.id,
          p.full_name,
          p.governorate,
          p.area,
          wp.profession,
          wp.years_experience,
          wp.bio,
          p.created_at
        from public.profiles p
        join public.worker_profiles wp on wp.user_id = p.id
        where p.id = @workerId::uuid
          and p.role = 'worker'
          and p.status = 'active'
          and wp.approval_status = 'approved'
      '''),
      parameters: {'workerId': workerId},
    );

    if (profileResult.isEmpty) {
      throw const RequestActionException('Worker was not found');
    }

    final profile = profileResult.first;
    final statsResult = await connection.execute(
      Sql.named('''
        select
          round(avg(rating)::numeric, 1) as average_rating,
          count(*)::bigint as review_count
        from public.service_reviews
        where worker_id = @workerId::uuid
      '''),
      parameters: {'workerId': workerId},
    );

    final stats = statsResult.first;
    final reviewsResult = await connection.execute(
      Sql.named('''
        select id, rating, comment, created_at
        from public.service_reviews
        where worker_id = @workerId::uuid
        order by created_at desc
        limit 5
      '''),
      parameters: {'workerId': workerId},
    );

    final reviews = reviewsResult
        .map(
          (row) => {
            'id': row[0]?.toString(),
            'rating': row[1],
            'comment': row[2],
            'created_at': _formatTimestamp(row[3]),
          },
        )
        .toList(growable: false);

    return {
      'worker_id': profile[0]?.toString(),
      'full_name': profile[1],
      'governorate': profile[2],
      'area': profile[3],
      'profession': profile[4],
      'years_experience': profile[5],
      'bio': profile[6],
      'created_at': _formatTimestamp(profile[7]),
      'average_rating': stats[0],
      'review_count': stats[1] ?? 0,
      'reviews': reviews,
    };
  }

  String? _formatTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value?.toString();
  }
}
