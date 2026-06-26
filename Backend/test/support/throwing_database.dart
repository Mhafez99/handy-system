import 'package:handy_backend/db/database.dart';

class ThrowingDatabase extends Database {
  ThrowingDatabase() : super(writeUrl: 'postgresql://localhost/postgres');
}
