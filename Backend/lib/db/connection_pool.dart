import 'dart:async';
import 'dart:collection';

import 'package:postgres/postgres.dart';

class ConnectionPool {
  ConnectionPool({
    required Endpoint endpoint,
    required ConnectionSettings settings,
    int maxSize = 25,
    Duration acquireTimeout = const Duration(seconds: 30),
  }) : _endpoint = endpoint,
       _settings = settings,
       _maxSize = maxSize,
       _acquireTimeout = acquireTimeout;

  final Endpoint _endpoint;
  final ConnectionSettings _settings;
  final int _maxSize;
  final Duration _acquireTimeout;
  final Queue<Connection> _available = Queue<Connection>();
  final Queue<Completer<Connection>> _waiters = Queue<Completer<Connection>>();
  int _created = 0;
  bool _closed = false;

  factory ConnectionPool.fromUri(
    String connectionString, {
    int maxSize = 25,
    Duration acquireTimeout = const Duration(seconds: 30),
  }) {
    final uri = Uri.parse(connectionString);
    final port = uri.port == 0 ? 5432 : uri.port;
    final database = uri.pathSegments.isEmpty
        ? 'postgres'
        : uri.pathSegments.first.replaceFirst('/', '');

    return ConnectionPool(
      endpoint: Endpoint(
        host: uri.host,
        port: port,
        database: database,
        username: uri.userInfo.isEmpty ? null : uri.userInfo.split(':').first,
        password: uri.userInfo.contains(':')
            ? uri.userInfo.split(':').skip(1).join(':')
            : null,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
      maxSize: maxSize,
      acquireTimeout: acquireTimeout,
    );
  }

  int get maxSize => _maxSize;

  int get activeConnections => _created;

  Future<void> prewarm({int? count}) async {
    final target = (count ?? _maxSize).clamp(1, _maxSize);
    final connections = <Connection>[];

    try {
      for (var index = 0; index < target; index++) {
        connections.add(await acquire());
      }
    } finally {
      for (final connection in connections) {
        release(connection);
      }
    }
  }

  Future<Connection> acquire() async {
    if (_closed) {
      throw StateError('Connection pool is closed');
    }

    while (_available.isNotEmpty) {
      final connection = _available.removeFirst();
      if (connection.isOpen) {
        return connection;
      }
      _created--;
    }

    if (_created < _maxSize) {
      _created++;
      try {
        return await Connection.open(
          _endpoint,
          settings: _settings,
        );
      } catch (error) {
        _created--;
        rethrow;
      }
    }

    final waiter = Completer<Connection>();
    _waiters.add(waiter);

    return waiter.future.timeout(
      _acquireTimeout,
      onTimeout: () {
        _waiters.remove(waiter);
        throw TimeoutException(
          'Timed out waiting for a database connection',
          _acquireTimeout,
        );
      },
    );
  }

  void release(Connection connection) {
    if (_closed) {
      if (connection.isOpen) {
        unawaited(connection.close());
      }
      return;
    }

    if (!connection.isOpen) {
      _created--;
      _grantNextWaiter();
      return;
    }

    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(connection);
      return;
    }

    _available.add(connection);
  }

  Future<void> close() async {
    _closed = true;

    for (final waiter in _waiters) {
      waiter.completeError(StateError('Connection pool is closed'));
    }
    _waiters.clear();

    final connections = _available.toList(growable: false);
    _available.clear();

    for (final connection in connections) {
      if (connection.isOpen) {
        await connection.close();
      }
    }

    _created = 0;
  }

  Future<bool> ping() async {
    final connection = await acquire();
    try {
      final result = await connection.execute(Sql('select 1'));
      return result.isNotEmpty;
    } finally {
      release(connection);
    }
  }

  void _grantNextWaiter() {
    if (_waiters.isEmpty || _closed) {
      return;
    }

    if (_created < _maxSize) {
      unawaited(
        acquire().then(_waiters.removeFirst().complete).catchError(
          (Object error, StackTrace stackTrace) {
            if (_waiters.isNotEmpty) {
              _waiters.removeFirst().completeError(error, stackTrace);
            }
          },
        ),
      );
    }
  }
}
