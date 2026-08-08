# Hajeen AI 🧠

A bilingual (Arabic / English, RTL-ready) AI chat platform built with **Flutter** and a clean layered architecture — Core → Data → Presentation — driven by **BLoC/Cubit** state management, **GetIt** DI, **go_router** navigation and the **Dio** network stack.

## Stack

| Layer | Tech |
|---|---|
| UI | Flutter (Material 3, Cairo typeface) |
| State | `flutter_bloc` (Cubits) + `equatable` |
| DI | `get_it` |
| Routing | `go_router` (StatefulShellRoute, guards, deep links) |
| Networking | `dio` + interceptors (auth/refresh, retry, logging) |
| Storage | `shared_preferences` (non-sensitive) + `flutter_secure_storage` (tokens) |
| Localization | custom `LocalizationCubit` + `flutter_localizations` |

## Architecture

```
lib/
├── core/          # config (flavors/environments), constants, DI, errors, extensions,
│                  # network (ApiConsumer/Endpoints/interceptors), routes (AppRouter/guards),
│                  # services, theme (tokens), utils, widgets (design system)
├── data/          # datasources (remote/local) + models + repositories
├── presentation/  # screens, widgets, dialogs, animations, blocs (cubits), routing (page factory)
└── main.dart      # bootstrap: config + DI + runApp
```

**Dependency rule:** Widgets → Cubits → Repositories → Data Sources. Widgets never touch the network, storage, or business logic.

## Getting started

```bash
# 1. Fetch dependencies (SDK >= 3.8)
flutter pub get

# 2. Run (development flavor — all feature flags enabled)
flutter run --dart-define=FLAVOR=development
```

> Platform folders (`android/`, `ios/`, …) are generated from Android Studio / the Flutter CLI once the core code is final:
> ```bash
> flutter create --org com.hajeen --project-name ai_chat .
> ```

## Environment variables (build-time `--dart-define`)

| Variable | Default | Purpose |
|---|---|---|
| `FLAVOR` | `production` | `development` / `staging` / `production` |
| `API_BASE_URL` | `https://api.hajeen.ai` | REST API base |
| `WS_BASE_URL` | `wss://ws.hajeen.ai` | streaming gateway |
| `API_VERSION` | `v1` | API version prefix |
| `APP_NAME` / `APP_VERSION` | Hajeen AI / 1.0.0+1 | branding |

Environment-specific overrides live in `lib/core/config/environments/`.

## Feature flags

The `FeatureFlags` snapshot in `lib/core/config/app_config.dart` gates routes via `RouteGuard.featureFlagGuard`. All flags are enabled in every environment for now; flip them per-environment as features ship.

## Features

- 💬 Chat with real-time streaming (SSE), regeneration and clipboard actions
- 🧠 AI model catalogue with capability details and provider badges
- 🗂️ Conversation list with search, pinning and offline cache
- 🔐 Full auth flow: splash, onboarding, login, register, forgot/reset password, email verification (token refresh handled by the network layer)
- 📁 Files, notifications, agents and payment history screens
- 💳 Subscription plans + current plan card
- 🌙 Dark / light themes + Arabic / English with RTL

## Testing & analysis

```bash
flutter analyze
flutter test
```

## Repository layout notes

- `lib/data/repositories/*` implement `lib/data/repositories/*_repository.dart` interfaces; cubits consume the interfaces (dependency inversion).
- `lib/core/routes/app_router.dart` declares every route; `lib/presentation/routing/router_page_factory.dart` maps them to screens.
- `lib/presentation/blocs/auth_controller.dart` drives auth state and the router guards.
