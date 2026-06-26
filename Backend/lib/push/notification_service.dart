import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/push/fcm_client.dart';
import 'package:handy_backend/repositories/device_tokens_repository.dart';
import 'package:postgres/postgres.dart';

class NotificationService {
  NotificationService({
    required DeviceTokensRepository deviceTokens,
    required Database database,
    FcmClient? fcm,
  }) : _deviceTokens = deviceTokens,
       _database = database,
       _fcm = fcm;

  final DeviceTokensRepository _deviceTokens;
  final Database _database;
  final FcmClient? _fcm;

  Future<void> notifyOfferCreated(String requestId) async {
    final customerId = await _loadRequestCustomerId(requestId);
    if (customerId == null) {
      return;
    }

    await _sendToUser(
      userId: customerId,
      title: 'عرض جديد',
      body: 'وصلك عرض جديد على طلبك.',
      data: {
        'type': 'offer_created',
        'request_id': requestId,
      },
    );
  }

  Future<void> notifyOfferAccepted({
    required String requestId,
    required String workerId,
  }) async {
    await _sendToUser(
      userId: workerId,
      title: 'تم قبول عرضك',
      body: 'العميل قبل عرضك. تابع تفاصيل الطلب.',
      data: {
        'type': 'offer_accepted',
        'request_id': requestId,
      },
    );
  }

  Future<void> notifyRequestStatusChanged({
    required String requestId,
    required String status,
  }) async {
    final customerId = await _loadRequestCustomerId(requestId);
    if (customerId == null) {
      return;
    }

    final body = switch (status) {
      'on_the_way' => 'الصنايعي في الطريق إليك.',
      'in_progress' => 'بدأ الصنايعي تنفيذ الشغل.',
      'completed' => 'تم إتمام الطلب.',
      _ => 'تم تحديث حالة الطلب.',
    };

    await _sendToUser(
      userId: customerId,
      title: 'تحديث الطلب',
      body: body,
      data: {
        'type': 'request_status',
        'request_id': requestId,
        'status': status,
      },
    );
  }

  Future<void> _sendToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    final fcm = _fcm;
    if (fcm == null) {
      return;
    }

    final tokens = await _deviceTokens.listTokensForUser(userId);
    if (tokens.isEmpty) {
      return;
    }

    final message = FcmMessage(title: title, body: body, data: data);

    for (final token in tokens) {
      final result = await fcm.send(token: token, message: message);
      if (result == FcmSendResult.invalidToken) {
        await _deviceTokens.deleteTokenEverywhere(token);
      }
    }
  }

  Future<String?> _loadRequestCustomerId(String requestId) {
    return _database.withConnection((connection) async {
      final result = await connection.execute(
        Sql.named('''
          select customer_id
          from public.service_requests
          where id = @requestId::uuid
        '''),
        parameters: {'requestId': requestId},
      );

      if (result.isEmpty) {
        return null;
      }

      return result.first[0]?.toString();
    });
  }
}
