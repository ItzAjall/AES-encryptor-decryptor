import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static Database? _db;

  static Future<Database> get() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'vault.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE vault(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          username TEXT,
          password TEXT
        )
        ''');
      },
    );

    return _db!;
  }
}