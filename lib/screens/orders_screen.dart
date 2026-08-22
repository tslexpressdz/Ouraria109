import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/repair_order.dart';
import '../utils/formatters.dart';
import 'archive_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'أرشيف التقارير الأسبوعية',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchiveScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text('لا توجد طلبات صيانة حالياً',
                        style: TextStyle(color: Colors.grey.shade600)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text(
                    'غلق جلسة الأعمال الأسبوعية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmWeeklyClose(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final RepairOrder order;
  const _OrderCard({required this.order});

  Color _statusColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.ready:
        return Colors.blue.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final color = _statusColor(context, order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.customerName} — ${order.deviceType}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(order.status.label,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${order.partName} • ${order.customerPhone}',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat('السعر', formatCurrency(order.sellPrice)),
                const SizedBox(width: 16),
                _miniStat('المتبقي', formatCurrency(order.remainingAmount)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusButton(
                  context,
                  label: 'قيد التصليح',
                  selected: order.status == OrderStatus.pending,
                  onTap: () =>
                      appState.updateOrderStatus(order, OrderStatus.pending),
                ),
                _statusButton(
                  context,
                  label: 'تم التصليح',
                  selected: order.status == OrderStatus.ready,
                  onTap: () =>
                      appState.updateOrderStatus(order, OrderStatus.ready),
                ),
                _statusButton(
                  context,
                  label: 'تم التسليم والقبض',
                  selected: order.status == OrderStatus.delivered,
                  onTap: () => _confirmDelivery(context, order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusButton(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  void _confirmDelivery(BuildContext context, RepairOrder order) {
    if (order.status == OrderStatus.delivered) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التسليم والقبض'),
        content: Text(
          'هل تم تسليم الجهاز لـ "${order.customerName}" وقبض كامل المبلغ '
          '(${formatCurrency(order.sellPrice)})؟\nسيتحول المبلغ المتبقي إلى صفر '
          'وتدخل الأرباح رسمياً في صندوق الأسبوع.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              context.read<AppState>().updateOrderStatus(order, OrderStatus.delivered);
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

void _confirmWeeklyClose(BuildContext context) {
  final appState = context.read<AppState>();
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7 == 0 ? 6 : now.weekday - 1));
  final weekEnd = now;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('غلق جلسة الأعمال الأسبوعية'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم إنشاء تقرير شامل عن الأسبوع الحالي، إرساله إلى '
                'Google Sheets، ثم تصفير عدادات الأسبوع للبدء من جديد.'),
            const SizedBox(height: 16),
            _reportLine('إجمالي المبالغ المقبوضة فعلياً',
                formatCurrency(appState.totalCollectedThisWeek)),
            _reportLine('صافي فائدتي المقبوضة',
                formatCurrency(appState.myProfitCollectedThisWeek)),
            _reportLine('صافي فائدة الشريك المقبوضة',
                formatCurrency(appState.ownerProfitCollectedThisWeek)),
            _reportLine('مجموع الكريدي المتبقي عند الزبائن',
                formatCurrency(appState.totalCustomerDebt)),
            _reportLine('مجموع الديون على المحل للموردين',
                formatCurrency(appState.totalSupplierDebt)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await appState.closeWeeklySession(weekStart: weekStart, weekEnd: weekEnd);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'تم أرشفة التقرير وإرساله إلى Google Sheets، وتصفير عدادات الأسبوع ✅')),
              );
            }
          },
          child: const Text('تأكيد الغلق'),
        ),
      ],
    ),
  );
}

Widget _reportLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
