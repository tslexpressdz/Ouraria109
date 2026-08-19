import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../widgets/pin_input_field.dart';

/// تُعرض أول مرة يفتح فيها المستخدم التطبيق: إنشاء رمز PIN جديد
class SetupPinScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupPinScreen({super.key, required this.onDone});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _firstFieldKey = GlobalKey<PinInputFieldState>();
  final _secondFieldKey = GlobalKey<PinInputFieldState>();

  String? _firstPin;
  bool _confirming = false;
  bool _error = false;

  void _handleFirst(String pin) {
    setState(() {
      _firstPin = pin;
      _confirming = true;
      _error = false;
    });
  }

  Future<void> _handleConfirm(String pin) async {
    if (pin == _firstPin) {
      await PinService.setPin(pin);
      if (mounted) widget.onDone();
    } else {
      setState(() => _error = true);
      _secondFieldKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _confirming ? 'أعد إدخال الرمز للتأكيد' : 'أنشئ رمز حماية (4 أرقام)',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'سيُطلب منك هذا الرمز في كل مرة تفتح فيها التطبيق',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_confirming)
                PinInputField(key: _firstFieldKey, onCompleted: _handleFirst)
              else
                PinInputField(
                  key: _secondFieldKey,
                  hasError: _error,
                  onCompleted: _handleConfirm,
                ),
              if (_error) ...[
                const SizedBox(height: 12),
                Text('الرمزان غير متطابقين، حاول مجدداً',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_confirming) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() {
                    _confirming = false;
                    _firstPin = null;
                    _error = false;
                  }),
                  child: const Text('البدء من جديد'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// شاشة القفل: تُعرض عند كل فتح للتطبيق إن كان الرمز مُفعَّلاً مسبقاً
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _fieldKey = GlobalKey<PinInputFieldState>();
  bool _error = false;

  Future<void> _checkPin(String pin) async {
    final correct = await PinService.checkPin(pin);
    if (correct) {
      widget.onUnlocked();
    } else {
      setState(() => _error = true);
      _fieldKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('أدخل رمز الحماية', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 32),
              PinInputField(key: _fieldKey, hasError: _error, onCompleted: _checkPin),
              if (_error) ...[
                const SizedBox(height: 12),
                Text('رمز غير صحيح',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// شاشة تغيير رمز الحماية: يجب إدخال الرمز الحالي أولاً، ثم تعيين رمز جديد
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _ChangeStep { verifyCurrent, enterNew, confirmNew }

class _ChangePinScreenState extends State<ChangePinScreen> {
  _ChangeStep _step = _ChangeStep.verifyCurrent;
  String? _newPin;
  bool _error = false;
  final _fieldKey = GlobalKey<PinInputFieldState>();

  Future<void> _handleInput(String pin) async {
    switch (_step) {
      case _ChangeStep.verifyCurrent:
        final ok = await PinService.checkPin(pin);
        if (ok) {
          setState(() {
            _step = _ChangeStep.enterNew;
            _error = false;
          });
        } else {
          setState(() => _error = true);
          _fieldKey.currentState?.clear();
        }
        break;
      case _ChangeStep.enterNew:
        setState(() {
          _newPin = pin;
          _step = _ChangeStep.confirmNew;
          _error = false;
        });
        break;
      case _ChangeStep.confirmNew:
        if (pin == _newPin) {
          await PinService.setPin(pin);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تغيير رمز الحماية بنجاح ✅')),
            );
          }
        } else {
          setState(() {
            _error = true;
            _step = _ChangeStep.enterNew;
            _newPin = null;
          });
          _fieldKey.currentState?.clear();
        }
        break;
    }
  }

  String get _title {
    switch (_step) {
      case _ChangeStep.verifyCurrent:
        return 'أدخل الرمز الحالي';
      case _ChangeStep.enterNew:
        return 'أدخل الرمز الجديد';
      case _ChangeStep.confirmNew:
        return 'أعد إدخال الرمز الجديد للتأكيد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير رمز الحماية')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 32),
              PinInputField(
                key: _fieldKey,
                hasError: _error,
                onCompleted: _handleInput,
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                Text(
                  _step == _ChangeStep.verifyCurrent
                      ? 'رمز غير صحيح'
                      : 'الرمزان غير متطابقين',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
