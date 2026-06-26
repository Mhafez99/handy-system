import 'dart:convert';

import 'package:handy_backend/cache/cache_store.dart';
import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:handy_backend/repositories/admin_operations.dart';
import 'package:postgres/postgres.dart';

class AdminRepository implements AdminOperations {
  AdminRepository(
    this._database, {
    CacheStore? cache,
    Duration statsCacheTtl = const Duration(seconds: 60),
  }) : _cache = cache,
       _statsCacheTtl = statsCacheTtl;

  final Database _database;
  final CacheStore? _cache;
  final Duration _statsCacheTtl;

  static const _overviewCachePrefix = 'admin:overview:';

  @override
  Future<bool> isAdmin(String userId) {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select exists (
            select 1
            from public.admin_users
            where user_id = @userId::uuid
          )
        '''),
        parameters: {'userId': userId},
      );

      return result.first[0] == true;
    });
  }

  @override
  Future<Map<String, Object?>> getOverviewStats({
    DateTime? from,
    DateTime? to,
  }) async {
    final cacheKey = _overviewCacheKey('stats', from: from, to: to);
    final cached = await _readCachedMap(cacheKey);
    if (cached != null) {
      return cached;
    }

    final stats = await _loadOverviewStatsFromDatabase(from: from, to: to);
    await _writeCachedMap(cacheKey, stats);
    return stats;
  }

  @override
  Future<List<Map<String, Object?>>> getOverviewDailyTrend({
    DateTime? from,
    DateTime? to,
  }) async {
    final cacheKey = _overviewCacheKey('trend', from: from, to: to);
    final cached = await _readCachedList(cacheKey);
    if (cached != null) {
      return cached;
    }

    final trend = await _loadOverviewDailyTrendFromDatabase(from: from, to: to);
    await _writeCachedList(cacheKey, trend);
    return trend;
  }

  Future<Map<String, Object?>> _loadOverviewStatsFromDatabase({
    DateTime? from,
    DateTime? to,
  }) {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select jsonb_build_object(
            'total_requests', (
              select count(*)::int
              from public.service_requests sr
              where (@from::timestamptz is null or sr.created_at >= @from)
                and (@to::timestamptz is null or sr.created_at <= @to)
            ),
            'requests_today', (
              select count(*)::int
              from public.service_requests
              where created_at >= date_trunc('day', timezone('utc', now()))
            ),
            'completed_requests', (
              select count(*)::int
              from public.service_requests sr
              where sr.status = 'completed'
                and (@from::timestamptz is null or sr.created_at >= @from)
                and (@to::timestamptz is null or sr.created_at <= @to)
            ),
            'active_requests', (
              select count(*)::int
              from public.service_requests sr
              where sr.status in (
                'new', 'offered', 'accepted', 'on_the_way', 'in_progress'
              )
                and (@from::timestamptz is null or sr.created_at >= @from)
                and (@to::timestamptz is null or sr.created_at <= @to)
            ),
            'open_complaints', (
              select count(*)::int
              from public.service_complaints
              where status in ('open', 'in_review')
            ),
            'pending_workers', (
              select count(*)::int
              from public.profiles p
              join public.worker_profiles wp on wp.user_id = p.id
              where p.role = 'worker'
                and p.status = 'pending'
                and wp.approval_status = 'pending'
            ),
            'total_customers', (
              select count(*)::int from public.profiles where role = 'customer'
            ),
            'active_workers', (
              select count(*)::int
              from public.profiles
              where role = 'worker' and status = 'active'
            ),
            'total_offers', (select count(*)::int from public.offers),
            'offers_in_period', (
              select count(*)::int
              from public.offers o
              where (@from::timestamptz is null or o.created_at >= @from)
                and (@to::timestamptz is null or o.created_at <= @to)
            ),
            'status_counts', (
              select coalesce(jsonb_object_agg(status, status_count), '{}'::jsonb)
              from (
                select sr.status, count(*)::int as status_count
                from public.service_requests sr
                where (@from::timestamptz is null or sr.created_at >= @from)
                  and (@to::timestamptz is null or sr.created_at <= @to)
                group by sr.status
              ) grouped_statuses
            ),
            'is_filtered', (@from::timestamptz is not null or @to::timestamptz is not null)
          )
        '''),
        parameters: {
          'from': from,
          'to': to,
        },
      );

      return _decodeJsonObject(result.first[0]);
    });
  }

  Future<List<Map<String, Object?>>> _loadOverviewDailyTrendFromDatabase({
    DateTime? from,
    DateTime? to,
  }) {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named(r'''
          with bounds as (
            select
              coalesce(
                @from::timestamptz,
                date_trunc('day', timezone('utc', now()) - interval '29 days')
              ) as range_from,
              coalesce(
                @to::timestamptz,
                date_trunc('day', timezone('utc', now()))
                  + interval '1 day' - interval '1 microsecond'
              ) as range_to
          ),
          series as (
            select gs.day::date as day
            from bounds b,
            generate_series(
              date_trunc('day', b.range_from)::date,
              date_trunc('day', b.range_to)::date,
              interval '1 day'
            ) as gs(day)
          ),
          counts as (
            select
              date_trunc('day', sr.created_at)::date as day,
              count(*)::int as total,
              count(*) filter (where sr.status = 'completed')::int as completed
            from public.service_requests sr
            cross join bounds b
            where sr.created_at >= b.range_from
              and sr.created_at <= b.range_to
            group by 1
          )
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'day', series.day,
                'total', coalesce(counts.total, 0),
                'completed', coalesce(counts.completed, 0)
              )
              order by series.day
            ),
            '[]'::jsonb
          )
          from series
          left join counts on counts.day = series.day
        '''),
        parameters: {
          'from': from,
          'to': to,
        },
      );

      return _decodeJsonList(result.first[0]);
    });
  }

  @override
  Future<List<Map<String, Object?>>> listRecentRequests({
    int limit = 20,
    DateTime? from,
    DateTime? to,
    String? status,
  }) {
    final boundedLimit = limit.clamp(1, 50);

    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            sr.id,
            sr.status,
            sr.created_at,
            sr.area,
            sr.governorate,
            service.name as service_name,
            category.name as category_name,
            customer.full_name as customer_name,
            coalesce(worker.full_name, '') as worker_name,
            (
              select count(*)
              from public.offers o
              where o.request_id = sr.id
            ) as offer_count,
            sr.final_price,
            sr.payment_method
          from public.service_requests sr
          join public.services service on service.id = sr.service_id
          join public.categories category on category.id = sr.category_id
          join public.profiles customer on customer.id = sr.customer_id
          left join lateral (
            select p.full_name
            from public.offers o
            join public.profiles p on p.id = o.worker_id
            where o.request_id = sr.id
              and o.status = 'accepted'
            limit 1
          ) worker on true
          where (@from::timestamptz is null or sr.created_at >= @from)
            and (@to::timestamptz is null or sr.created_at <= @to)
            and (@status::text is null or sr.status = @status)
          order by sr.created_at desc
          limit @limit
        '''),
        parameters: {
          'limit': boundedLimit,
          'from': from,
          'to': to,
          'status': status,
        },
      );

      return result
          .map(
            (row) => {
              'id': row[0]?.toString(),
              'status': row[1],
              'created_at': _formatTimestamp(row[2]),
              'area': row[3],
              'governorate': row[4],
              'service_name': row[5],
              'category_name': row[6],
              'customer_name': row[7],
              'worker_name': row[8],
              'offer_count': row[9],
              'final_price': row[10],
              'payment_method': row[11],
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<Map<String, Object?>>> listPendingWorkers() {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql('''
          select
            p.id as user_id,
            p.full_name,
            p.phone,
            p.governorate,
            p.area,
            p.address,
            wp.profession,
            wp.years_experience,
            wp.bio,
            p.created_at
          from public.profiles p
          join public.worker_profiles wp on wp.user_id = p.id
          where p.role = 'worker'
            and p.status = 'pending'
            and wp.approval_status = 'pending'
          order by p.created_at asc
        '''),
      );

      return result
          .map(
            (row) => {
              'user_id': row[0]?.toString(),
              'full_name': row[1],
              'phone': row[2],
              'governorate': row[3],
              'area': row[4],
              'address': row[5],
              'profession': row[6],
              'years_experience': row[7],
              'bio': row[8],
              'created_at': _formatTimestamp(row[9]),
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> approveWorker(String workerId) async {
    await _database.withConnection((connection) async {
      await connection.execute(
        Sql.named('''
          update public.profiles
          set status = 'active',
              updated_at = now()
          where id = @workerId::uuid
            and role = 'worker'
        '''),
        parameters: {'workerId': workerId},
      );

      final workerUpdate = await connection.execute(
        Sql.named('''
          update public.worker_profiles
          set approval_status = 'approved',
              reviewed_at = now()
          where user_id = @workerId::uuid
        '''),
        parameters: {'workerId': workerId},
      );

      if (workerUpdate.affectedRows == 0) {
        throw const RequestActionException('Worker was not found');
      }
    });
    await _invalidateOverviewCache();
  }

  @override
  Future<void> rejectWorker(String workerId) async {
    await _database.withConnection((connection) async {
      await connection.execute(
        Sql.named('''
          update public.profiles
          set status = 'suspended',
              updated_at = now()
          where id = @workerId::uuid
            and role = 'worker'
        '''),
        parameters: {'workerId': workerId},
      );

      final workerUpdate = await connection.execute(
        Sql.named('''
          update public.worker_profiles
          set approval_status = 'rejected',
              reviewed_at = now()
          where user_id = @workerId::uuid
        '''),
        parameters: {'workerId': workerId},
      );

      if (workerUpdate.affectedRows == 0) {
        throw const RequestActionException('Worker was not found');
      }
    });
    await _invalidateOverviewCache();
  }

  @override
  Future<List<Map<String, Object?>>> listAreas() {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql('''
          select id, governorate, name, sort_order, is_active, created_at
          from public.areas
          order by governorate, sort_order, name
        '''),
      );

      return result.map(_mapAreaRow).toList(growable: false);
    });
  }

  @override
  Future<int> createArea({
    required String governorate,
    required String name,
    int sortOrder = 0,
  }) {
    final trimmedGovernorate = governorate.trim();
    final trimmedName = name.trim();

    if (trimmedGovernorate.length < 2) {
      throw const RequestActionException('Governorate is required');
    }
    if (trimmedName.length < 2) {
      throw const RequestActionException('Area name is required');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          insert into public.areas (governorate, name, sort_order, is_active)
          values (@governorate, @name, @sortOrder, true)
          returning id
        '''),
        parameters: {
          'governorate': trimmedGovernorate,
          'name': trimmedName,
          'sortOrder': sortOrder,
        },
      );

      final areaId = _readInt(result.first[0]);
      await _invalidateOverviewCache();
      return areaId;
    });
  }

  @override
  Future<void> updateArea({
    required int areaId,
    required String governorate,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) {
    final trimmedGovernorate = governorate.trim();
    final trimmedName = name.trim();

    if (trimmedGovernorate.length < 2) {
      throw const RequestActionException('Governorate is required');
    }
    if (trimmedName.length < 2) {
      throw const RequestActionException('Area name is required');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          update public.areas
          set governorate = @governorate,
              name = @name,
              sort_order = @sortOrder,
              is_active = @isActive
          where id = @areaId
        '''),
        parameters: {
          'areaId': areaId,
          'governorate': trimmedGovernorate,
          'name': trimmedName,
          'sortOrder': sortOrder,
          'isActive': isActive,
        },
      );

      if (result.affectedRows == 0) {
        throw const RequestActionException('Area was not found');
      }
      await _invalidateOverviewCache();
    });
  }

  @override
  Future<List<Map<String, Object?>>> listComplaints() {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql('''
          select
            c.id,
            c.request_id,
            c.category,
            c.description,
            c.status,
            c.created_at,
            customer.full_name as customer_name,
            customer.phone as customer_phone,
            worker.full_name as worker_name,
            worker.phone as worker_phone,
            service.name as service_name,
            sr.area
          from public.service_complaints c
          join public.service_requests sr on sr.id = c.request_id
          join public.profiles customer on customer.id = c.customer_id
          join public.profiles worker on worker.id = c.worker_id
          join public.services service on service.id = sr.service_id
          order by
            case c.status
              when 'open' then 0
              when 'in_review' then 1
              else 2
            end,
            c.created_at desc
        '''),
      );

      return result
          .map(
            (row) => {
              'id': row[0]?.toString(),
              'request_id': row[1]?.toString(),
              'category': row[2],
              'description': row[3],
              'status': row[4],
              'created_at': _formatTimestamp(row[5]),
              'customer_name': row[6],
              'customer_phone': row[7],
              'worker_name': row[8],
              'worker_phone': row[9],
              'service_name': row[10],
              'area': row[11],
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  }) {
    const allowed = {'open', 'in_review', 'resolved', 'dismissed'};
    if (!allowed.contains(status)) {
      throw const RequestActionException('Invalid complaint status');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          update public.service_complaints
          set status = @status,
              updated_at = now()
          where id = @complaintId::uuid
        '''),
        parameters: {
          'complaintId': complaintId,
          'status': status,
        },
      );

      if (result.affectedRows == 0) {
        throw const RequestActionException('Complaint was not found');
      }
      await _invalidateOverviewCache();
    });
  }

  @override
  Future<List<Map<String, Object?>>> listUsers({
    String? role,
    String? status,
  }) {
    if (role != null && role != 'customer' && role != 'worker') {
      throw const RequestActionException('Invalid role filter');
    }
    if (status != null &&
        status != 'active' &&
        status != 'pending' &&
        status != 'suspended') {
      throw const RequestActionException('Invalid status filter');
    }

    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            p.id as user_id,
            p.full_name,
            p.phone,
            p.role,
            p.governorate,
            p.area,
            p.status,
            coalesce(wp.profession, '') as profession,
            coalesce(wp.approval_status, '') as approval_status,
            p.created_at
          from public.profiles p
          left join public.worker_profiles wp on wp.user_id = p.id
          where not exists (
            select 1
            from public.admin_users au
            where au.user_id = p.id
          )
            and (@role::text is null or p.role = @role)
            and (@status::text is null or p.status = @status)
          order by p.created_at desc
        '''),
        parameters: {
          'role': role,
          'status': status,
        },
      );

      return result
          .map(
            (row) => {
              'user_id': row[0]?.toString(),
              'full_name': row[1],
              'phone': row[2],
              'role': row[3],
              'governorate': row[4],
              'area': row[5],
              'status': row[6],
              'profession': row[7],
              'approval_status': row[8],
              'created_at': _formatTimestamp(row[9]),
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> updateUserStatus({
    required String adminUserId,
    required String userId,
    required String status,
  }) {
    if (status != 'active' && status != 'suspended') {
      throw const RequestActionException('Invalid status');
    }
    if (userId == adminUserId) {
      throw const RequestActionException('Cannot change your own status');
    }

    return _database.withConnection((connection) async {
      final adminCheck = await connection.execute(
        Sql.named('''
          select exists (
            select 1
            from public.admin_users
            where user_id = @userId::uuid
          )
        '''),
        parameters: {'userId': userId},
      );

      if (adminCheck.first[0] == true) {
        throw const RequestActionException('Cannot change admin account status');
      }

      final profileResult = await connection.execute(
        Sql.named('''
          select role
          from public.profiles
          where id = @userId::uuid
        '''),
        parameters: {'userId': userId},
      );

      if (profileResult.isEmpty) {
        throw const RequestActionException('User was not found');
      }

      final targetRole = profileResult.first[0]?.toString();
      if (status == 'active' && targetRole == 'worker') {
        final approvalResult = await connection.execute(
          Sql.named('''
            select approval_status
            from public.worker_profiles
            where user_id = @userId::uuid
          '''),
          parameters: {'userId': userId},
        );

        if (approvalResult.isEmpty) {
          throw const RequestActionException(
            'Worker must be approved before activation',
          );
        }

        final approvalStatus = approvalResult.first[0]?.toString();
        if (approvalStatus != 'approved') {
          throw const RequestActionException(
            'Worker must be approved before activation',
          );
        }
      }

      final updateResult = await connection.execute(
        Sql.named('''
          update public.profiles
          set status = @status,
              updated_at = now()
          where id = @userId::uuid
        '''),
        parameters: {
          'userId': userId,
          'status': status,
        },
      );

      if (updateResult.affectedRows == 0) {
        throw const RequestActionException('User was not found');
      }
      await _invalidateOverviewCache();
    });
  }

  @override
  Future<List<Map<String, Object?>>> listCategories() {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql('''
          select
            c.id,
            c.name,
            c.sort_order,
            c.is_active,
            (
              select count(*)
              from public.services s
              where s.category_id = c.id
            ) as service_count,
            (
              select count(*)
              from public.services s
              where s.category_id = c.id
                and s.is_active = true
            ) as active_service_count,
            c.created_at
          from public.categories c
          order by c.sort_order, c.name
        '''),
      );

      return result
          .map(
            (row) => {
              'id': row[0],
              'name': row[1],
              'sort_order': row[2],
              'is_active': row[3],
              'service_count': row[4],
              'active_service_count': row[5],
              'created_at': _formatTimestamp(row[6]),
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<int> createCategory({
    required String name,
    int sortOrder = 0,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      throw const RequestActionException('Category name is required');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          insert into public.categories (name, sort_order, is_active)
          values (@name, @sortOrder, true)
          returning id
        '''),
        parameters: {
          'name': trimmedName,
          'sortOrder': sortOrder,
        },
      );

      final categoryId = _readInt(result.first[0]);
      await _invalidateOverviewCache();
      return categoryId;
    });
  }

  @override
  Future<void> updateCategory({
    required int categoryId,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      throw const RequestActionException('Category name is required');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          update public.categories
          set name = @name,
              sort_order = @sortOrder,
              is_active = @isActive
          where id = @categoryId
        '''),
        parameters: {
          'categoryId': categoryId,
          'name': trimmedName,
          'sortOrder': sortOrder,
          'isActive': isActive,
        },
      );

      if (result.affectedRows == 0) {
        throw const RequestActionException('Category was not found');
      }
      await _invalidateOverviewCache();
    });
  }

  @override
  Future<List<Map<String, Object?>>> listServices({int? categoryId}) {
    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            s.id,
            s.category_id,
            c.name as category_name,
            s.name,
            s.min_price,
            s.max_price,
            s.is_active,
            s.created_at
          from public.services s
          join public.categories c on c.id = s.category_id
          where (@categoryId::bigint is null or s.category_id = @categoryId)
          order by c.sort_order, c.name, s.name
        '''),
        parameters: {'categoryId': categoryId},
      );

      return result
          .map(
            (row) => {
              'id': row[0],
              'category_id': row[1],
              'category_name': row[2],
              'name': row[3],
              'min_price': row[4],
              'max_price': row[5],
              'is_active': row[6],
              'created_at': _formatTimestamp(row[7]),
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<int> createService({
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      throw const RequestActionException('Service name is required');
    }
    if (minPrice < 0) {
      throw const RequestActionException('Invalid minimum price');
    }
    if (maxPrice < minPrice) {
      throw const RequestActionException('Invalid maximum price');
    }

    return _database.withConnection((connection) async {
      final categoryExists = await connection.execute(
        Sql.named('''
          select 1
          from public.categories
          where id = @categoryId
        '''),
        parameters: {'categoryId': categoryId},
      );

      if (categoryExists.isEmpty) {
        throw const RequestActionException('Category was not found');
      }

      final result = await connection.execute(
        Sql.named('''
          insert into public.services (
            category_id,
            name,
            min_price,
            max_price,
            is_active
          )
          values (@categoryId, @name, @minPrice, @maxPrice, true)
          returning id
        '''),
        parameters: {
          'categoryId': categoryId,
          'name': trimmedName,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        },
      );

      final serviceId = _readInt(result.first[0]);
      await _invalidateOverviewCache();
      return serviceId;
    });
  }

  @override
  Future<void> updateService({
    required int serviceId,
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
    required bool isActive,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      throw const RequestActionException('Service name is required');
    }
    if (minPrice < 0) {
      throw const RequestActionException('Invalid minimum price');
    }
    if (maxPrice < minPrice) {
      throw const RequestActionException('Invalid maximum price');
    }

    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          update public.services
          set category_id = @categoryId,
              name = @name,
              min_price = @minPrice,
              max_price = @maxPrice,
              is_active = @isActive
          where id = @serviceId
        '''),
        parameters: {
          'serviceId': serviceId,
          'categoryId': categoryId,
          'name': trimmedName,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
          'isActive': isActive,
        },
      );

      if (result.affectedRows == 0) {
        throw const RequestActionException('Service was not found');
      }
      await _invalidateOverviewCache();
    });
  }

  @override
  Future<List<Map<String, Object?>>> listReviews({
    String? workerId,
    int? minRating,
    int? maxRating,
    bool includeHidden = true,
    int limit = 50,
  }) {
    if (minRating != null && (minRating < 1 || minRating > 5)) {
      throw const RequestActionException('Invalid minimum rating');
    }
    if (maxRating != null && (maxRating < 1 || maxRating > 5)) {
      throw const RequestActionException('Invalid maximum rating');
    }

    final boundedLimit = limit.clamp(1, 200);

    return _database.withReadConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            sr.id,
            sr.request_id,
            sr.worker_id,
            worker.full_name as worker_name,
            worker.phone as worker_phone,
            sr.customer_id,
            customer.full_name as customer_name,
            customer.phone as customer_phone,
            sr.rating,
            sr.comment,
            sr.is_hidden,
            sr.created_at,
            service.name as service_name,
            req.area
          from public.service_reviews sr
          join public.profiles worker on worker.id = sr.worker_id
          join public.profiles customer on customer.id = sr.customer_id
          join public.service_requests req on req.id = sr.request_id
          join public.services service on service.id = req.service_id
          where (@workerId::uuid is null or sr.worker_id = @workerId::uuid)
            and (@minRating::smallint is null or sr.rating >= @minRating)
            and (@maxRating::smallint is null or sr.rating <= @maxRating)
            and (@includeHidden::boolean or sr.is_hidden = false)
          order by sr.created_at desc
          limit @limit
        '''),
        parameters: {
          'workerId': workerId,
          'minRating': minRating,
          'maxRating': maxRating,
          'includeHidden': includeHidden,
          'limit': boundedLimit,
        },
      );

      return result
          .map(
            (row) => {
              'id': row[0]?.toString(),
              'request_id': row[1]?.toString(),
              'worker_id': row[2]?.toString(),
              'worker_name': row[3],
              'worker_phone': row[4],
              'customer_id': row[5]?.toString(),
              'customer_name': row[6],
              'customer_phone': row[7],
              'rating': row[8],
              'comment': row[9],
              'is_hidden': row[10],
              'created_at': _formatTimestamp(row[11]),
              'service_name': row[12],
              'area': row[13],
            },
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> updateReviewVisibility({
    required String reviewId,
    required bool isHidden,
  }) {
    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          update public.service_reviews
          set is_hidden = @isHidden
          where id = @reviewId::uuid
        '''),
        parameters: {
          'reviewId': reviewId,
          'isHidden': isHidden,
        },
      );

      if (result.affectedRows == 0) {
        throw const RequestActionException('Review was not found');
      }
    });
  }

  String _overviewCacheKey(
    String kind, {
    DateTime? from,
    DateTime? to,
  }) {
    return '$_overviewCachePrefix$kind:'
        '${from?.toUtc().toIso8601String() ?? 'all'}:'
        '${to?.toUtc().toIso8601String() ?? 'all'}';
  }

  Future<Map<String, Object?>?> _readCachedMap(String key) async {
    final cache = _cache;
    if (cache == null) {
      return null;
    }

    final raw = await cache.get(key);
    final decoded = await decodeCachedJson(raw);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }

    return null;
  }

  Future<List<Map<String, Object?>>?> _readCachedList(String key) async {
    final cache = _cache;
    if (cache == null) {
      return null;
    }

    final raw = await cache.get(key);
    final decoded = await decodeCachedJson(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
    }

    return null;
  }

  Future<void> _writeCachedMap(String key, Map<String, Object?> value) async {
    final cache = _cache;
    if (cache == null) {
      return;
    }

    await cache.set(
      key: key,
      value: encodeCachedJson(value),
      ttl: _statsCacheTtl,
    );
  }

  Future<void> _writeCachedList(
    String key,
    List<Map<String, Object?>> value,
  ) async {
    final cache = _cache;
    if (cache == null) {
      return;
    }

    await cache.set(
      key: key,
      value: encodeCachedJson(value),
      ttl: _statsCacheTtl,
    );
  }

  Future<void> _invalidateOverviewCache() async {
    final cache = _cache;
    if (cache == null) {
      return;
    }

    await cache.deleteByPrefix(_overviewCachePrefix);
    await cache.deleteByPrefix('catalog:');
  }

  Map<String, Object?> _mapAreaRow(ResultRow row) {
    return {
      'id': row[0],
      'governorate': row[1],
      'name': row[2],
      'sort_order': row[3],
      'is_active': row[4],
      'created_at': _formatTimestamp(row[5]),
    };
  }

  Map<String, Object?> _decodeJsonObject(Object? value) {
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    }
    return {};
  }

  List<Map<String, Object?>> _decodeJsonList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
    }
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
      }
    }
    return const [];
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }

  String? _formatTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value?.toString();
  }
}
