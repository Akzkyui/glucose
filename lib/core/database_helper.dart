import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/glucose_record.dart';

/// SQLite 数据库工具类 (单例模式)
class DatabaseHelper {
  // 单例实例
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('glucose_app.db');
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 升级表结构：无缝追加新增的模型字段
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE glucose_records ADD COLUMN baselineSteps INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // 创建表结构
  Future<void> _createDB(Database db, int version) async {
    // 创建血糖记录表
    await db.execute('''
      CREATE TABLE glucose_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        glucoseValue REAL NOT NULL,
        timeTag INTEGER NOT NULL,
        baselineSteps INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ---------------- CRUD operations for glucose_records ----------------

  /// 插入一条血糖记录
  Future<int> insertRecord(GlucoseRecord record) async {
    try {
      final db = await instance.database;
      return await db.insert(
        'glucose_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error inserting record into database: $e');
      return -1;
    }
  }

  /// 获取所有血糖记录 (按时间倒序排列)
  Future<List<GlucoseRecord>> getAllRecords() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'glucose_records',
        orderBy: 'timestamp DESC',
      );
      return result.map((json) => GlucoseRecord.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching records from database: $e');
      return [];
    }
  }

  /// 获取特定日期范围内的血糖记录
  Future<List<GlucoseRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await instance.database;
      // 保证 end 只比较到当天末尾
      final result = await db.query(
        'glucose_records',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'timestamp DESC',
      );
      return result.map((json) => GlucoseRecord.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching records by date range: $e');
      return [];
    }
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
