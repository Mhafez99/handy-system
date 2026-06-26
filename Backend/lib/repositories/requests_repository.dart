import 'dart:async';
import 'dart:convert';

import 'package:handy_backend/cache/cache_store.dart';
import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:handy_backend/push/notification_service.dart';
import 'package:handy_backend/storage/supabase_storage_client.dart';
import 'package:postgres/postgres.dart';

class RequestsRepository {
  RequestsRepository(
    this._database, {
    SupabaseStorageClient? storage,
    NotificationService? notifications,
    CacheStore? cache,
    Duration workerAvailableCacheTtl = const Duration(seconds: 20),
  }) : _storage = storage,
       _notifications = notifications,
       _cache = cache,
       _workerAvailableCacheTtl = workerAvailableCacheTtl;

  final Database _database;
  final SupabaseStorageClient? _storage;
  final NotificationService? _notifications;
  final CacheStore? _cache;
  final Duration _workerAvailableCacheTtl;

  static const maxRequestImages = 3;
  static const maxAvailableWorkerRequests = 100;

  Future<T> _withDb<T>(Future<T> Function(Connection connection) action) {
    return _database.withConnection(action);
  }

  Future<T> _withReadDb<T>(Future<T> Function(Connection connection) action) {
    return _database.withReadConnection(action);
  }

