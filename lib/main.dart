import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/pdf_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  runApp(
    ChangeNotifierProvider(
      create: (_) => PdfProvider(),
      child: const PDFLibreApp(),
    ),
  );
}
