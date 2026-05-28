class AppConstants {
  AppConstants._();

  static const String appName = 'القوافل التعليمية';

  // ── Secure Storage keys ───────────────────────────────────────────────────
  static const String tokenKey           = 'jwt_token';
  static const String nonceKey           = 'wp_nonce';
  static const String userIdKey          = 'user_id';
  static const String userEmailKey       = 'user_email';
  static const String userDisplayNameKey = 'user_display_name';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String videoProgressPrefix = 'video_progress_';

  // ── HTTP ──────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Cache TTL ─────────────────────────────────────────────────────────────
  static const Duration cacheTtl = Duration(minutes: 5);
}
