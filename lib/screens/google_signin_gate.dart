
import 'package:flutter/material.dart';
import '../services/sheets_service.dart';
import 'google_signin_screen.dart';

/// يُغلَّف بها التطبيق: يتحقق أولاً إذا كان المستخدم سجل دخوله من قبل
/// (تسجيل صامت بلا نافذة)، وإلا يعرض شاشة تسجيل الدخول
class GoogleSignInGate extends StatefulWidget {
  final Widget child;
  const GoogleSignInGate({super.key, required this.child});

  @override
  State<GoogleSignInGate> createState() => _GoogleSignInGateState();
}

enum _Status { loading, needsSignIn, signedIn }

class _GoogleSignInGateState extends State<GoogleSignInGate> {
  _Status _status = _Status.loading;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await SheetsService.signInSilently();
    if (!mounted) return;
    setState(() {
      _status = ok ? _Status.signedIn : _Status.needsSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _Status.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Status.needsSignIn:
        return GoogleSignInScreen(
          onSignedIn: () => setState(() => _status = _Status.signedIn),
        );
      case _Status.signedIn:
        return widget.child;
    }
  }
}
