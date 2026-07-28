import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authTokenProvider = StateProvider<String?>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAuthToken();
});

final selectedModelProvider = StateProvider<String?>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getSelectedModel();
});
