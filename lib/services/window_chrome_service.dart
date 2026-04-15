import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// macOS 네이티브 창 외형(트래픽 라이트 영역·타이틀바 배경)을 Flutter
/// effective brightness에 맞춰 동기화한다.
///
/// macOS가 아닌 플랫폼에서는 no-op.
class WindowChromeService {
  WindowChromeService._();

  static const _channel = MethodChannel('pdflibre/window_chrome');

  static Future<void> applyBrightness(Brightness brightness) async {
    if (kIsWeb || !Platform.isMacOS) return;
    await _channel.invokeMethod(
      'setBrightness',
      brightness == Brightness.dark ? 'dark' : 'light',
    );
  }
}
