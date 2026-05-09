import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static const appName = 'PDFLibre';
  static const supportedFormatHint = '.pdf';

  // Version + build number are populated from pubspec.yaml at startup via
  // [loadVersionInfo]. Fallback values are only visible if loadVersionInfo
  // hasn't run yet.
  static String _appVersion = 'v0.0.0';
  static String _buildNumber = '0';

  static String get appVersion => _appVersion;
  static String get buildNumber => _buildNumber;

  /// Load app version from native package info. Call once during app startup.
  static Future<void> loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    _appVersion = 'v${info.version}';
    _buildNumber = info.buildNumber;
  }

  static const supportedImageFormats = <String>[
    'PNG',
    'JPEG',
    'WebP',
    'TIFF',
    'BMP',
    'GIF',
  ];

  static const defaultFileName = 'document.pdf';
  static const defaultFileSize = '2.4 MB';
  static const defaultPageCount = 12;
}
