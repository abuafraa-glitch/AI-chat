/// Runtime environment flavors for the Hajeen AI platform.
///
/// The active flavor is selected at build time through the
/// `--dart-define=FLAVOR=<value>` compile-time flag and resolved via
/// [Flavor.fromEnvironment]. When the flag is missing or holds an
/// unrecognised value, [Flavor.production] is returned so that the
/// safest, most restrictive configuration is the default.
enum Flavor {
  /// Local development build. Verbose logging, debug tooling, and
  /// relaxed network timeouts.
  development,

  /// Pre-release staging build. Mirrors production but with diagnostic
  /// affordances and non-productive data sources.
  staging,

  /// Customer-facing production build. Strictest settings, no debug
  /// surfaces, and hardened defaults.
  production;

  /// Compile-time key used to look up this flavor from `dart-define`.
  static const String dartDefineKey = 'FLAVOR';

  /// Human-readable label suitable for logs, diagnostics, and UI.
  String get label {
    switch (this) {
      case Flavor.development:
        return 'Development';
      case Flavor.staging:
        return 'Staging';
      case Flavor.production:
        return 'Production';
    }
  }

  /// `true` when this flavor is not [Flavor.production]. Useful for
  /// gating diagnostics and developer tooling.
  bool get isNonProduction => this != Flavor.production;

  /// Resolves the active flavor from compile-time defines.
  ///
  /// The value is matched against [Flavor.name]; any mismatch falls
  /// back to [Flavor.production] to prevent misconfigured builds from
  /// silently running with development settings.
  static Flavor fromEnvironment() {
    const declared = String.fromEnvironment(dartDefineKey, defaultValue: '');
    if (declared.isEmpty) {
      return Flavor.production;
    }
    for (final flavor in Flavor.values) {
      if (flavor.name == declared) {
        return flavor;
      }
    }
    return Flavor.production;
  }
}
