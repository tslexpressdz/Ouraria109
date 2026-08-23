import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/repair_order.dart';
import '../models/debt.dart';

/// طبقة الوصول لقاعدة البيانات المحلية (SQLite)
/// جميع البيانات تُخزَّن محلياً على الهاتف، ثم تُرفَع نسخة منها إلى Google Sheets
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'phone_repair_manager.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE repair_orders (
        id TEXT PRIMARY KEY,
        customerName TEXT,
        customerPhone TEXT,
        deviceType TEXT,
        partName TEXT,
        purchasePrice REAL,
        sellPrice REAL,
        deposit REAL,
        status TEXT,
        createdAt TEXT,
        deliveredAt TEXT,
        archived INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        type TEXT,
        personName TEXT,
        amount REAL,
        note TEXT,
        createdAt TEXT,
        paid INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE delivery_persons (
        id TEXT PRIMARY KEY,
        name TEXT,
        amountDue REAL,
        createdAt TEXT,
        paid INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE weekly_reports (
        id TEXT PRIMARY KEY,
        weekStart TEXT,
        weekEnd TEXT,
        totalCollected REAL,
        myProfitCollected REAL,
        ownerProfitCollected REAL,
        totalCustomerDebt REAL,
        totalSupplierDebt REAL,
        archivedAt TEXT
      )
    ''');
  }

  // ---------------- طلبات الصيانة ----------------

  Future<void> insertOrder(RepairOrder order) async {
    final db = await database;
    await db.insert(
      'repair_orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOrder(RepairOrder order) async {
    final db = await database;
    await db.update(
      'repair_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<List<RepairOrder>> getActiveOrders() async {
    final db = await database;
    final result = await db.query(
      'repair_orders',
      where: 'archived = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => RepairOrder.fromMap(e)).toList();
  }

  Future<void> archiveAllDeliveredOrders() async {
    final db = await database;
    await db.update(
      'repair_orders',
      {'archived': 1},
      where: 'status = ?',
      whereArgs: [OrderStatus.delivered.name],
    );
  }

  Future<void> deleteOrder(String id) async {
    final db = await database;
    await db.delete('repair_orders', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- الديون ----------------

  Future<void> insertDebt(Debt debt) async {
    final db = await database;
    await db.insert(
      'debts',
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDebt(Debt debt) async {
    final db = await database;
    await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<List<Debt>> getDebtsByType(DebtType type) async {
    final db = await database;
    final result = await db.query(
      'debts',
      where: 'type = ? AND paid = ?',
      whereArgs: [type.name, 0],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => Debt.fromMap(e)).toList();
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- عمال التوصيل ----------------

  Future<void> insertDeliveryPerson(DeliveryPerson person) async {
    final db = await database;
    await db.insert(
      'delivery_persons',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    final db = await database;
    await db.update(
      'delivery_persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<List<DeliveryPerson>> getUnpaidDeliveryPersons() async {
    final db = await database;
    final result = await db.query(
      'delivery_persons',
      where: 'paid = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => DeliveryPerson.fromMap(e)).toList();
  }

  /// كل عمال التوصيل (مدفوعين وغير مدفوعين) — تُستخدم لحساب التكلفة
  /// الإجمالية لأجر التوصيل بشكل دائم في حساب الفائدة، حتى لو تم الدفع
  Future<List<DeliveryPerson>> getAllDeliveryPersons() async {
    final db = await database;
    final result = await db.query('delivery_persons', orderBy: 'createdAt DESC');
    return result.map((e) => DeliveryPerson.fromMap(e)).toList();
  }

  // ---------------- التقارير الأسبوعية ----------------

  Future<void> insertWeeklyReport(WeeklyReport report) async {
    final db = await database;
    await db.insert(
      'weekly_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeeklyReport>> getAllWeeklyReports() async {
    final db = await database;
    final result = await db.query('weekly_reports', orderBy: 'weekStart DESC');
    return result.map((e) => WeeklyReport.fromMap(e)).toList();
  }
}
