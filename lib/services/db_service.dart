import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inspection.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inspections.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tbl_inspections(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            property_name TEXT NOT NULL,
            description TEXT NOT NULL,
            rating TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            date_created TEXT NOT NULL,
            photos TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Inspection>> getAllInspections() async {
    final db = await database;
    final maps = await db.query(
      'tbl_inspections',
      orderBy: 'date_created DESC',
    );
    return maps.map((e) => Inspection.fromMap(e)).toList();
  }

  Future<int> insertInspection(Inspection inspection) async {
    final db = await database;
    final map = inspection.toMap();
    map.remove('id'); // Let SQLite auto-generate ID
    return await db.insert('tbl_inspections', map);
  }
  Future<Inspection?> getInspectionById(int id) async {
  final db = await database;
  final maps = await db.query(
    'tbl_inspections',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    return Inspection.fromMap(maps.first);
  }
  return null;
}

  Future<int> updateInspection(Inspection inspection) async {
    if (inspection.id == null) return 0;

    final db = await database;
    return await db.update(
      'tbl_inspections',
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  Future<int> deleteInspection(int id) async {
    final db = await database;
    return await db.delete(
      'tbl_inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
