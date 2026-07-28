import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/localization/app_localization.dart';

class SuggestionChips extends StatelessWidget {
  final Function(String) onSuggestionSelected;

  const SuggestionChips({
    Key? key,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      ('✨', Strings.askAnything),
      ('💻', Strings.writeCode),
      ('📄', Strings.analyzeFile),
      ('🌍', Strings.translate),
      ('📚', Strings.summarize),
      ('💡', Strings.suggestIdeas),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(
          suggestions.length,
          (index) => FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: GestureDetector(
              onTap: () => onSuggestionSelected(suggestions[index].$2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestions[index].$1,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suggestions[index].$2,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
