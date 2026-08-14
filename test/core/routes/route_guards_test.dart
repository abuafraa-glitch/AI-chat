import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [AuthStatusProvider] whose [status] and [hasCompletedOnboarding]
/// can be set directly in tests. Extends [ChangeNotifier] to satisfy the
/// [Listenable] contract; no listeners are attached in these tests.
class _FakeAuthProvider extends ChangeNotifier implements AuthStatusProvider {
  _FakeAuthProvider(this._status, {bool onboarding = true})
    : _onboarding = onboarding;

  AuthStatus _status;
  bool _onboarding;

  @override
  AuthStatus get status => _status;

  @override
  bool get hasCompletedOnboarding => _onboarding;
}

void main() {
  group('RouteGuard.authGuardForLocation', () {
    test('loading holds the user on splash', () {
      final auth = _FakeAuthProvider(AuthStatus.loading);
      expect(
        RouteGuard.authGuardForLocation(RouteNames.chat, auth),
        RouteNames.splash,
      );
      expect(RouteGuard.authGuardForLocation(RouteNames.splash, auth), isNull);
    });

    test(
      'unauthenticated without onboarding redirects protected routes to onboarding',
      () {
        final auth = _FakeAuthProvider(
          AuthStatus.unauthenticated,
          onboarding: false,
        );
        expect(
          RouteGuard.authGuardForLocation(RouteNames.chat, auth),
          RouteNames.onboarding,
        );
        expect(
          RouteGuard.authGuardForLocation(RouteNames.models, auth),
          RouteNames.onboarding,
        );
      },
    );

    test(
      'unauthenticated with onboarding redirects protected routes to login',
      () {
        final auth = _FakeAuthProvider(
          AuthStatus.unauthenticated,
          onboarding: true,
        );
        expect(
          RouteGuard.authGuardForLocation(RouteNames.chat, auth),
          RouteNames.login,
        );
        expect(
          RouteGuard.authGuardForLocation(RouteNames.models, auth),
          RouteNames.login,
        );
      },
    );

    test('unauthenticated may stay on auth screens and splash', () {
      final auth = _FakeAuthProvider(
        AuthStatus.unauthenticated,
        onboarding: true,
      );
      expect(RouteGuard.authGuardForLocation(RouteNames.login, auth), isNull);
      expect(
        RouteGuard.authGuardForLocation(RouteNames.register, auth),
        isNull,
      );
      expect(RouteGuard.authGuardForLocation(RouteNames.splash, auth), isNull);
    });

    test('authenticated is bounced off auth / splash / onboarding to chat', () {
      final auth = _FakeAuthProvider(AuthStatus.authenticated);
      expect(
        RouteGuard.authGuardForLocation(RouteNames.login, auth),
        RouteNames.chat,
      );
      expect(
        RouteGuard.authGuardForLocation(RouteNames.splash, auth),
        RouteNames.chat,
      );
      expect(
        RouteGuard.authGuardForLocation(RouteNames.onboarding, auth),
        RouteNames.chat,
      );
    });

    test('authenticated may access protected routes', () {
      final auth = _FakeAuthProvider(AuthStatus.authenticated);
      expect(RouteGuard.authGuardForLocation(RouteNames.chat, auth), isNull);
      expect(RouteGuard.authGuardForLocation(RouteNames.models, auth), isNull);
      expect(
        RouteGuard.authGuardForLocation(RouteNames.settings, auth),
        isNull,
      );
      expect(RouteGuard.authGuardForLocation(RouteNames.files, auth), isNull);
    });
  });

  group('RouteGuard.featureFlagGuardForLocation', () {
    FeatureFlags flags({
      bool sub = false,
      bool pay = false,
      bool files = false,
      bool search = false,
      bool agents = false,
      bool notif = false,
    }) => FeatureFlags(
      enableSubscriptions: sub,
      enablePayments: pay,
      enableFileManagement: files,
      enableSearch: search,
      enableAgents: agents,
      enableNotifications: notif,
    );

    test('disabled features redirect to chat', () {
      final f = flags(); // all disabled (production defaults)
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.subscriptions, f),
        RouteNames.chat,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.payments, f),
        RouteNames.chat,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.files, f),
        RouteNames.chat,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.search, f),
        RouteNames.chat,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.agents, f),
        RouteNames.chat,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.notifications, f),
        RouteNames.chat,
      );
    });

    test('enabled features are allowed', () {
      final f = flags(
        sub: true,
        pay: true,
        files: true,
        search: true,
        agents: true,
        notif: true,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.subscriptions, f),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.payments, f),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.files, f),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.search, f),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.agents, f),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.notifications, f),
        isNull,
      );
    });

    test('flag-free routes are always allowed', () {
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.chat, flags()),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.models, flags()),
        isNull,
      );
      expect(
        RouteGuard.featureFlagGuardForLocation(RouteNames.settings, flags()),
        isNull,
      );
    });
  });
}
