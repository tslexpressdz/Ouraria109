/// نوع الدين
enum DebtType {
  supplier, // دين للمورد (يسالوني)
  customer, // دين على الزبون (نسأله) - يدوي غير مرتبط بطلب صيانة
}

class Debt {
  final String id;
  final DebtType type;
  final String personName; // اسم المورد أو الزبون
  double amount;
  final String note;
  final DateTime createdAt;
  bool paid;

  Debt({
    required this.id,
    required this.type,
    required this.personName,
    required this.amount,
    this.note = '',
    required this.createdAt,
    this.paid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'personName': personName,
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'paid': paid ? 1 : 0,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      type: (map['type'] as String) == 'supplier'
          ? DebtType.supplier
          : DebtType.customer,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      paid: (map['paid'] as int) == 1,
    );
  }
}

/// عامل التوصيل والمبلغ المستحق له
class DeliveryPerson {
  final String id;
  final String name;
  double amountDue;
  final DateTime createdAt;
  bool paid;

  DeliveryPerson({
    required this.id,
    required this.name,
    required this.amountDue,
    required this.createdAt,
    this.paid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amountDue': amountDue,
      'createdAt': createdAt.toIso8601String(),
      'paid': paid ? 1 : 0,
    };
  }

  factory DeliveryPerson.fromMap(Map<String, dynamic> map) {
    return DeliveryPerson(
      id: map['id'] as String,
      name: map['name'] as String,
      amountDue: (map['amountDue'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      paid: (map['paid'] as int) == 1,
    );
  }
}

/// تقرير الغلق الأسبوعي المؤرشف
class WeeklyReport {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalCollected; // إجمالي المبالغ المقبوضة فعلياً
  final double myProfitCollected; // صافي فائدتي المقبوضة
  final double ownerProfitCollected; // صافي فائدة الشريك المقبوضة
  final double totalCustomerDebt; // مجموع الكريدي المتبقي عند الزبائن
  final double totalSupplierDebt; // مجموع الديون على المحل للموردين
  final DateTime archivedAt;

  WeeklyReport({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.totalCollected,
    required this.myProfitCollected,
    required this.ownerProfitCollected,
    required this.totalCustomerDebt,
    required this.totalSupplierDebt,
    required this.archivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalCollected': totalCollected,
      'myProfitCollected': myProfitCollected,
      'ownerProfitCollected': ownerProfitCollected,
      'totalCustomerDebt': totalCustomerDebt,
      'totalSupplierDebt': totalSupplierDebt,
      'archivedAt': archivedAt.toIso8601String(),
    };
  }

  factory WeeklyReport.fromMap(Map<String, dynamic> map) {
    return WeeklyReport(
      id: map['id'] as String,
      weekStart: DateTime.parse(map['weekStart'] as String),
      weekEnd: DateTime.parse(map['weekEnd'] as String),
      totalCollected: (map['totalCollected'] as num).toDouble(),
      myProfitCollected: (map['myProfitCollected'] as num).toDouble(),
      ownerProfitCollected: (map['ownerProfitCollected'] as num).toDouble(),
      totalCustomerDebt: (map['totalCustomerDebt'] as num).toDouble(),
      totalSupplierDebt: (map['totalSupplierDebt'] as num).toDouble(),
      archivedAt: DateTime.parse(map['archivedAt'] as String),
    );
  }
}
