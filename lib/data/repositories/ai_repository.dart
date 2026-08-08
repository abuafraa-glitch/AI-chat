import 'package:ai_chat/data/models/ai_model.dart';

/// Contract for the AI model catalogue repository.
///
/// Implementations orchestrate remote and local data sources and hide
/// caching policies from the presentation layer. Failures are surfaced
/// as [AppException] subtypes thrown by the data sources.
abstract interface class AIRepository {
  /// Returns all available AI models, remote-first with a local-cache
  /// fallback when the network is unavailable.
  Future<List<AIModel>> getModels();

  /// Fetches the technical details of a single [modelId].
  Future<AIModel> getModelDetails(String modelId);
}
