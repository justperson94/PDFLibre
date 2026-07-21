import 'package:flutter/material.dart';
import 'package:pdflibre/providers/pdf_provider.dart';
import 'package:pdflibre/providers/settings_provider.dart';
import 'package:pdflibre/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// 위젯 테스트 공용 하네스 — 실제 앱과 동일하게 [AppColors] ThemeExtension과
/// [SettingsProvider]를 제공한다 (google_fonts는 네트워크를 쓰므로 제외).
Widget wrapWithApp(
  Widget child, {
  SettingsProvider? settings,
  PdfProvider? pdf,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => settings ?? SettingsProvider()),
      ChangeNotifierProvider(create: (_) => pdf ?? PdfProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData.light(
        useMaterial3: false,
      ).copyWith(extensions: const [AppColors.light]),
      home: child,
    ),
  );
}
