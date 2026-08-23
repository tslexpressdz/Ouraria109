import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/formatters.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final totalCollected = appState.totalCollectedThisWeek;
    final ordersCount = appState.deliveredThisWeek.length;
    final totalDeliveryDue = appState.totalDeliveryDue;
    final totalSupplierDebt = appState.totalSupplierDebt;
    final netTotal = totalCollected - totalDeliveryDue - totalSupplierDebt;
    final grossProfit = appState.grossProfitThisWeek;
    final netProfit = appState.netProfitThisWeek;
    final myProfit = appState.myProfitCollectedThisWeek;
    final ownerProfit = appState.ownerProfitCollectedThisWeek;

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(
            theme,
            icon: Icons.payments_outlined,
            title: 'المبالغ المقبوضة',
            children: [
              _row('إجمالي المبالغ المقبوضة', formatCurrency(totalCollected),
                  bold: true),
              _row('عدد العمليات المخلَّصة', '$ordersCount'),
            ],
          ),
          const SizedBox(height: 16),

          _summaryCard(
            theme,
            icon: Icons.delivery_dining_outlined,
            title: 'أجر التوصيل المستحق',
            children: [
              if (appState.deliveryPersons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('ما كاين حتى مستحق توصيل',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              else ...[
                for (final p in appState.deliveryPersons)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${p.name} — ${formatCurrency(p.amountDue)}'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<AppState>().markDeliveryPersonPaid(p),
                          child: const Text('تم الدفع'),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                _row('مجموع أجر التوصيل', formatCurrency(totalDeliveryDue),
                    bold: true),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _summaryCard(
            theme,
            icon: Icons.local_shipping_outlined,
            title: 'ديون الموردين',
            children: [
              if (appState.supplierDebts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('ما كاين حتى دين لمورد',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              else ...[
                for (final d in appState.supplierDebts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              Text('${d.personName} — ${formatCurrency(d.amount)}'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<AppState>().markDebtPaid(d),
                          child: const Text('تم الدفع'),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                _row('مجموع ديون الموردين', formatCurrency(totalSupplierDebt),
                    bold: true),
              ],
            ],
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الصافي',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    formatCurrency(netTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _summaryCard(
            theme,
            icon: Icons.pie_chart_outline,
            title: 'توزيع الفائدة',
            children: [
              _row('الفائدة الإجمالية (قبل الخصم)', formatCurrency(grossProfit)),
              _row('ناقص: أجر التوصيل',
                  '- ${formatCurrency(appState.totalDeliveryCostEver)}'),
              const Divider(),
              _row('الفائدة الصافية', formatCurrency(netProfit), bold: true),
              const SizedBox(height: 4),
              _row('فائدتي', formatCurrency(myProfit),
                  bold: true, color: Colors.green.shade700),
              _row('فائدة صاحب المحل', formatCurrency(ownerProfit),
                  bold: true, color: Colors.blue.shade700),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
