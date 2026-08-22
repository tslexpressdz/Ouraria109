/// حالات طلب الصيانة
enum OrderStatus {
  pending, // قيد التصليح
  ready, // تم التصليح - في انتظار الزبون
  delivered, // تم التسليم وقبض الثمن كاملاً
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد التصليح';
      case OrderStatus.ready:
        return 'تم التصليح - بانتظار الزبون';
      case OrderStatus.delivered:
        return 'تم التسليم والقبض';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// نموذج عملية صيانة كاملة
class RepairOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deviceType; // نوع الهاتف
  final String partName; // اسم قطعة الغيار
  final double purchasePrice; // سعر شراء القطعة
  final double sellPrice; // سعر البيع النهائي المتفق عليه
  double deposit; // العربون المدفوع مسبقاً
  OrderStatus status;
  final DateTime createdAt;
  DateTime? deliveredAt;
  bool archived; // هل تمت أرشفتها ضمن غلق أسبوعي سابق

  RepairOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deviceType,
    required this.partName,
    required this.purchasePrice,
    required this.sellPrice,
    required this.deposit,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.deliveredAt,
    this.archived = false,
  });

  /// المبلغ المتبقي على الزبون
  double get remainingAmount {
    if (status == OrderStatus.delivered) return 0;
    final remaining = sellPrice - deposit;
    return remaining < 0 ? 0 : remaining;
  }

  /// صافي الفائدة الإجمالية المتوقعة (سعر البيع - سعر الشراء)
  double get totalProfit => sellPrice - purchasePrice;

  /// فائدتي الخاصة (50%)
  double get myProfitShare => totalProfit / 2;

  /// فائدة صاحب المحل (50%)
  double get ownerProfitShare => totalProfit / 2;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deviceType': deviceType,
      'partName': partName,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'deposit': deposit,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'archived': archived ? 1 : 0,
    };
  }

  factory RepairOrder.fromMap(Map<String, dynamic> map) {
    return RepairOrder(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      deviceType: map['deviceType'] as String,
      partName: map['partName'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      sellPrice: (map['sellPrice'] as num).toDouble(),
      deposit: (map['deposit'] as num).toDouble(),
      status: OrderStatusLabel.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'] as String)
          : null,
      archived: (map['archived'] as int) == 1,
    );
  }
}
