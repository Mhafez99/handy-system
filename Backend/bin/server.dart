import 'dart:io';

import 'package:handy_backend/bootstrap/handy_app.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final environment = _loadEnvironment();
  final config = AppConfig.fromEnvironment(environment);
  final app = await buildHandyApplication(config);

  final server = await shelf_io.serve(
    app.handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  stdout.writeln(
    'Handy API listening on http://${server.address.host}:${server.port}',
  );
  if (config.hasReadReplica) {
    stdout.writeln('Read replica enabled');
  }
  if (app.cacheStore != null) {
    stdout.writeln('Redis cache enabled');
  }
  if (app.rateLimitStore != null) {
    stdout.writeln('Rate limiting enabled');
  }

  _watchShutdownSignal(ProcessSignal.sigint, app);
  // SIGTERM is not supported on Windows; guard so startup doesn't crash.
  if (!Platform.isWindows) {
    _watchShutdownSignal(ProcessSignal.sigterm, app);
  }
}

void _watchShutdownSignal(ProcessSignal signal, HandyApplication app) {
  try {
    signal.watch().listen((_) async {
      await app.close();
      exit(0);
    });
  } on SignalException {
    // Signal not supported on this platform; ignore.
  }
}

Map<String, String> _loadEnvironment() {
  final environment = Map<String, String>.from(Platform.environment);
  final file = File('.env');

  if (!file.existsSync()) {
    return environment;
  }

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final key = trimmed.substring(0, separatorIndex).trim();
    final value = _unquote(trimmed.substring(separatorIndex + 1).trim());
    if (key.isNotEmpty) {
      environment[key] = value;
    }
  }

  return environment;
}

String _unquote(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}
