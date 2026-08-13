import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/utils/debounce.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.suggestions,
    this.onSuggestionSelected,
  });
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Duration debounceDuration;
  final List<String>? suggestions;
  final void Function(String)? onSuggestionSelected;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _debouncer = Debouncer(delay: widget.debounceDuration);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debouncer(() {
      widget.onChanged?.call(value);
    });
    setState(() {}); // To update clear button visibility
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: _controller,
          hintText: widget.hintText ?? 'Search...',
          isSearch: true,
          onChanged: _onChanged,
          onSubmitted: widget.onSubmitted,
          onClear: _onClear,
          prefixIcon: Icon(
            Icons.search,
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        if (widget.suggestions != null &&
            widget.suggestions!.isNotEmpty &&
            _controller.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: AppRadius.sm,
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.suggestions!.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions![index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    _controller.text = suggestion;
                    widget.onSuggestionSelected?.call(suggestion);
                    _onChanged(suggestion);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
