import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/history_provider.dart';
import 'providers/pdf_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  await AppConstants.loadVersionInfo();
  final settings = SettingsProvider();
  await settings.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const PDFLibreApp(),
    ),
  );
}