  Future<List<Map<String, Object?>>> listCustomerRequests(String userId) {
    return _withReadDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        select
          sr.id,
          sr.area,
          sr.status,
          sr.created_at,
          sr.final_price,
          sr.payment_method,
          s.name as service_name,
          c.name as category_name,
          (
            select count(*)::int
            from public.offers o
            where o.request_id = sr.id
          ) as offer_count
        from public.service_requests sr
        join public.services s on s.id = sr.service_id
        join public.categories c on c.id = sr.category_id
        where sr.customer_id = @userId::uuid
        order by sr.created_at desc
      '''),
      parameters: {'userId': userId},
    );

      return result.map(_mapCustomerRequestRow).toList(growable: false);
    });
  }

  Future<List<Map<String, Object?>>> listAvailableWorkerRequests(
    String userId,
  ) async {
    final cacheKey = 'worker:available:$userId';
    final cached = await _readCachedRequestList(cacheKey);
    if (cached != null) {
      return cached;
    }

    final requests = await _withReadDb((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            sr.id,
            sr.description,
            sr.area,
            sr.address,
            sr.preferred_time,
            sr.status,
            sr.created_at,
            s.name as service_name,
            c.name as category_name,
            s.min_price,
            s.max_price
          from public.profiles p
          join public.worker_profiles wp on wp.user_id = p.id
          join public.service_requests sr on sr.status in ('new', 'offered')
          join public.services s on s.id = sr.service_id
          join public.categories c on c.id = sr.category_id
          where p.id = @userId::uuid
            and p.role = 'worker'
            and p.status = 'active'
            and wp.approval_status = 'approved'
            and wp.profession = c.name
            and (
              (
                p.area_id is not null
                and sr.area_id is not null
                and p.area_id = sr.area_id
              )
              or p.area = sr.area
            )
          order by sr.created_at desc
          limit @limit
        '''),
        parameters: {
          'userId': userId,
          'limit': maxAvailableWorkerRequests,
        },
      );

      return result.map(_mapAvailableRequestRow).toList(growable: false);
    });

    await _writeCachedRequestList(cacheKey, requests);
    return requests;
  }

  Future<List<Map<String, Object?>>> listActiveWorkerRequests(
    String userId,
  ) {
    return _listWorkerRequests(
      userId,
      const ['accepted', 'on_the_way', 'in_progress'],
    );
  }

  Future<List<Map<String, Object?>>> listCompletedWorkerRequests(
    String userId,
  ) {
    return _listWorkerRequests(userId, const ['completed', 'complaint']);
  }

  Future<void> acceptOffer(String userId, String offerId) async {
    String? requestId;
    String? workerId;

    await _withDb((connection) async {
      await connection.runTx((session) async {
      final selection = await session.execute(
        Sql.named('''
          select o.request_id, o.worker_id
          from public.offers o
          join public.service_requests sr on sr.id = o.request_id
          where o.id = @offerId::uuid
            and sr.customer_id = @userId::uuid
            and sr.status in ('new', 'offered')
            and o.status = 'pending'
          for update of o, sr
        '''),
        parameters: {'offerId': offerId, 'userId': userId},
      );

      if (selection.isEmpty) {
        throw const RequestActionException(
          'Offer is not available for acceptance',
        );
      }

      requestId = selection.first[0]?.toString();
      workerId = selection.first[1]?.toString();
      if (requestId == null ||
          requestId!.isEmpty ||
          workerId == null ||
          workerId!.isEmpty) {
        throw const RequestActionException(
          'Offer is not available for acceptance',
        );
      }

      final codeResult = await session.execute(
        Sql('select lpad((floor(random() * 1000000)::int)::text, 6, \'0\')'),
      );
      final completionCode = codeResult.first[0]?.toString() ?? '000000';

      await session.execute(
        Sql.named('''
          update public.offers
          set status = case when id = @offerId::uuid then 'accepted' else 'rejected' end,
              updated_at = now()
          where request_id = @requestId::uuid
            and status = 'pending'
        '''),
        parameters: {'offerId': offerId, 'requestId': requestId},
      );

      final updated = await session.execute(
        Sql.named('''
          update public.service_requests
          set status = 'accepted',
              completion_code = @completionCode,
              updated_at = now()
          where id = @requestId::uuid
        '''),
        parameters: {
          'requestId': requestId,
          'completionCode': completionCode,
        },
      );

      if (updated.affectedRows == 0) {
        throw const RequestActionException(
          'Offer is not available for acceptance',
        );
      }
      });
    });

    final acceptedRequestId = requestId;
    final acceptedWorkerId = workerId;
    if (acceptedRequestId != null && acceptedWorkerId != null) {
      _notify(
        () => _notifications!.notifyOfferAccepted(
          requestId: acceptedRequestId,
          workerId: acceptedWorkerId,
        ),
      );
    }
  }

  Future<void> markOnTheWay(String userId, String requestId) async {
    await _updateWorkerRequestStatus(
      userId: userId,
      requestId: requestId,
      expectedStatus: 'accepted',
      nextStatus: 'on_the_way',
      errorMessage: 'Request is not available to mark on the way',
    );
    _notify(
      () => _notifications!.notifyRequestStatusChanged(
        requestId: requestId,
        status: 'on_the_way',
      ),
    );
  }

  Future<void> startWork(String userId, String requestId) async {
    await _updateWorkerRequestStatus(
      userId: userId,
      requestId: requestId,
      expectedStatus: 'on_the_way',
      nextStatus: 'in_progress',
      errorMessage: 'Request is not available to start',
    );
    _notify(
      () => _notifications!.notifyRequestStatusChanged(
        requestId: requestId,
        status: 'in_progress',
      ),
    );
  }

  Future<void> completeRequestByWorker({
    required String userId,
    required String requestId,
    required String code,
    required int finalPrice,
  }) async {
    if (finalPrice <= 0) {
      throw const RequestActionException('Final price is required');
    }

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const RequestActionException('Completion code is required');
    }

    await _withDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        update public.service_requests sr
        set status = 'completed',
            final_price = @finalPrice,
            payment_method = 'cash',
            updated_at = now()
        where sr.id = @requestId::uuid
          and sr.status = 'in_progress'
          and sr.completion_code = @code
          and exists (
            select 1
            from public.offers o
            where o.request_id = sr.id
              and o.worker_id = @userId::uuid
              and o.status = 'accepted'
          )
      '''),
      parameters: {
        'requestId': requestId,
        'userId': userId,
        'code': trimmedCode,
        'finalPrice': finalPrice,
      },
    );

    if (result.affectedRows == 0) {
      throw const RequestActionException(
        'Request is not available to complete or code is invalid',
      );
    }
    });

    _notify(
      () => _notifications!.notifyRequestStatusChanged(
        requestId: requestId,
        status: 'completed',
      ),
    );
  }

  Future<Map<String, Object?>> getCustomerRequestDetails(
    String userId,
    String requestId,
  ) {
    return _withReadDb((connection) async {
      final requestResult = await connection.execute(
      Sql.named('''
        select
          sr.id,
          sr.description,
          sr.governorate,
          sr.area,
          sr.address,
          sr.preferred_time,
          sr.status,
          sr.created_at,
          sr.completion_code,
          sr.final_price,
          sr.payment_method,
          s.name as service_name,
          s.min_price,
          s.max_price,
          c.name as category_name
        from public.service_requests sr
        join public.services s on s.id = sr.service_id
        join public.categories c on c.id = sr.category_id
        where sr.id = @requestId::uuid
          and sr.customer_id = @userId::uuid
      '''),
      parameters: {'requestId': requestId, 'userId': userId},
    );

    if (requestResult.isEmpty) {
      throw const RequestActionException('Request was not found');
    }

    final requestRow = requestResult.first;
    final offers = await _loadRequestOffers(connection, requestId);
    final reviews = await _loadRequestReviews(connection, requestId);
    final complaints = await _loadRequestComplaints(connection, requestId);

      return {
        'id': requestRow[0]?.toString(),
        'description': requestRow[1],
        'governorate': requestRow[2],
        'area': requestRow[3],
        'address': requestRow[4],
        'preferred_time': requestRow[5],
        'status': requestRow[6],
        'created_at': _formatTimestamp(requestRow[7]),
        'completion_code': requestRow[8],
        'final_price': requestRow[9],
        'payment_method': requestRow[10],
        'services': {
          'name': requestRow[11],
          'min_price': requestRow[12],
          'max_price': requestRow[13],
          'categories': {'name': requestRow[14]},
        },
        'offers': offers,
        'service_reviews': reviews,
        'service_complaints': complaints,
      };
    });
  }

  Future<String> createRequest({
    required String userId,
    required int categoryId,
    required int serviceId,
    required String description,
    required String governorate,
    required String area,
    required int areaId,
    required String address,
    required String preferredTime,
  }) async {
    final trimmedDescription = description.trim();
    final trimmedGovernorate = governorate.trim();
    final trimmedArea = area.trim();
    final trimmedAddress = address.trim();
    final trimmedPreferredTime = preferredTime.trim();

    if (trimmedDescription.length < 10) {
      throw const RequestActionException('Description is too short');
    }

    return _withDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        insert into public.service_requests (
          customer_id,
          category_id,
          service_id,
          description,
          governorate,
          area,
          area_id,
          address,
          preferred_time
        )
        select
          @userId::uuid,
          @categoryId,
          @serviceId,
          @description,
          @governorate,
          @area,
          @areaId,
          @address,
          @preferredTime
        where exists (
          select 1
          from public.profiles
          where id = @userId::uuid
            and role = 'customer'
            and status = 'active'
        )
        returning id
      '''),
      parameters: {
        'userId': userId,
        'categoryId': categoryId,
        'serviceId': serviceId,
        'description': trimmedDescription,
        'governorate': trimmedGovernorate,
        'area': trimmedArea,
        'areaId': areaId,
        'address': trimmedAddress,
        'preferredTime': trimmedPreferredTime,
      },
    );

    if (result.isEmpty) {
      throw const RequestActionException('Unable to create request');
    }

      return result.first[0]?.toString() ?? '';
    });
  }

  Future<void> createOffer({
    required String userId,
    required String requestId,
    required int price,
    required String arrivalTime,
    required String note,
  }) async {
    if (price <= 0) {
      throw const RequestActionException('Price is required');
    }

    final trimmedArrivalTime = arrivalTime.trim();
    if (trimmedArrivalTime.length < 3) {
      throw const RequestActionException('Arrival time is required');
    }

    await _withDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        insert into public.offers (
          request_id,
          worker_id,
          price,
          arrival_time,
          note
        )
        select
          @requestId::uuid,
          @userId::uuid,
          @price,
          @arrivalTime,
          @note
        where exists (
          select 1
          from public.service_requests sr
          join public.categories c on c.id = sr.category_id
          join public.profiles p on p.id = @userId::uuid
          join public.worker_profiles wp on wp.user_id = p.id
          where sr.id = @requestId::uuid
            and sr.status in ('new', 'offered')
            and p.role = 'worker'
            and p.status = 'active'
            and wp.approval_status = 'approved'
            and wp.profession = c.name
            and (
              (
                p.area_id is not null
                and sr.area_id is not null
                and p.area_id = sr.area_id
              )
              or p.area = sr.area
            )
        )
      '''),
      parameters: {
        'requestId': requestId,
        'userId': userId,
        'price': price,
        'arrivalTime': trimmedArrivalTime,
        'note': note.trim().isEmpty ? null : note.trim(),
      },
    );

    if (result.affectedRows == 0) {
      throw const RequestActionException('Offer is not available to create');
    }
    });

    await _cache?.delete('worker:available:$userId');
    _notify(() => _notifications!.notifyOfferCreated(requestId));
  }

  Future<void> cancelRequest(String userId, String requestId) {
    return _withDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        update public.service_requests
        set status = 'cancelled',
            updated_at = now()
        where id = @requestId::uuid
          and customer_id = @userId::uuid
          and status in ('new', 'offered')
      '''),
      parameters: {'requestId': requestId, 'userId': userId},
    );

    if (result.affectedRows == 0) {
      throw const RequestActionException('Request is not available to cancel');
    }
    });
  }

  Future<void> submitServiceComplaint({
    required String userId,
    required String requestId,
    required String category,
    required String description,
  }) async {
    const allowedCategories = {
      'poor_quality',
      'no_show',
      'overcharge',
      'behavior',
      'other',
    };

    if (!allowedCategories.contains(category)) {
      throw const RequestActionException('Invalid complaint category');
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription.length < 10) {
      throw const RequestActionException('Complaint description is too short');
    }

    if (trimmedDescription.length > 1000) {
      throw const RequestActionException('Complaint description is too long');
    }

    await _withDb((connection) async {
      await connection.runTx((session) async {
      final workerResult = await session.execute(
        Sql.named('''
          select o.worker_id
          from public.service_requests sr
          join public.offers o on o.request_id = sr.id
          where sr.id = @requestId::uuid
            and sr.customer_id = @userId::uuid
            and sr.status = 'completed'
            and o.status = 'accepted'
        '''),
        parameters: {'requestId': requestId, 'userId': userId},
      );

      if (workerResult.isEmpty) {
        throw const RequestActionException(
          'Request is not available for complaint',
        );
      }

      final workerId = workerResult.first[0]?.toString();
      if (workerId == null || workerId.isEmpty) {
        throw const RequestActionException(
          'Request is not available for complaint',
        );
      }

      await session.execute(
        Sql.named('''
          insert into public.service_complaints (
            request_id,
            customer_id,
            worker_id,
            category,
            description
          )
          values (
            @requestId::uuid,
            @userId::uuid,
            @workerId::uuid,
            @category,
            @description
          )
        '''),
        parameters: {
          'requestId': requestId,
          'userId': userId,
          'workerId': workerId,
          'category': category,
          'description': trimmedDescription,
        },
      );

      final updateResult = await session.execute(
        Sql.named('''
          update public.service_requests
          set status = 'complaint',
              updated_at = now()
          where id = @requestId::uuid
        '''),
        parameters: {'requestId': requestId},
      );

      if (updateResult.affectedRows == 0) {
        throw const RequestActionException(
          'Request is not available for complaint',
        );
      }
      });
    });
  }

  Future<void> submitServiceReview({
    required String userId,
    required String requestId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const RequestActionException('Rating must be between 1 and 5');
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.length > 500) {
      throw const RequestActionException('Review comment is too long');
    }

    await _withDb((connection) async {
      final workerResult = await connection.execute(
      Sql.named('''
        select o.worker_id
        from public.service_requests sr
        join public.offers o on o.request_id = sr.id
        where sr.id = @requestId::uuid
          and sr.customer_id = @userId::uuid
          and sr.status = 'completed'
          and o.status = 'accepted'
      '''),
      parameters: {'requestId': requestId, 'userId': userId},
    );

    if (workerResult.isEmpty) {
      throw const RequestActionException('Request is not available for review');
    }

    final workerId = workerResult.first[0]?.toString();
    if (workerId == null || workerId.isEmpty) {
      throw const RequestActionException('Request is not available for review');
    }

    final insertResult = await connection.execute(
      Sql.named('''
        insert into public.service_reviews (
          request_id,
          customer_id,
          worker_id,
          rating,
          comment
        )
        values (
          @requestId::uuid,
          @userId::uuid,
          @workerId::uuid,
          @rating,
          @comment
        )
      '''),
      parameters: {
        'requestId': requestId,
        'userId': userId,
        'workerId': workerId,
        'rating': rating,
        'comment': trimmedComment,
      },
    );

    if (insertResult.affectedRows == 0) {
      throw const RequestActionException('Request is not available for review');
    }
    });
  }

  Future<List<Map<String, Object?>>> listRequestImages(
    String userId,
    String requestId,
  ) async {
    final storage = _requireStorage();
    final rows = await _loadAccessibleRequestImages(userId, requestId);
    final images = <Map<String, Object?>>[];

    for (final row in rows) {
      final storagePath = row['storage_path'] as String? ?? '';
      if (storagePath.isEmpty) {
        continue;
      }

      images.add({
        'id': row['id'],
        'sort_order': row['sort_order'],
        'url': await storage.createSignedReadUrl(objectPath: storagePath),
      });
    }

    return images;
  }

  Future<List<Map<String, Object?>>> createRequestImageUploadUrls({
    required String userId,
    required String requestId,
    required List<Map<String, Object?>> images,
  }) async {
    if (images.isEmpty) {
      throw const RequestActionException('At least one image is required');
    }

    final storage = _requireStorage();

    return _withDb((connection) async {
      final ownershipResult = await connection.execute(
      Sql.named('''
        select 1
        from public.service_requests sr
        where sr.id = @requestId::uuid
          and sr.customer_id = @userId::uuid
      '''),
      parameters: {'requestId': requestId, 'userId': userId},
    );

    if (ownershipResult.isEmpty) {
      throw const RequestActionException('Request was not found');
    }

    final countResult = await connection.execute(
      Sql.named('''
        select count(*)::int
        from public.request_images
        where request_id = @requestId::uuid
      '''),
      parameters: {'requestId': requestId},
    );

    final existingCount = countResult.first[0] as int? ?? 0;
    if (existingCount + images.length > maxRequestImages) {
      throw const RequestActionException('Too many request images');
    }

    final uploads = <Map<String, Object?>>[];
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    for (final image in images) {
      final contentType = image['content_type'];
      final rawSortOrder = image['sort_order'];

      if (contentType is! String || rawSortOrder == null) {
        throw const RequestActionException('Invalid image payload');
      }

      const allowedContentTypes = {
        'image/jpeg',
        'image/png',
        'image/webp',
      };

      if (!allowedContentTypes.contains(contentType)) {
        throw const RequestActionException('Invalid image content type');
      }

      final sortOrder = switch (rawSortOrder) {
        final int value => value,
        final num value => value.toInt(),
        _ => throw const RequestActionException('Invalid image payload'),
      };

      if (sortOrder < 0 || sortOrder >= maxRequestImages) {
        throw const RequestActionException('Invalid image sort order');
      }

      final extension = _extensionForContentType(contentType);
      final storagePath =
          '$userId/$requestId/${timestamp}_${sortOrder}$extension';
      final signedUpload = await storage.createSignedUploadUrl(
        objectPath: storagePath,
      );

      final insertResult = await connection.execute(
        Sql.named('''
          insert into public.request_images (
            request_id,
            storage_path,
            sort_order
          )
          values (
            @requestId::uuid,
            @storagePath,
            @sortOrder
          )
          returning id
        '''),
        parameters: {
          'requestId': requestId,
          'storagePath': storagePath,
          'sortOrder': sortOrder,
        },
      );

      if (insertResult.isEmpty) {
        throw const RequestActionException('Unable to register request image');
      }

      uploads.add({
        'id': insertResult.first[0]?.toString(),
        'storage_path': storagePath,
        'sort_order': sortOrder,
        'upload_url': signedUpload.uploadUrl,
        'token': signedUpload.token,
        'content_type': contentType,
      });
    }

      return uploads;
    });
  }

  SupabaseStorageClient _requireStorage() {
    final storage = _storage;
    if (storage == null) {
      throw const RequestActionException('Image storage is not configured');
    }

    return storage;
  }

  String _extensionForContentType(String contentType) {
    return switch (contentType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
  }

  Future<List<Map<String, Object?>>> _loadAccessibleRequestImages(
    String userId,
    String requestId,
  ) {
    return _withReadDb((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select ri.id, ri.storage_path, ri.sort_order
        from public.request_images ri
        join public.service_requests sr on sr.id = ri.request_id
        where ri.request_id = @requestId::uuid
          and (
            sr.customer_id = @userId::uuid
            or exists (
              select 1
              from public.profiles p
              join public.worker_profiles wp on wp.user_id = p.id
              join public.categories c on c.id = sr.category_id
              where p.id = @userId::uuid
                and sr.status in ('new', 'offered')
                and p.role = 'worker'
                and p.status = 'active'
                and wp.approval_status = 'approved'
                and wp.profession = c.name
                and (
                  (
                    p.area_id is not null
                    and sr.area_id is not null
                    and p.area_id = sr.area_id
                  )
                  or p.area = sr.area
                )
            )
            or exists (
              select 1
              from public.offers o
              where o.request_id = sr.id
                and o.worker_id = @userId::uuid
                and o.status = 'accepted'
            )
          )
        order by ri.sort_order asc
      '''),
      parameters: {'requestId': requestId, 'userId': userId},
    );

    if (result.isEmpty) {
      final existsResult = await connection.execute(
        Sql.named('''
          select 1
          from public.request_images
          where request_id = @requestId::uuid
        '''),
        parameters: {'requestId': requestId},
      );

      if (existsResult.isNotEmpty) {
        throw const RequestActionException('Request images are not accessible');
      }
    }

    return result
        .map(
          (row) => {
            'id': row[0]?.toString(),
            'storage_path': row[1],
            'sort_order': row[2],
          },
        )
        .toList(growable: false);
    });
  }

  Future<void> _updateWorkerRequestStatus({
    required String userId,
    required String requestId,
    required String expectedStatus,
    required String nextStatus,
    required String errorMessage,
  }) {
    return _withDb((connection) async {
      final result = await connection.execute(
      Sql.named('''
        update public.service_requests sr
        set status = @nextStatus,
            updated_at = now()
        where sr.id = @requestId::uuid
          and sr.status = @expectedStatus
          and exists (
            select 1
            from public.offers o
            where o.request_id = sr.id
              and o.worker_id = @userId::uuid
              and o.status = 'accepted'
          )
      '''),
      parameters: {
        'requestId': requestId,
        'userId': userId,
        'expectedStatus': expectedStatus,
        'nextStatus': nextStatus,
      },
    );

    if (result.affectedRows == 0) {
      throw RequestActionException(errorMessage);
    }
    });
  }

  Future<List<Map<String, Object?>>> _loadRequestOffers(
    Connection connection,
    String requestId,
  ) async {
    final result = await connection.execute(
      Sql.named('''
        select
          o.id,
          o.worker_id,
          o.price,
          o.arrival_time,
          o.note,
          o.status,
          o.created_at,
          p.full_name,
          p.phone
        from public.offers o
        join public.profiles p on p.id = o.worker_id
        where o.request_id = @requestId::uuid
        order by o.created_at asc
      '''),
      parameters: {'requestId': requestId},
    );

    return result
        .map(
          (row) => {
            'id': row[0]?.toString(),
            'worker_id': row[1]?.toString(),
            'price': row[2],
            'arrival_time': row[3],
            'note': row[4],
            'status': row[5],
            'created_at': _formatTimestamp(row[6]),
            'worker': {
              'full_name': row[7],
              'phone': row[8],
            },
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _loadRequestReviews(
    Connection connection,
    String requestId,
  ) async {
    final result = await connection.execute(
      Sql.named('''
        select id, rating, comment, created_at
        from public.service_reviews
        where request_id = @requestId::uuid
        order by created_at desc
        limit 1
      '''),
      parameters: {'requestId': requestId},
    );

    return result
        .map(
          (row) => {
            'id': row[0]?.toString(),
            'rating': row[1],
            'comment': row[2],
            'created_at': _formatTimestamp(row[3]),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _loadRequestComplaints(
    Connection connection,
    String requestId,
  ) async {
    final result = await connection.execute(
      Sql.named('''
        select id, category, description, status, created_at
        from public.service_complaints
        where request_id = @requestId::uuid
        order by created_at desc
        limit 1
      '''),
      parameters: {'requestId': requestId},
    );

    return result
        .map(
          (row) => {
            'id': row[0]?.toString(),
            'category': row[1],
            'description': row[2],
            'status': row[3],
            'created_at': _formatTimestamp(row[4]),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _listWorkerRequests(
    String userId,
    List<String> statuses,
  ) {
    return _withReadDb((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select
            sr.id,
            sr.description,
            sr.governorate,
          sr.area,
          sr.address,
          sr.preferred_time,
          sr.status,
          sr.created_at,
          sr.final_price,
          sr.payment_method,
          s.name as service_name,
          c.name as category_name,
          cust.full_name as customer_name,
          cust.phone as customer_phone,
          cust.address as customer_address,
          o.price as accepted_price,
          o.arrival_time,
          o.worker_id,
          rev.id as review_id,
          rev.rating,
          rev.comment,
          rev.created_at as review_created_at
        from public.service_requests sr
        join public.services s on s.id = sr.service_id
        join public.categories c on c.id = sr.category_id
        join public.profiles cust on cust.id = sr.customer_id
        join public.offers o
          on o.request_id = sr.id
         and o.worker_id = @userId::uuid
         and o.status = 'accepted'
        left join lateral (
          select r.id, r.rating, r.comment, r.created_at
          from public.service_reviews r
          where r.request_id = sr.id
          order by r.created_at desc
          limit 1
        ) rev on true
        where sr.status = any(@statuses::text[])
        order by sr.created_at desc
      '''),
      parameters: {
        'userId': userId,
        'statuses': statuses,
      },
    );

      return result.map(_mapAcceptedWorkerRequestRow).toList(growable: false);
    });
  }

  Future<List<Map<String, Object?>>?> _readCachedRequestList(String key) async {
    final cache = _cache;
    if (cache == null) {
      return null;
    }

    final raw = await cache.get(key);
    final decoded = await decodeCachedJson(raw);
    if (decoded is! List) {
      return null;
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  Future<void> _writeCachedRequestList(
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
      ttl: _workerAvailableCacheTtl,
    );
  }

  Map<String, Object?> _mapCustomerRequestRow(ResultRow row) {
    final createdAt = row[3];
    return {
      'id': row[0]?.toString(),
      'area': row[1],
      'status': row[2],
      'created_at': _formatTimestamp(createdAt),
      'final_price': row[4],
      'payment_method': row[5],
      'offer_count': row[8],
      'services': {
        'name': row[6],
        'categories': {'name': row[7]},
      },
      'offers': <Map<String, Object?>>[],
    };
  }

  Map<String, Object?> _mapAvailableRequestRow(ResultRow row) {
    return {
      'id': row[0]?.toString(),
      'description': row[1],
      'area': row[2],
      'address': row[3],
      'preferred_time': row[4],
      'status': row[5],
      'created_at': _formatTimestamp(row[6]),
      'services': {
        'name': row[7],
        'min_price': row[9],
        'max_price': row[10],
        'categories': {'name': row[8]},
      },
    };
  }

  Map<String, Object?> _mapAcceptedWorkerRequestRow(ResultRow row) {
    final reviewId = row[18]?.toString();
    final reviews = reviewId == null || reviewId.isEmpty
        ? <Map<String, Object?>>[]
        : [
            {
              'id': reviewId,
              'rating': row[19],
              'comment': row[20],
              'created_at': _formatTimestamp(row[21]),
            },
          ];

    return {
      'id': row[0]?.toString(),
      'description': row[1],
      'governorate': row[2],
      'area': row[3],
      'address': row[4],
      'preferred_time': row[5],
      'status': row[6],
      'created_at': _formatTimestamp(row[7]),
      'final_price': row[8],
      'payment_method': row[9],
      'services': {
        'name': row[10],
        'categories': {'name': row[11]},
      },
      'customer': {
        'full_name': row[12],
        'phone': row[13],
        'address': row[14],
      },
      'offers': [
        {
          'price': row[15],
          'arrival_time': row[16],
          'status': 'accepted',
          'worker_id': row[17]?.toString(),
        },
      ],
      'service_reviews': reviews,
    };
  }

  String? _formatTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value?.toString();
  }

  void _notify(Future<void> Function() action) {
    final notifications = _notifications;
    if (notifications == null) {
      return;
    }

    unawaited(
      action().catchError((_) {
        return;
      }),
    );
  }
}
