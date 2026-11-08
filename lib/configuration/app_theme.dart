/// The measures shared by every page, so that spacing, corners and controls look the same everywhere.
/// Use these instead of raw numbers in new code.
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal margin of the pages' content
  static const double page = 10;

  /// Space between two sections of a page
  static const double section = 24;
}

class AppRadius {
  static const double s = 12;
  static const double m = 18;
  static const double l = 24;
  static const double xl = 32;

  /// Chat bubbles
  static const double bubble = 22;
  static const double bubbleTail = 6;
}

class AppSizes {
  /// Height of the standard buttons and fields
  static const double control = 52;

  /// Height of search fields, the chat's message field and small buttons
  static const double compactControl = 44;

  /// Square icon buttons
  static const double iconButton = 44;

  static const double icon = 24;
  static const double smallIcon = 18;
  static const double tinyIcon = 14;

  static const double avatarSmall = 36;
  static const double avatar = 50;
  static const double avatarLarge = 100;

  /// Height of the custom bottom navigation bar, without the device's safe area
  static const double bottomBar = 80;

  /// Height of the custom top bars, without the device's safe area
  static const double topBar = 60;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
