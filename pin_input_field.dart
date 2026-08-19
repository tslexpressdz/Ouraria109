import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حقل إدخال رمز مكوّن من 4 أرقام بشكل بصري جذاب، مع نداء عند اكتمال الإدخال
class PinInputField extends StatefulWidget {
  final void Function(String pin) onCompleted;
  final bool hasError;

  const PinInputField({
    super.key,
    required this.onCompleted,
    this.hasError = false,
  });

  @override
  State<PinInputField> createState() => PinInputFieldState();
}

class PinInputFieldState extends State<PinInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void clear() {
    _controller.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _controller.text.length;
              return Container(
                width: 52,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.hasError
                        ? theme.colorScheme.error
                        : filled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
                child: Text(
                  filled ? '●' : '',
                  style: const TextStyle(fontSize: 22),
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (value) {
                setState(() {});
                if (value.length == 4) {
                  widget.onCompleted(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
