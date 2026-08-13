import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/presentation/animations/fade_in_slide.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Renders quick-start suggestion chips.
///
/// A pure presentation widget: labels are derived from the active
/// locale and tapping a chip forwards its text through
/// [onSuggestionSelected]. It performs no logic of its own.
class SuggestionChips extends StatelessWidget {
  /// Creates a [SuggestionChips].
  const SuggestionChips({super.key, required this.onSuggestionSelected});

  /// Invoked with the suggestion text when a chip is tapped.
  final ValueChanged<String> onSuggestionSelected;

  List<(String, String)> _suggestions(BuildContext context) {
    return <(String, String)>[
      ('✨', localizedText(context, 'Ask anything', 'اسأل أي شيء')),
      ('💻', localizedText(context, 'Write code', 'اكتب كوداً')),
      ('📄', localizedText(context, 'Analyze a file', 'حلّل ملفاً')),
      ('🌍', localizedText(context, 'Translate', 'ترجم')),
      ('📚', localizedText(context, 'Summarize', 'لخّص')),
      ('💡', localizedText(context, 'Suggest ideas', 'اقترح أفكاراً')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions(context);

    return Padding(
      padding: AppSpacing.h6,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (var index = 0; index < suggestions.length; index++)
            FadeInSlide(
              delay: Duration(milliseconds: index * 60),
              slideDistance: 8,
              child: _SuggestionChip(
                icon: suggestions[index].$1,
                label: suggestions[index].$2,
                onTap: () => onSuggestionSelected(suggestions[index].$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.xxl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xxl,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.v4,
            vertical: AppSpacing.v2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(icon, style: const TextStyle(fontSize: 16)),
              AppSpacing.gap2,
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
