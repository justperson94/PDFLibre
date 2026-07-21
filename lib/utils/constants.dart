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

  // WebP 제외: image 패키지에 WebP 인코더가 없어 실제로는 PNG로 저장되던
  // 허위 표기였음. 진짜 WebP 지원은 인코더 패키지 추가 검토 후 재개.
  static const supportedImageFormats = <String>[
    'PNG',
    'JPEG',
    'TIFF',
    'BMP',
    'GIF',
  ];

  static const defaultFileName = 'document.pdf';
  static const defaultFileSize = '2.4 MB';
  static const defaultPageCount = 12;
}
