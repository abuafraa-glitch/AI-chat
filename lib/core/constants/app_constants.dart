/// Standard animation and timing durations used across the UI.
///
/// Durations are intentionally short and aligned with Material
/// motion guidelines; the values live here so that all transitions
/// stay in lock-step.
abstract final class AppDurations {
  const AppDurations._();

  /// `150ms` — micro-interactions (button press, ripple).
  static const Duration fast = Duration(milliseconds: 150);

  /// `250ms` — default page transitions and small reveals.
  static const Duration normal = Duration(milliseconds: 250);

  /// `400ms` — emphasised transitions (sheet, dialog).
  static const Duration slow = Duration(milliseconds: 400);

  /// `500ms` — splash-screen minimum display time.
  static const Duration splashMin = Duration(milliseconds: 500);

  /// `300ms` — debounce window for search-as-you-type inputs.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// `500ms` — debounce window for form-field validation.
  static const Duration validationDebounce = Duration(milliseconds: 500);

  /// `1200ms` — toast/snackbar default display time.
  static const Duration toastDisplay = Duration(milliseconds: 1200);

  /// `30s` — interval between automatic background syncs.
  static const Duration backgroundSyncInterval = Duration(seconds: 30);

  /// `5s` — generic retry delay (further strategies live in config).
  static const Duration retryDelay = Duration(seconds: 5);

  /// `2s` — short polling interval for live status checks.
  static const Duration shortPoll = Duration(seconds: 2);

  /// `10s` — long polling interval for background refreshes.
  static const Duration longPoll = Duration(seconds: 10);

  /// `8s` — timeout for the splash bootstrap before forcing exit.
  static const Duration bootstrapTimeout = Duration(seconds: 8);
}

/// Hard limits enforced on user input, file uploads, and caches.
abstract final class AppLimits {
  const AppLimits._();

  /// Maximum number of characters allowed in a chat message.
  static const int maxMessageLength = 4000;

  /// Minimum number of characters required for a chat message.
  static const int minMessageLength = 1;

  /// Maximum number of characters allowed in a conversation title.
  static const int maxConversationTitleLength = 120;

  /// Maximum number of attachments per single message.
  static const int maxAttachmentsPerMessage = 5;

  /// Maximum size in bytes for a single uploaded file (10 MB).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum total size in bytes across all attachments in a message.
  static const int maxTotalAttachmentSizeBytes = 25 * 1024 * 1024;

  /// Minimum length required for account passwords.
  static const int minPasswordLength = 8;

  /// Maximum length accepted for account passwords.
  static const int maxPasswordLength = 128;

  /// Minimum length required for a user display name.
  static const int minDisplayNameLength = 2;

  /// Maximum length accepted for a user display name.
  static const int maxDisplayNameLength = 50;

  /// Maximum number of search results returned in a single page.
  static const int maxSearchResults = 50;

  /// Maximum number of recent conversations cached locally.
  static const int maxRecentConversations = 100;

  /// Maximum number of in-app notifications held in memory.
  static const int maxInMemoryNotifications = 200;
}

/// Responsive design breakpoints (logical pixels).
///
/// The application is laid out for three form factors. A device is
/// considered a tablet when its shortest side is `>= 600` and a
/// desktop when `>= 1024`.
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  /// `600` — minimum width for the tablet layout.
  static const double tablet = 600;

  /// `1024` — minimum width for the desktop layout.
  static const double desktop = 1024;

  /// `1440` — maximum content width on ultra-wide screens.
  static const double maxContentWidth = 1440;

  /// `320` — minimum width the layout must support gracefully.
  static const double minSupportedWidth = 320;
}

/// Pagination defaults surfaced to UI components.
abstract final class AppPagination {
  const AppPagination._();

  /// Default page size used by paginated lists.
  static const int defaultPageSize = 20;

  /// Threshold (in items) that triggers pre-fetching the next page.
  static const int prefetchThreshold = 5;

  /// Maximum page size the UI will request in a single call.
  static const int maxPageSize = 100;

  /// Initial page index — pages are 1-indexed across the platform.
  static const int initialPage = 1;
}

/// Format patterns and string templates used to render values across
/// the application. Patterns are designed for the `intl` package and
/// are easy to swap for locale-specific overrides.
abstract final class AppFormats {
  const AppFormats._();

  /// `yyyy-MM-dd` — ISO calendar date.
  static const String dateIso = 'yyyy-MM-dd';

  /// `dd/MM/yyyy` — regional short date.
  static const String dateShort = 'dd/MM/yyyy';

  /// `MMMM d, yyyy` — long-form display date.
  static const String dateLong = 'MMMM d, yyyy';

  /// `HH:mm` — 24-hour clock time.
  static const String time24 = 'HH:mm';

  /// `h:mm a` — 12-hour clock time with AM/PM.
  static const String time12 = 'h:mm a';

  /// `yyyy-MM-dd'T'HH:mm:ss'Z'` — ISO-8601 timestamp in UTC.
  static const String dateTimeIsoUtc = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  /// `#0.##` — compact decimal (drops trailing zeros).
  static const String decimalCompact = '#0.##';

  /// `#,##0` — grouped thousands integer.
  static const String integerGrouped = '#,##0';

  /// `+### ##########` — international phone format hint.
  static const String phoneInternational = '+### ##########';
}

/// Common layout dimensions that the design system references.
abstract final class AppDimensions {
  const AppDimensions._();

  /// Standard top safe-area inset for full-screen layouts.
  static const double topSafeArea = 0;

  /// Default edge padding for page-level scaffolds.
  static const double pagePadding = 16;

  /// Default edge padding for list/grid items.
  static const double itemPadding = 12;

  /// Default border radius for cards and surfaces.
  static const double cardRadius = 12;

  /// Default border radius for buttons.
  static const double buttonRadius = 8;

  /// Default border radius for input fields.
  static const double inputRadius = 8;

  /// Default elevation for elevated cards.
  static const double cardElevation = 1;

  /// Default elevation for floating action buttons.
  static const double fabElevation = 6;

  /// Stroke width for outlined inputs and dividers.
  static const double strokeWidth = 1;

  /// Touch target minimum size (Material accessibility guideline).
  static const double minTouchTarget = 48;
}
