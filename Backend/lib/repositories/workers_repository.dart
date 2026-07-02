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

    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            sr.worker_id,
            round(avg(sr.rating)::numeric, 1) as average_rating,
            count(*)::bigint as review_count
          from public.service_reviews sr
          where sr.worker_id = any(@workerIds::uuid[])
            and sr.is_hidden = false
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
    });
  }

  Future<Map<String, Object?>> getWorkerPublicDetails(String workerId) {
    return _database.withReadConnection((connection) async {
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
            and is_hidden = false
        '''),
        parameters: {'workerId': workerId},
      );

      final stats = statsResult.first;
      final reviewsResult = await connection.execute(
        Sql.named('''
          select id, rating, comment, created_at
          from public.service_reviews
          where worker_id = @workerId::uuid
            and is_hidden = false
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
    });
  }

  Future<Map<String, Object?>> getWorkerEarnings(String workerId) {
    return _database.withReadConnection((connection) async {
      final summaryResult = await connection.execute(
        Sql.named('''
          select
            count(*)::int as jobs_count,
            coalesce(sum(gross_amount), 0)::bigint as total_gross,
            coalesce(sum(commission_amount), 0)::bigint as total_commission,
            coalesce(sum(net_amount), 0)::bigint as total_net
          from public.platform_commissions
          where worker_id = @workerId::uuid
        '''),
        parameters: {'workerId': workerId},
      );

      final recentResult = await connection.execute(
        Sql.named('''
          select
            pc.request_id,
            pc.gross_amount,
            pc.commission_rate::float8,
            pc.commission_amount,
            pc.net_amount,
            pc.created_at,
            s.name as service_name,
            c.name as category_name
          from public.platform_commissions pc
          left join public.service_requests sr on sr.id = pc.request_id
          left join public.services s on s.id = sr.service_id
          left join public.categories c on c.id = pc.category_id
          where pc.worker_id = @workerId::uuid
          order by pc.created_at desc
          limit 30
        '''),
        parameters: {'workerId': workerId},
      );

      final summary = summaryResult.first;
      final recent = recentResult
          .map(
            (row) => {
              'request_id': row[0]?.toString(),
              'gross_amount': row[1],
              'commission_rate': row[2],
              'commission_amount': row[3],
              'net_amount': row[4],
              'created_at': _formatTimestamp(row[5]),
              'service_name': row[6],
              'category_name': row[7],
            },
          )
          .toList(growable: false);

      return {
        'jobs_count': summary[0],
        'total_gross': summary[1],
        'total_commission': summary[2],
        'total_net': summary[3],
        'recent': recent,
      };
    });
  }

  String? _formatTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value?.toString();
  }
}
