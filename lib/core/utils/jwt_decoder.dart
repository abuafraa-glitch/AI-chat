import 'dart:convert';

/// Pure, dependency-free helper that decodes the *payload* of a JSON Web
/// Token and exposes the `exp` (expiration) claim.
///
/// The project's access tokens are bearer strings obtained from the
/// Hajeen AI auth endpoints. The backend contract does **not** surface a
/// separate `expires_in` / `expires_at` field (see `AuthInterceptor` and
/// `AuthController._persistSession`), so the only contract-free way to
/// reason about token validity locally — without inventing an API
/// contract — is to read the standard `exp` claim from the JWT payload.
///
/// This helper is intentionally tolerant: tokens that are not JWTs (opaque
/// tokens), are malformed, or lack an `exp` claim yield `null`, so callers
/// can fall back to a presence-based check instead of crashing. It performs
/// **no signature verification** — signature validation is the backend's
/// responsibility; here we only read the self-describing metadata.
abstract final class JwtDecoder {
  const JwtDecoder._();

  /// Returns the `exp` claim of [token] as a [DateTime], or `null` when the
  /// token is not a JWT, is malformed, or does not carry an `exp` claim.
  static DateTime? expirationOf(String? token) {
    final claims = _claimsOf(token);
    if (claims == null) {
      return null;
    }
    final exp = claims['exp'];
    if (exp is! num) {
      return null;
    }
    // JWT `exp` is seconds since the Unix epoch.
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }

  /// Returns `true` when [token] carries an `exp` claim that has already
  /// passed, accounting for a small [clockSkew] tolerance. Returns `false`
  /// when the token is not a JWT / has no `exp` claim (validity not
  /// locally decidable) or when the claim is still in the future.
  static bool isExpired(String? token, {Duration clockSkew = Duration.zero}) {
    final exp = expirationOf(token);
    if (exp == null) {
      return false;
    }
    return DateTime.now().isAfter(exp.subtract(clockSkew));
  }

  /// Decodes and returns the JWT payload claims as a [Map], or `null` when
  /// the token is not a three-part compact JWT or its payload cannot be
  /// base64url-decoded / JSON-parsed.
  static Map<String, dynamic>? _claimsOf(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final payload = _decodeBase64Url(parts[1]);
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on Exception {
      return null;
    }
  }

  /// Decodes a base64url string, re-padding to a multiple of four as
  /// required by [base64Url].
  static String _decodeBase64Url(String encoded) {
    var normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized += '=' * (4 - remainder);
    }
    return utf8.decode(base64.decode(normalized));
  }
}
