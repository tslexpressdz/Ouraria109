import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/formatters.dart';
import 'pin_screens.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _deviceTypeCtrl = TextEditingController();
  final _partNameCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController(text: '0');

  double _remaining = 0;
  double _totalProfit = 0;
  double _myShare = 0;
  double _ownerShare = 0;

  @override
  void initState() {
    super.initState();
    for (final c in [_purchasePriceCtrl, _sellPriceCtrl, _depositCtrl]) {
      c.addListener(_recalculate);
    }
  }

  double _parse(String text) => double.tryParse(text.trim()) ?? 0;

  void _recalculate() {
    final purchase = _parse(_purchasePriceCtrl.text);
    final sell = _parse(_sellPriceCtrl.text);
    final deposit = _parse(_depositCtrl.text);

    setState(() {
      final remaining = sell - deposit;
      _remaining = remaining < 0 ? 0 : remaining;
      _totalProfit = sell - purchase;
      _myShare = _totalProfit / 2;
      _ownerShare = _totalProfit / 2;
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    await appState.addOrder(
      customerName: _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      deviceType: _deviceTypeCtrl.text.trim(),
      partName: _partNameCtrl.text.trim(),
      purchasePrice: _parse(_purchasePriceCtrl.text),
      sellPrice: _parse(_sellPriceCtrl.text),
      deposit: _parse(_depositCtrl.text),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ العملية بنجاح ✅ (قيد الانتظار)')),
    );

    _formKey.currentState!.reset();
    _customerNameCtrl.clear();
    _customerPhoneCtrl.clear();
    _deviceTypeCtrl.clear();
    _partNameCtrl.clear();
    _purchasePriceCtrl.clear();
    _sellPriceCtrl.clear();
    _depositCtrl.text = '0';
    _recalculate();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _deviceTypeCtrl.dispose();
    _partNameCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الصيانة والأرباح'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset_outlined),
            tooltip: 'تغيير رمز الحماية',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePinScreen()),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('بيانات الزبون'),
            _textField(_customerNameCtrl, 'اسم الزبون', Icons.person_outline,
                required: true),
            const SizedBox(height: 12),
            _textField(_customerPhoneCtrl, 'رقم الهاتف', Icons.phone_outlined,
                keyboardType: TextInputType.phone, required: true),
            const SizedBox(height: 20),
            _sectionTitle('بيانات الصيانة'),
            _textField(_deviceTypeCtrl, 'نوع الهاتف', Icons.smartphone_outlined,
                required: true),
            const SizedBox(height: 12),
            _textField(_partNameCtrl, 'اسم قطعة الغيار', Icons.build_outlined,
                required: true),
            const SizedBox(height: 20),
            _sectionTitle('الأسعار'),
            _numberField(_purchasePriceCtrl, 'سعر شراء القطعة',
                Icons.shopping_cart_outlined),
            const SizedBox(height: 12),
            _numberField(
                _sellPriceCtrl, 'سعر البيع النهائي المتفق عليه', Icons.sell_outlined),
            const SizedBox(height: 12),
            _numberField(_depositCtrl, 'المبلغ المدفوع مسبقاً (العربون)',
                Icons.payments_outlined),
            const SizedBox(height: 24),
            _resultsCard(theme),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveOrder,
              icon: const Icon(Icons.save_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('حفظ العملية', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _numberField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixText: 'دج',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (double.tryParse(v.trim()) == null) return 'رقم غير صالح';
        return null;
      },
    );
  }

  Widget _resultsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('النتائج التلقائية',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _resultRow('المبلغ المتبقي على الزبون', _remaining,
                color: theme.colorScheme.error),
            _resultRow('صافي الفائدة الإجمالية المتوقعة', _totalProfit,
                color: theme.colorScheme.primary),
            const Divider(height: 24),
            _resultRow('فائدتي الخاصة (50%)', _myShare,
                color: Colors.green.shade700),
            _resultRow('فائدة صاحب المحل (50%)', _ownerShare,
                color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, double value, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            formatCurrency(value),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
