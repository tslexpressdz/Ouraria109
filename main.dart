import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/calculator_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/pin_gate.dart';

void main() {
  runApp(const PhoneRepairApp());
}

class PhoneRepairApp extends StatelessWidget {
  const PhoneRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'إدارة محل الصيانة',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        // للحصول على واجهة من اليمين لليسار بشكل صحيح
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D6B), // أخضر مزرق عصري
            brightness: Brightness.light,
          ),
          fontFamily: 'Cairo', // يمكن إضافة خط عربي عصري (اختياري - انظر README)
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D6B),
            brightness: Brightness.dark,
          ),
        ),
        home: const PinGate(child: HomeShell()),
      ),
    );
  }
}

/// الحاوية الرئيسية التي تحتوي على 3 التبويبات
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    CalculatorScreen(),
    DebtsScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'الحاسبة',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'الديون',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'الطلبات',
          ),
        ],
      ),
    );
  }
}
