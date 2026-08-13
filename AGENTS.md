# AGENTS.md — Hajeen AI (AI-chat)

Repository-specific knowledge for the Hajeen AI Flutter application.

## Project overview
- Flutter app (`ai_chat` package) using **Clean Architecture** (core/data/presentation).
- State management: `flutter_bloc` 9.1.1 (requires `List<SingleChildWidget>` from the `nested` package for `MultiBlocProvider`).
- Routing: `go_router` with `StatefulShellRoute.indexedStack` for bottom-nav tabs.
- Networking: `dio` + interceptors (auth, retry).
- Localization: custom `localizedText(context, en, ar)` helper (no `.arb`/`gen_l10n`); supports `en` + `ar`; RTL via `GlobalWidgetsLocalizations`.

## Key conventions
- `MultiBlocProvider.providers` must be `List<SingleChildWidget>` — import `package:nested/nested.dart` (added as direct dependency).
- `GoRouterState`-based page factory: `AppRouterPageFactory` in `core/routes/app_router.dart`, implemented by `presentation/routing/router_page_factory.dart`.
- `DioExceptionType.transformTimeout` exists in newer `dio` — handle it in all switch statements.
- `core/errors/exceptions.dart` and `core/network/network_response.dart` both define `NetworkException`; use `import ... as domain` alias in `remote_data_source_impl.dart`.
- Color opacity: use `.withValues(alpha: x)` (NOT deprecated `.withOpacity(x)`) on Flutter 3.32+.
- `surfaceVariant` is deprecated → use `surfaceContainerHighest`.

## Build / verify commands
```bash
export PATH="/workspace/flutter/bin:$PATH"
flutter pub get
flutter analyze          # 0 errors, 0 warnings, ~25 cascade_invocations infos (acceptable)
dart format lib/ test/   # keep formatting clean
flutter test             # 9 tests (models + chat_cubit)
```
- No Android SDK / web `index.html` in this environment → `flutter build apk/web` won't work here; rely on `flutter analyze` + `flutter test`.
- Do NOT create platform folders (android/ios/web/...) — user constraint.

## Testing
- `test/data/models/message_model_test.dart` — JSON round-trip, defaults, copyWith, equality.
- `test/presentation/blocs/chat_cubit_test.dart` — streaming send, cache, error handling (uses fake repositories, no mocks).
- `analysis_options.yaml` excludes `test/**` from analyze — run `flutter test` to compile-check tests.

## Known patterns / gotchas
- `ChatState.copyWith` uses a sentinel (`_sentinel`) so `streamingContent`/`error` can be explicitly reset to `null` (the `?? this.x` pattern can't clear nullable fields).
- `ChatCubit` catches `on Exception` — repository errors must implement `Exception` (AppException does; StateError does not).
- `app_colors.dart` has `// ignore_for_file: unused_field` — raw palette fields are intentionally kept for the design system.
- `injection.dart` has many `cascade_invocations` infos from repeated `sl.registerSingleton` calls — left as-is for readability.
