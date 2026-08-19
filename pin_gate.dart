import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import 'pin_screens.dart';

/// يُغلَّف بها التطبيق بالكامل: يتحقق أولاً إن كان هناك رمز PIN محفوظ
/// - لا يوجد رمز بعد → شاشة إنشاء رمز جديد (أول استخدام)
/// - يوجد رمز → شاشة القفل تطلب إدخاله
/// - بعد النجاح في الحالتين → يُعرض التطبيق الفعلي (child)
class PinGate extends StatefulWidget {
  final Widget child;
  const PinGate({super.key, required this.child});

  @override
  State<PinGate> createState() => _PinGateState();
}

enum _GateStatus { loading, needsSetup, locked, unlocked }

class _PinGateState extends State<PinGate> {
  _GateStatus _status = _GateStatus.loading;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final has = await PinService.hasPin();
    setState(() {
      _status = has ? _GateStatus.locked : _GateStatus.needsSetup;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _GateStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _GateStatus.needsSetup:
        return SetupPinScreen(
          onDone: () => setState(() => _status = _GateStatus.unlocked),
        );
      case _GateStatus.locked:
        return LockScreen(
          onUnlocked: () => setState(() => _status = _GateStatus.unlocked),
        );
      case _GateStatus.unlocked:
        return widget.child;
    }
  }
}
