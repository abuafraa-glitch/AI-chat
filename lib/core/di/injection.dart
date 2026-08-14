import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/network/api_client.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/dio_factory.dart';
import 'package:ai_chat/core/network/network_info.dart';
import 'package:ai_chat/core/routes/app_router.dart';
import 'package:ai_chat/core/services/cache_service.dart';
import 'package:ai_chat/core/services/connectivity_service.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/logger_service.dart';
import 'package:ai_chat/core/services/permission_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/local/local_data_source_impl.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source_impl.dart';
import 'package:ai_chat/data/repositories/ai_repository.dart';
import 'package:ai_chat/data/repositories/ai_repository_impl.dart';
import 'package:ai_chat/data/repositories/conversation_repository.dart';
import 'package:ai_chat/data/repositories/conversation_repository_impl.dart';
import 'package:ai_chat/data/repositories/file_repository.dart';
import 'package:ai_chat/data/repositories/file_repository_impl.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';
import 'package:ai_chat/data/repositories/message_repository_impl.dart';
import 'package:ai_chat/data/repositories/subscription_repository.dart';
import 'package:ai_chat/data/repositories/subscription_repository_impl.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/routing/router_page_factory.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Global instance of the GetIt service locator.
final GetIt sl = GetIt.instance;

/// Initialises all dependencies for the application.
///
/// Must be called once during the bootstrap phase, after
/// [AppConfig.initialize], and before the first frame is rendered.
Future<void> initDependencies() async {
  // ── Core services ─────────────────────────────────────────────────────────

  // LoggerService: singleton.
  sl.registerLazySingleton<LoggerService>(
    () => LoggerService(flavor: AppConfig.instance.flavor),
  );

  // LocalStorageService: async singleton.
  final localStorageService = await LocalStorageService.create();
  sl.registerSingleton<LocalStorageService>(localStorageService);

  // SecureStorageService: singleton; implements TokenProvider directly,
  // so the network layer reads and persists tokens through it.
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
  sl.registerLazySingleton<TokenProvider>(() => sl<SecureStorageService>());

  // CacheService: in-memory TTL cache.
  sl.registerLazySingleton<CacheService>(CacheService.new);

  // ConnectivityService: singleton with async initialisation.
  sl.registerSingleton<ConnectivityService>(
    ConnectivityService(
      connectivity: Connectivity(),
      internetConnection: InternetConnection(),
    ),
  );
  await sl<ConnectivityService>().initialise();

  // PermissionService: singleton.
  sl.registerLazySingleton<PermissionService>(PermissionService.new);

  // ── Network ───────────────────────────────────────────────────────────────

  // NetworkInfo: singleton.
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      connectionChecker: InternetConnection(),
      connectivity: Connectivity(),
    ),
  );

  // Dio: singleton, fully configured with the interceptor stack.
  sl.registerLazySingleton<Dio>(
    () => DioFactory.create(
      config: AppConfig.instance,
      tokenProvider: sl<TokenProvider>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<LoggerService>(),
      authSessionSink: sl<AuthSessionSink>(),
    ),
  );

  // ApiConsumer: singleton.
  sl.registerLazySingleton<ApiConsumer>(() => ApiClient(dio: sl<Dio>()));

  // ── Data sources ──────────────────────────────────────────────────────────

  sl.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(apiConsumer: sl<ApiConsumer>()),
  );

  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(
      sl<LocalStorageService>(),
      sl<SecureStorageService>(),
    ),
  );

  // ── Repositories ──────────────────────────────────────────────────────────

  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(
      remoteDataSource: sl<RemoteDataSource>(),
      localDataSource: sl<LocalDataSource>(),
    ),
  );

  // ModelsCubit: SINGLETON — the single source of truth for the AI model
  // catalogue and the user's current selection. It is shared (via
  // BlocProvider.value) between the main shell and the pushed ChatScreen
  // so that selecting a model in one surface immediately reflects in the
  // other. A singleton is correct here because model selection is an
  // application-wide concern, not a per-screen concern.
  sl.registerLazySingleton<ModelsCubit>(
    () => ModelsCubit(repository: sl<AIRepository>())..loadModels(),
  );

  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(
      remoteDataSource: sl<RemoteDataSource>(),
      localDataSource: sl<LocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: sl<RemoteDataSource>(),
      localDataSource: sl<LocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      remoteDataSource: sl<RemoteDataSource>(),
      localDataSource: sl<LocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<FileRepository>(
    () => FileRepositoryImpl(remoteDataSource: sl<RemoteDataSource>()),
  );

  // ── Presentation state management ─────────────────────────────────────────

  // ThemeCubit: factory — one instance per widget subtree.
  sl.registerFactory<ThemeCubit>(
    () => ThemeCubit(localStorageService: sl<LocalStorageService>()),
  );

  // LocalizationCubit: factory.
  sl.registerFactory<LocalizationCubit>(
    () => LocalizationCubit(storage: sl<LocalStorageService>()),
  );

  // ── Routing / auth wiring ─────────────────────────────────────────────────

  // AuthController: singleton ChangeNotifier driving the router guards.
  sl.registerLazySingleton<AuthController>(
    () => AuthController(
      remoteDataSource: sl<RemoteDataSource>(),
      secureStorage: sl<SecureStorageService>(),
      localStorage: sl<LocalStorageService>(),
    ),
  );

  // AuthSessionSink: the AuthController exposes the network-layer sink so
  // the AuthInterceptor can reconcile the auth state to `unauthenticated`
  // when an unrecoverable token-refresh failure occurs. Registering it as
  // a lazy alias over AuthController avoids a construction cycle: the Dio
  // factory captures `sl<AuthSessionSink>()` but only resolves it on the
  // first 401, long after `setup()` has finished registering everything.
  sl.registerLazySingleton<AuthSessionSink>(sl<AuthController>);

  // Router page factory: maps every route to a concrete screen.
  sl.registerLazySingleton<AppRouterPageFactory>(RouterPageFactory.new);

  // AppRouter: singleton; the router listens to the auth controller for
  // reactive redirect re-evaluation.
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(
      authStatusProvider: sl<AuthController>(),
      pageFactory: sl<AppRouterPageFactory>(),
    ),
  );
}

/// Resets the GetIt service locator, unregistering all dependencies.
///
/// Useful for testing or when a complete re-initialisation is required.
Future<void> resetDependencies() async {
  await sl.reset(dispose: true);
}
