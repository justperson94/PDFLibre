import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/history_provider.dart';
import 'providers/pdf_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const PDFLibreApp(),
    ),
  );
}
