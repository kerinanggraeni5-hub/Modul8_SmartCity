import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/laporan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _database;


  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }


  Future<Database> _initDatabase() async {
    final dbPath = join(
      await getDatabasesPath(),
      'smart_city.db',
    );

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        kategori TEXT NOT NULL,
        lokasi TEXT NOT NULL,
        urgensi INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Baru'
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE laporan
        ADD COLUMN urgensi INTEGER NOT NULL DEFAULT 1
      ''');

      await db.execute('''
        ALTER TABLE laporan
        ADD COLUMN status TEXT NOT NULL DEFAULT 'Baru'
      ''');
    }
  }


  Future<int> tambahLaporan(Laporan laporan) async {
    final db = await database;

    return await db.insert(
      'laporan',
      laporan.toMap(),
    );
  }

  Future<List<Laporan>> getLaporan({
    String keyword = '',
    String? status,
  }) async {
    final db = await database;

    List<String> kondisi = [];
    List<Object?> argumen = [];

    if (keyword.isNotEmpty) {
      kondisi.add('(judul LIKE ? OR lokasi LIKE ?)');
      argumen.add('%$keyword%');
      argumen.add('%$keyword%');
    }

    if (status != null && status != 'Semua') {
      kondisi.add('status = ?');
      argumen.add(status);
    }

    final hasil = await db.query(
      'laporan',
      where: kondisi.isEmpty ? null : kondisi.join(' AND '),
      whereArgs: argumen.isEmpty ? null : argumen,
      orderBy: "CASE WHEN status = 'Selesai' THEN 1 ELSE 0 END ASC, urgensi DESC, tanggal ASC",
    );

    return hasil.map((data) => Laporan.fromMap(data)).toList();
  }

  Future<int> updateLaporan(Laporan laporan) async {
    final db = await database;

    return await db.update(
      'laporan',
      laporan.toMap(),
      where: 'id = ?',
      whereArgs: [laporan.id],
    );
  }

  Future<int> hapusLaporan(int id) async {
    final db = await database;

    return await db.delete(
      'laporan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Menghitung jumlah seluruh laporan
  Future<int> getTotalLaporan() async {
    final db = await database;

    final hasil = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM laporan',
    );

    return hasil.first['total'] as int;
  }

  // Menghitung laporan yang masih aktif
  Future<int> getLaporanAktif() async {
    final db = await database;

    final hasil = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM laporan
      WHERE status IN ('Baru', 'Diproses')
    ''');

    return hasil.first['total'] as int;
  }

  // Menghitung laporan yang sudah selesai
  Future<int> getLaporanSelesai() async {
    final db = await database;

    final hasil = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM laporan
      WHERE status = 'Selesai'
    ''');

    return hasil.first['total'] as int;
  }
}
