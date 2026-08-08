import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Shows the technical details of an [AIModel].
///
/// A pure presentation dialog: it renders the [AIModel] passed to it
/// and localizes its labels through [localizedText]. It contains no
/// business logic and never fetches data.
class ModelDetailsDialog extends StatelessWidget {
  /// The model whose details are displayed.
  final AIModel model;

  /// Creates a [ModelDetailsDialog] for [model].
  const ModelDetailsDialog({
    super.key,
    required this.model,
  });

  /// Opens the dialog over [context].
  static Future<void> show(BuildContext context, AIModel model) {
    return showDialog<void>(
      context: context,
      builder: (context) => ModelDetailsDialog(model: model),
    );
  }

  String _providerName(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.anthropic:
        return 'Anthropic';
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.qwen:
        return 'Qwen';
      case AIProvider.hajeenLocal:
        return 'Hajeen Local';
      case AIProvider.ollama:
        return 'Ollama';
      case AIProvider.vllm:
        return 'vLLM';
      case AIProvider.openRouter:
        return 'OpenRouter';
      case AIProvider.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capabilities = model.capabilities;

    return AlertDialog(
      title: Text(model.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (model.description != null &&
                model.description!.isNotEmpty) ...<Widget>[
              Text(model.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.v4),
            ],
            _DetailRow(
              label: localizedText(context, 'Provider', 'المزود'),
              value: _providerName(model.provider),
            ),
            _DetailRow(
              label: localizedText(context, 'Type', 'النوع'),
              value: model.type == AIModelType.cloud
                  ? localizedText(context, 'Cloud', 'سحابي')
                  : localizedText(context, 'Local', 'محلي'),
            ),
            _DetailRow(
              label: localizedText(context, 'Version', 'الإصدار'),
              value: model.version,
            ),
            _DetailRow(
              label: localizedText(context, 'Context window', 'نافذة السياق'),
              value: model.contextWindow.toString(),
            ),
            if (model.maxOutputTokens != null)
              _DetailRow(
                label: localizedText(context, 'Max output', 'أقصى مخرجات'),
                value: model.maxOutputTokens.toString(),
              ),
            _DetailRow(
              label: localizedText(context, 'Status', 'الحالة'),
              value: model.isAvailable
                  ? localizedText(context, 'Available', 'متاح')
                  : localizedText(context, 'Unavailable', 'غير متاح'),
            ),
            const SizedBox(height: AppSpacing.v4),
            Text(
              localizedText(context, 'Capabilities', 'الإمكانات'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.v2),
            Wrap(
              spacing: AppSpacing.v2,
              runSpacing: AppSpacing.v2,
              children: <Widget>[
                _CapabilityChip(
                  label: localizedText(context, 'Vision', 'رؤية'),
                  enabled: capabilities.supportsVision,
                ),
                _CapabilityChip(
                  label: localizedText(context, 'Audio', 'صوت'),
                  enabled: capabilities.supportsAudio,
                ),
                _CapabilityChip(
                  label: localizedText(context, 'Streaming', 'بث مباشر'),
                  enabled: capabilities.supportsStreaming,
                ),
                _CapabilityChip(
                  label: localizedText(context, 'Tool use', 'أدوات'),
                  enabled: capabilities.supportsToolUse,
                ),
                _CapabilityChip(
                  label: localizedText(context, 'JSON mode', 'وضع JSON'),
                  enabled: capabilities.supportsJsonMode,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizedText(context, 'Close', 'إغلاق')),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.v1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Chip(
      avatar: Icon(
        enabled ? Icons.check : Icons.close,
        size: 16,
        color: color,
      ),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(color: color),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: enabled
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHighest,
    );
  }
}
