import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/debt.dart';
import '../utils/formatters.dart';

/// شاشة تعرض كل تقارير الغلق الأسبوعي المؤرشفة سابقاً، من الأحدث إلى الأقدم
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AppState>().weeklyReports;

    return Scaffold(
      appBar: AppBar(title: const Text('أرشيف التقارير الأسبوعية')),
      body: reports.isEmpty
          ? Center(
              child: Text(
                'لا توجد تقارير مؤرشفة بعد.\nستظهر هنا كل مرة تضغط '
                '"غلق جلسة الأعمال الأسبوعية".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, i) => _ReportCard(report: reports[i]),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final WeeklyReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(
          'أسبوع ${formatDate(report.weekStart).split(' - ').first} '
          '→ ${formatDate(report.weekEnd).split(' - ').first}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('تمت الأرشفة في: ${formatDate(report.archivedAt)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _line('إجمالي المبالغ المقبوضة فعلياً', report.totalCollected,
              theme.colorScheme.primary),
          _line('صافي فائدتي المقبوضة', report.myProfitCollected,
              Colors.green.shade700),
          _line('صافي فائدة الشريك المقبوضة', report.ownerProfitCollected,
              Colors.blue.shade700),
          const Divider(),
          _line('مجموع الكريدي عند الزبائن (وقت الغلق)',
              report.totalCustomerDebt, theme.colorScheme.tertiary),
          _line('مجموع الديون للموردين (وقت الغلق)',
              report.totalSupplierDebt, theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _line(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(formatCurrency(value),
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
