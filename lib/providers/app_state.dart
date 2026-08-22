import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/repair_order.dart';
import '../models/debt.dart';
import '../services/sheets_service.dart';

const _uuid = Uuid();

/// الحالة العامة للتطبيق: تحمّل البيانات من قاعدة البيانات المحلية،
/// وتزامنها مع Google Sheets عند كل تعديل
class AppState extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<RepairOrder> orders = [];
  List<Debt> supplierDebts = [];
  List<Debt> customerDebts = [];
  List<DeliveryPerson> deliveryPersons = [];
  List<WeeklyReport> weeklyReports = [];

  bool isLoading = true;

  AppState() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading = true;
    notifyListeners();

    orders = await _db.getActiveOrders();
    supplierDebts = await _db.getDebtsByType(DebtType.supplier);
    customerDebts = await _db.getDebtsByType(DebtType.customer);
    deliveryPersons = await _db.getUnpaidDeliveryPersons();
    weeklyReports = await _db.getAllWeeklyReports();

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _loadAll();

  // ---------------- عمليات الصيانة ----------------

  Future<void> addOrder({
    required String customerName,
    required String customerPhone,
    required String deviceType,
    required String partName,
    required double purchasePrice,
    required double sellPrice,
    required double deposit,
  }) async {
    final order = RepairOrder(
      id: _uuid.v4(),
      customerName: customerName,
      customerPhone: customerPhone,
      deviceType: deviceType,
      partName: partName,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      deposit: deposit,
      createdAt: DateTime.now(),
    );
    await _db.insertOrder(order);

    // إذا بقي مبلغ على الزبون، يُضاف تلقائياً إلى ديون الزبائن
    if (order.remainingAmount > 0) {
      // لا ننشئ سجل دين منفصل هنا لأن شاشة الديون تعرض المتبقي من
      // طلبات الصيانة مباشرة + الديون اليدوية (انظر debts_screen.dart)
    }

    await SheetsService.sendOrder(order);
    await refresh();
  }

  Future<void> updateOrderStatus(RepairOrder order, OrderStatus newStatus) async {
    order.status = newStatus;
    if (newStatus == OrderStatus.delivered) {
      order.deposit = order.sellPrice; // المبلغ المتبقي يصبح صفراً
      order.deliveredAt = DateTime.now();
    }
    await _db.updateOrder(order);
    await SheetsService.sendOrder(order);
    await refresh();
  }

  Future<void> deleteOrder(String id) async {
    await _db.deleteOrder(id);
    await refresh();
  }

  // ---------------- الديون ----------------

  Future<void> addDebt({
    required DebtType type,
    required String personName,
    required double amount,
    String note = '',
  }) async {
    final debt = Debt(
      id: _uuid.v4(),
      type: type,
      personName: personName,
      amount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    await _db.insertDebt(debt);
    await SheetsService.sendDebt(debt);
    await refresh();
  }

  Future<void> markDebtPaid(Debt debt) async {
    debt.paid = true;
    await _db.updateDebt(debt);
    await SheetsService.sendDebt(debt);
    await refresh();
  }

  Future<void> deleteDebt(String id) async {
    await _db.deleteDebt(id);
    await refresh();
  }

  // ---------------- عمال التوصيل ----------------

  Future<void> addDeliveryPerson(String name, double amountDue) async {
    final person = DeliveryPerson(
      id: _uuid.v4(),
      name: name,
      amountDue: amountDue,
      createdAt: DateTime.now(),
    );
    await _db.insertDeliveryPerson(person);
    await refresh();
  }

  Future<void> markDeliveryPersonPaid(DeliveryPerson person) async {
    person.paid = true;
    person.amountDue = 0;
    await _db.updateDeliveryPerson(person);
    await refresh();
  }

  // ---------------- حسابات مجمّعة (تُستخدم في شاشة الغلق الأسبوعي) ----------------

  /// مجموع الكريدي المتبقي في السوق عند الزبائن (من طلبات الصيانة + الديون اليدوية)
  double get totalCustomerDebt {
    final fromOrders =
        orders.fold<double>(0, (sum, o) => sum + o.remainingAmount);
    final fromManual =
        customerDebts.fold<double>(0, (sum, d) => sum + d.amount);
    return fromOrders + fromManual;
  }

  /// مجموع الديون التي على المحل تجاه الموردين
  double get totalSupplierDebt =>
      supplierDebts.fold<double>(0, (sum, d) => sum + d.amount);

  /// مجموع أجر التوصيل المستحق (غير المدفوع بعد)
  double get totalDeliveryDue =>
      deliveryPersons.fold<double>(0, (sum, p) => sum + p.amountDue);

  /// الطلبات المُسلَّمة والمقبوضة بالكامل (تدخل في حساب الأسبوع الحالي)
  List<RepairOrder> get deliveredThisWeek =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  double get totalCollectedThisWeek =>
      deliveredThisWeek.fold<double>(0, (sum, o) => sum + o.sellPrice);

  double get myProfitCollectedThisWeek =>
      deliveredThisWeek.fold<double>(0, (sum, o) => sum + o.myProfitShare);

  double get ownerProfitCollectedThisWeek =>
      deliveredThisWeek.fold<double>(0, (sum, o) => sum + o.ownerProfitShare);

  /// تنفيذ الغلق الأسبوعي: يبني التقرير، يرسله لجوجل شيت، ثم يؤرشف الطلبات المسلَّمة
  Future<Map<String, dynamic>> closeWeeklySession({
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final reportData = {
      'id': _uuid.v4(),
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'إجمالي المقبوضات': totalCollectedThisWeek,
      'صافي فائدتي': myProfitCollectedThisWeek,
      'صافي فائدة الشريك': ownerProfitCollectedThisWeek,
      'إجمالي الكريدي عند الزبائن': totalCustomerDebt,
      'إجمالي الديون على المحل للموردين': totalSupplierDebt,
      'تاريخ الأرشفة': DateTime.now().toIso8601String(),
    };

    await SheetsService.sendWeeklyReport(reportData);

    final report = WeeklyReport(
      id: reportData['id'] as String,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalCollected: totalCollectedThisWeek,
      myProfitCollected: myProfitCollectedThisWeek,
      ownerProfitCollected: ownerProfitCollectedThisWeek,
      totalCustomerDebt: totalCustomerDebt,
      totalSupplierDebt: totalSupplierDebt,
      archivedAt: DateTime.now(),
    );
    await _db.insertWeeklyReport(report);

    // تصفير الأسبوع: أرشفة الطلبات المسلَّمة حتى لا تُحتسب مجدداً
    await _db.archiveAllDeliveredOrders();
    await refresh();

    return reportData;
  }
}
