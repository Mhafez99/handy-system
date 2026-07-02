import 'dart:io';

import 'package:postgres/postgres.dart';

/// One-off migration runner.
///
/// Usage:
///   dart run tool/apply_migration.dart <path-to-sql-file>
///
/// Reads DATABASE_URL from Backend/.env and executes the SQL file using the
/// simple query protocol (so multi-statement files with function bodies work).
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/apply_migration.dart <path-to-sql>');
    exitCode = 64;
    return;
  }

  final sqlFile = File(args.first);
  if (!sqlFile.existsSync()) {
    stderr.writeln('SQL file not found: ${args.first}');
    exitCode = 66;
    return;
  }

  final databaseUrl = _readDatabaseUrl();
  if (databaseUrl == null || databaseUrl.isEmpty) {
    stderr.writeln('DATABASE_URL not found in .env');
    exitCode = 78;
    return;
  }

  final sql = sqlFile.readAsStringSync();
  final uri = Uri.parse(databaseUrl);
  final endpoint = Endpoint(
    host: uri.host,
    port: uri.port == 0 ? 5432 : uri.port,
    database: uri.pathSegments.isEmpty
        ? 'postgres'
        : uri.pathSegments.first.replaceFirst('/', ''),
    username: uri.userInfo.isEmpty ? null : uri.userInfo.split(':').first,
    password: uri.userInfo.contains(':')
        ? uri.userInfo.split(':').skip(1).join(':')
        : null,
  );

  stdout.writeln('Connecting to ${endpoint.host}:${endpoint.port}...');
  final connection = await Connection.open(
    endpoint,
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    stdout.writeln('Applying ${sqlFile.path}...');
    await connection.execute(sql, queryMode: QueryMode.simple);
    stdout.writeln('Migration applied successfully.');
  } finally {
    await connection.close();
  }
}

String? _readDatabaseUrl() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    return Platform.environment['DATABASE_URL'];
  }

  for (final rawLine in envFile.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final separator = line.indexOf('=');
    if (separator == -1) {
      continue;
    }

    final key = line.substring(0, separator).trim();
    if (key != 'DATABASE_URL') {
      continue;
    }

    var value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }

  return Platform.environment['DATABASE_URL'];
}
