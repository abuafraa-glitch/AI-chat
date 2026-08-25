import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/repositories/ai_repository.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAIRepository implements AIRepository {
  @override
  Future<List<AIModel>> getModels() async {
    // StateError represents the class of parsing/runtime errors that must
    // also leave the UI in a terminal state.
    throw StateError('catalogue unavailable');
  }

  @override
  Future<AIModel> getModelDetails(String modelId) async {
    throw UnimplementedError();
  }
}

void main() {
  test('uses Groq fallback and exits loading when catalogue fails', () async {
    final cubit = ModelsCubit(repository: _FailingAIRepository());

    await cubit.loadModels();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.models, isNotEmpty);
    expect(cubit.state.models.first.provider, AIProvider.groq);
    expect(cubit.state.models.first.id, 'openai/gpt-oss-20b');
    expect(cubit.state.selectedModelId, 'openai/gpt-oss-20b');

    await cubit.close();
  });
}
