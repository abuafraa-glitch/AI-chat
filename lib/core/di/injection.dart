import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/errors/error_handler.dart';
import 'package:ai_chat/core/network/api_client.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/dio_factory.dart';
import 'package:ai_chat/core/network/network_info.dart';
import 'package:ai_chat/core/services/cache_service.dart';
import 'package:ai_chat/core/services/connectivity_service.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/logger_service.dart';
import 'package:ai_chat/core/services/permission_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Global instance of the GetIt service locator.
final GetIt sl = GetIt.instance;

/// Initializes all the dependencies for the application.
///
/// This function should be called once during the application's bootstrap
/// phase. It registers all services, repositories, and other dependencies
/// with the GetIt service locator.
Future<void> initDependencies() async {
  // ---------------------------------------------------------------------------
  // Core Dependencies
  // ---------------------------------------------------------------------------

  // LoggerService: Singleton
  sl.registerLazySingleton<LoggerService>(
    () => LoggerService(flavor: AppConfig.instance.flavor),
  );

  // LocalStorageService: Async Singleton
  final localStorageService = await LocalStorageService.create();
  sl.registerSingleton<LocalStorageService>(localStorageService);

  // SecureStorageService: Singleton
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(
      storage: const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    ),
  );

  // CacheService: Singleton
  sl.registerLazySingleton<CacheService>(CacheService.new);

  // ConnectivityService: Singleton with async initialization and dispose
  sl.registerSingleton<ConnectivityService>(
    ConnectivityService(
      connectivity: Connectivity(),
      internetConnection: InternetConnection(),
    ),
  );
  await sl<ConnectivityService>().initialise();

  // PermissionService: Singleton
  sl.registerLazySingleton<PermissionService>(PermissionService.new);

  // ErrorHandler: Singleton
  sl.registerLazySingleton<ErrorHandler>(
    () => ErrorHandler(logger: sl<LoggerService>()),
  );

  // ---------------------------------------------------------------------------
  // Network Dependencies
  // ---------------------------------------------------------------------------

  // NetworkInfo: Singleton
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      connectionChecker: InternetConnectionCheckerPlus(),
      connectivity: Connectivity(),
    ),
  );

  // TokenProvider: SecureStorageService acts as TokenProvider
  // Using a dynamic cast for now as SecureStorageService contains the required methods.
  // ignore: avoid_dynamic_calls
  sl.registerLazySingleton<TokenProvider>(
    () => sl<SecureStorageService>() as dynamic,
  );

  // Dio: Singleton
  sl.registerLazySingleton<Dio>(
    () => DioFactory.create(
      config: AppConfig.instance,
      tokenProvider: sl<TokenProvider>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // ApiConsumer: Singleton
  sl.registerLazySingleton<ApiConsumer>(
    () => ApiClient(dio: sl<Dio>()),
  );

  // ---------------------------------------------------------------------------
  // Presentation Layer Dependencies
  // ---------------------------------------------------------------------------

  // ThemeCubit: Factory
  sl.registerFactory<ThemeCubit>(
    () => ThemeCubit(localStorageService: sl<LocalStorageService>()),
  );

  // Note: Data, Domain, and other Presentation dependencies (like AppRouter)
  // will be registered here as they are implemented in future phases.
}

/// Resets the GetIt service locator, unregistering all dependencies.
///
/// This is useful for testing or when a complete re-initialization
/// of the application's dependencies is required.
Future<void> resetDependencies() async {
  await sl.reset(dispose: true);
}
