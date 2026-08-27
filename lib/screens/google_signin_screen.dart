import 'package:flutter/material.dart';
import '../services/sheets_service.dart';

class GoogleSignInScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const GoogleSignInScreen({super.key, required this.onSignedIn});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await SheetsService.signIn();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      widget.onSignedIn();
    } else {
      setState(() => _error =
          'تعذر تسجيل الدخول:\n${SheetsService.lastError ?? "خطأ غير معروف"}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              const Text(
                'سجّل دخولك بحساب Google',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'باش ينشئلك التطبيق شيت خاص بيك، ويحفظ فيه بياناتك تلقائياً',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_loading)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _handleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text('تسجيل الدخول بـ Google'),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
