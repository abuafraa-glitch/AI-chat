# AGENTS.md — AI-chat (Hajeen AI) repository memory

## Project
- Flutter app "Hajeen AI" — bilingual AI chat client. Layered: core → data → presentation. BLoC/Cubit, GetIt DI, go_router, Dio.
- Branch worked on: `main` (HEAD `d39f2a4`, shallow clone). Remote: github.com/abuafraa-glitch/AI-chat.git

## Environment setup (verified)
- Flutter/Dart NOT preinstalled. Installed Flutter SDK via `git clone --depth 1 --branch stable https://github.com/flutter/flutter.git ~/flutter-sdk` (needs `unzip` via `sudo apt-get install -y unzip` after `sudo apt-get update`).
- Use: `export PATH="$HOME/flutter-sdk/bin:$PATH"`.
- `flutter pub get` succeeds (resolves go_router 16.3.0, flutter_bloc 9.1.1, dio 5.11.0, internet_connection_checker_plus 2.9.1+2, uuid 4.5.3).
- `pubspec.lock` is NOT committed and NOT gitignored — non-reproducible across machines.

## Verified state (as of this review) — project does NOT compile
- `flutter analyze`: 414 issues = 132 errors / 44 warnings / 238 infos. 22 files have compile errors.
- `flutter test`: ZERO test files (test/ has only .gitkeep). Any "N/9 tests pass" claim is false.
- `dart format --set-exit-if-changed .`: reformats 99/127 files (formatting NOT clean).
- Platform folders correctly absent (android/ios/windows/linux/macos/web) — deferred per task scope.

## Known root-cause compile errors (do NOT assume "compile=0")
1. `AppSpacing` (lib/core/theme/app_spacing.dart) defines v1..v24/all1../h../gap.. but NOT `.md/.sm/.lg/.xl`; ~15 widget files use the undefined ones → `undefined_getter`/`invalid_constant`.
2. `AppRadius` doc references `AppRadius.circular`/`AppRadius.all` which don't exist.
3. Two parallel exception hierarchies with SAME names: `network_response.dart` (NetworkException + subtypes) vs `core/errors/exceptions.dart` (AppException + subtypes: ServerException, UnauthorizedException, NotFoundException, ForbiddenException, RateLimitException, NetworkException). `remote_data_source_impl.dart` imports BOTH without alias → `ambiguous_import` (16) + `invocation_of_non_function`.
4. `StorageKeys.currentUser` used in `local_data_source_impl.dart:41,46,53` but NOT defined in `storage_keys.dart` (only currentUserId/Name/Email/AvatarUrl).
5. `NetworkInfoImpl` uses `InternetConnectionCheckerPlus`/`InternetConnectionStatus`/`.hasConnection` — package 2.9.1+2 actually exposes `InternetConnection` (factory), `hasInternetAccess`, `InternetStatus`. (ConnectivityService uses the correct API — inconsistent.)
6. go_router 16: `GoRoute.builder` wants `GoRouterWidgetBuilder` (BuildContext, GoRouterState); page factory uses single-arg `(GoRouterState)` → 18 `argument_type_not_assignable`.
7. flutter_bloc 9: `BlocProviderSingleChildWidget` not a public type → 3 `non_type_as_type_argument` (app.dart, chat_screen.dart, main_layout.dart).
8. dio 5.11 added `DioExceptionType.transformTimeout`; `api_client.dart:290` & `retry_interceptor.dart:90` switches not exhaustive.
9. `string_extension.dart:39` unterminated string literal (regex with unescaped quote). `formatters.dart:41` non-constant default value.

## Known logic/architecture issues (compile-aside)
- ChatCubit has NO `close()`/StreamSubscription/CancelToken → streaming leaks + "Bloc is closed" after screen leave.
- Two separate `ModelsCubit` instances: main_layout.dart:50 and chat_screen.dart:68 (state split).
- Conversation IDs = `DateTime.now().microsecondsSinceEpoch.toString()` local, no createConversation backend call.
- `clearCache()` doesn't delete dynamic `CacheKeys.conversationMessages(id)` keys.
- RemoteDataSource returns raw `Map` for Files/Notifications/Agents/Payments/SubscriptionPlans.
- Localization: no .arb files; uses inline `localizedText(context, en, ar)`; plus hardcoded strings in error_view.dart (AR only), empty_state.dart (AR only), loading_button.dart ('Loading...' EN only).
- ProductionConfig enables ALL feature flags in production.
- ResponsiveLayout used only with mobile (tablet/desktop null) → dead abstraction.
- 19 `withOpacity` not migrated to `withValues`.
- Dio: no sendTimeout; receiveTimeout 30s applies to SSE stream → kills long streams.
- AuthInterceptor `catch (_) {}` silent (5 sites); refresh failure clears tokens but does NOT notify AuthController → phantom auth state. bootstrap() trusts token presence without /me validation.
- TWO logging systems: LoggerService (instance, services/) + AppLogger (static, utils/); interceptors use dart:developer directly.

## What IS solid (don't regress these)
- StorageKeys/SecureStorageKeys/CacheKeys separation is clean (no collision) — only the missing `currentUser` aggregate key is the bug.
- DI registration order is logical and layered.
- LoggingInterceptor redacts `Authorization` header.
- RetryInterceptor policy (idempotent methods, full-jitter backoff, connectivity check) is sound.
- Route guards (authGuard/featureFlagGuard) logic is reasonable (the failures are API-signature, not logic).
- Validators are pure static functions (easy to test).
- Repository interfaces + dependency inversion pattern is correctly applied.

## Tooling notes for this repo
- analysis_options.yaml has strict-casts/strict-inference/strict-raw-types ON + many lints; `test/**` excluded from analyzer.
- Do NOT run `dart format .` non-destructively — it rewrites ~99 files. If asked only to verify, use `dart format --output=none --set-exit-if-changed .` to avoid modifying the tree.
- Git Safety rule from the remediation prompt: no commits/pushes, no `git reset --hard`/`clean -fd`/`checkout .` on unrelated; restore tree with `git checkout -- .` if format touched files.
