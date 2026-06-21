import 'package:postgres/postgres.dart';

class Database {
  Database(this._connectionString);

  final String _connectionString;
  Connection? _connection;

  Future<Connection> connect() async {
    final existing = _connection;
    if (existing != null) {
      return existing;
    }

    final uri = Uri.parse(_connectionString);
    final port = uri.port == 0 ? 5432 : uri.port;
    final database = uri.pathSegments.isEmpty
        ? 'postgres'
        : uri.pathSegments.first.replaceFirst('/', '');

    _connection = await Connection.open(
      Endpoint(
        host: uri.host,
        port: port,
        database: database,
        username: uri.userInfo.isEmpty ? null : uri.userInfo.split(':').first,
        password: uri.userInfo.contains(':')
            ? uri.userInfo.split(':').skip(1).join(':')
            : null,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    return _connection!;
  }

  Future<void> close() async {
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      await connection.close();
    }
  }
}
