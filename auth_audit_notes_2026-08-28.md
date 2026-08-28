# Auth audit notes — 2026-08-28

- Backend auth router is `api/v1/auth/router.py`.
- Current user persistence appears to use in-memory `_USERS` in the router; `shared/database.py` only defines SQLAlchemy engine/session/Base and no auth models were shown in the audit output.
- Current routes include register, verify-email, resend-verification, login, google, facebook, refresh, revoke, me, apikeys, and users.
- Current login rejects social-only accounts with an explicit error, checks active/email_verified, verifies password, and issues access/refresh JWTs.
- JWT implementation is HS256 with access TTL 3600 seconds and refresh TTL 30 days; revoked-token store is used.
- Social verification lives in `api/v1/auth/social.py` and verifies Google/Facebook tokens server-side.
- Required production work from pasted_content.txt: durable user/identity/session/token storage, separate email signup/signin, password hashing, email verification and reset flows, OTP expiry/attempt/rate limits, generic anti-enumeration errors, account linking controls, session revocation, audit/security tests, Flutter states, and no secrets in APK/Git.
- Do not implement database migration or destructive changes until schema and existing persistence are fully mapped.
