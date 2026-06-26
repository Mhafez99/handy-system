import 'package:handy_backend/db/connection_pool.dart';
import 'package:postgres/postgres.dart';

class Database {
  Database({
    required String writeUrl,
    String? readUrl,
    int poolSize = 25,
    int? readPoolSize,
    Duration acquireTimeout = const Duration(seconds: 30),
    bool prewarmPools = true,
  }) : _writePool = ConnectionPool.fromUri(
         writeUrl,
         maxSize: poolSize,
         acquireTimeout: acquireTimeout,
       ),
       _readPool = readUrl == null || readUrl == writeUrl
           ? null
           : ConnectionPool.fromUri(
               readUrl,
               maxSize: readPoolSize ?? poolSize,
               acquireTimeout: acquireTimeout,
             ),
       _prewarmPools = prewarmPools;

  final ConnectionPool _writePool;
  final ConnectionPool? _readPool;
  final bool _prewarmPools;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_prewarmPools) {
      await _writePool.prewarm(count: (_writePool.maxSize / 2).ceil());
      await _readPool?.prewarm(count: (_readPool!.maxSize / 2).ceil());
    }

    _initialized = true;
  }

  Future<T> withConnection<T>(
    Future<T> Function(Connection connection) action,
  ) {
    return _withPool(_writePool, action);
  }

  Future<T> withReadConnection<T>(
    Future<T> Function(Connection connection) action,
  ) {
    final readPool = _readPool;
    if (readPool == null) {
      return withConnection(action);
    }

    return _withPool(readPool, action);
  }

  Future<bool> pingWritePool() => _writePool.ping();

  Future<bool> pingReadPool() async {
    final readPool = _readPool;
    if (readPool == null) {
      return pingWritePool();
    }

    return readPool.ping();
  }

  Future<void> close() async {
    await _writePool.close();
    await _readPool?.close();
  }

  Future<T> _withPool<T>(
    ConnectionPool pool,
    Future<T> Function(Connection connection) action,
  ) async {
    final connection = await pool.acquire();
    try {
      return await action(connection);
    } finally {
      pool.release(connection);
    }
  }
}
