
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';

class OtpField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool autoFocus;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;

  const OtpField({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.autoFocus = false,
    this.textStyle,
    this.decoration,
    this.inputFormatters,
  }) : assert(length > 0);

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _textControllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _textControllers = List.generate(widget.length, (index) => TextEditingController());

    if (widget.autoFocus) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final otp = _textControllers.map((e) => e.text).join();
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: _textControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            obscureText: widget.obscureText,
            style: widget.textStyle ?? context.textTheme.headlineSmall,
            inputFormatters: widget.inputFormatters ??
                [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
            decoration: widget.decoration ??
                InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: context.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.sm,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.sm,
                    borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
                  ),
                ),
            onChanged: (value) => _onChanged(value, index),
          ),
        );
      }),
    );
  }
}
