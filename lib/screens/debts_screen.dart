import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/debt.dart';
import '../models/repair_order.dart';
import '../utils/formatters.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الديون والتوصيل'),
          bottom: const TabBar(tabs: [
            Tab(text: 'ديون الموردين'),
            Tab(text: 'ديون الزبائن'),
            Tab(text: 'أجر التوصيل'),
          ]),
        ),
        body: const TabBarView(children: [
          _SupplierDebtsTab(),
          _CustomerDebtsTab(),
          _DeliveryTab(),
        ]),
      ),
    );
  }
}

// =================== ديون الموردين (يسالوني) ===================

class _SupplierDebtsTab extends StatelessWidget {
  const _SupplierDebtsTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final debts = appState.supplierDebts;
    final total = debts.fold<double>(0, (s, d) => s + d.amount);

    return Column(
      children: [
        _totalBanner(context, 'إجمالي ديون الموردين', total,
            color: Theme.of(context).colorScheme.errorContainer),
        Expanded(
          child: debts.isEmpty
              ? const _EmptyState(text: 'لا توجد ديون على المحل حالياً')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: debts.length,
                  itemBuilder: (context, i) {
                    final debt = debts[i];
                    return _DebtCard(
                      debt: debt,
                      onPaid: () => context.read<AppState>().markDebtPaid(debt),
                      onDelete: () =>
                          context.read<AppState>().deleteDebt(debt.id),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showAddDebtDialog(context, DebtType.supplier),
            icon: const Icon(Icons.add),
            label: const Text('إضافة دين لمورد'),
          ),
        ),
      ],
    );
  }
}

// =================== ديون الزبائن (نسالهم) ===================

class _CustomerDebtsTab extends StatelessWidget {
  const _CustomerDebtsTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // الديون الآتية تلقائياً من طلبات الصيانة التي فيها مبلغ متبقٍ
    final ordersWithDebt =
        appState.orders.where((o) => o.remainingAmount > 0).toList();
    final manualDebts = appState.customerDebts;

    final total = ordersWithDebt.fold<double>(0, (s, o) => s + o.remainingAmount) +
        manualDebts.fold<double>(0, (s, d) => s + d.amount);

    return Column(
      children: [
        _totalBanner(context, 'إجمالي الكريدي عند الزبائن', total,
            color: Theme.of(context).colorScheme.tertiaryContainer),
        Expanded(
          child: (ordersWithDebt.isEmpty && manualDebts.isEmpty)
              ? const _EmptyState(text: 'لا توجد ديون على الزبائن حالياً')
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (ordersWithDebt.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('من عمليات الصيانة',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...ordersWithDebt.map((o) => _OrderDebtCard(order: o)),
                    ],
                    if (manualDebts.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('ديون مضافة يدوياً',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...manualDebts.map((d) => _DebtCard(
                            debt: d,
                            onPaid: () =>
                                context.read<AppState>().markDebtPaid(d),
                            onDelete: () =>
                                context.read<AppState>().deleteDebt(d.id),
                          )),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showAddDebtDialog(context, DebtType.customer),
            icon: const Icon(Icons.add),
            label: const Text('إضافة دين على زبون (يدوي)'),
          ),
        ),
      ],
    );
  }
}

class _OrderDebtCard extends StatelessWidget {
  final RepairOrder order;
  const _OrderDebtCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.build_circle_outlined),
        title: Text('${order.customerName} — ${order.deviceType}'),
        subtitle: Text('${order.partName} • ${order.customerPhone}'),
        trailing: Text(
          formatCurrency(order.remainingAmount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

// =================== أجر التوصيل ===================

class _DeliveryTab extends StatelessWidget {
  const _DeliveryTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final persons = appState.deliveryPersons;

    return Column(
      children: [
        Expanded(
          child: persons.isEmpty
              ? const _EmptyState(text: 'لا توجد مستحقات توصيل حالياً')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: persons.length,
                  itemBuilder: (context, i) {
                    final p = persons[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.delivery_dining_outlined),
                        title: Text(p.name),
                        subtitle: Text(formatCurrency(p.amountDue)),
                        trailing: FilledButton.tonal(
                          onPressed: () => context
                              .read<AppState>()
                              .markDeliveryPersonPaid(p),
                          child: const Text('تم الدفع'),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showAddDeliveryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة مستحق توصيل'),
          ),
        ),
      ],
    );
  }
}

// =================== عناصر مشتركة ===================

Widget _totalBanner(BuildContext context, String label, double value,
    {required Color color}) {
  return Container(
    width: double.infinity,
    color: color,
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(formatCurrency(value),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onPaid;
  final VoidCallback onDelete;

  const _DebtCard(
      {required this.debt, required this.onPaid, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(debt.type == DebtType.supplier
            ? Icons.local_shipping_outlined
            : Icons.person_outline),
        title: Text(debt.personName),
        subtitle: Text(debt.note.isEmpty ? formatDate(debt.createdAt) : debt.note),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCurrency(debt.amount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'تسديد الدين',
              onPressed: onPaid,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddDebtDialog(BuildContext context, DebtType type) {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(type == DebtType.supplier ? 'دين جديد لمورد' : 'دين جديد على زبون'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: type == DebtType.supplier ? 'اسم المورد' : 'اسم الزبون',
            ),
          ),
          TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(labelText: 'المبلغ'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
            ctx.read<AppState>().addDebt(
                  type: type,
                  personName: nameCtrl.text.trim(),
                  amount: amount,
                  note: noteCtrl.text.trim(),
                );
            Navigator.pop(ctx);
          },
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}

void _showAddDeliveryDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('إضافة مستحق توصيل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'اسم رجل التوصيل'),
          ),
          TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(labelText: 'المبلغ المستحق'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
            ctx.read<AppState>().addDeliveryPerson(nameCtrl.text.trim(), amount);
            Navigator.pop(ctx);
          },
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}
