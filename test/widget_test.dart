import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pdflibre/app.dart';
import 'package:pdflibre/providers/history_provider.dart';
import 'package:pdflibre/providers/pdf_provider.dart';
import 'package:pdflibre/providers/settings_provider.dart';

void main() {
  testWidgets('PDFLibre app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PdfProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const PDFLibreApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify EmptyStateScreen is rendered (default language: English)
    expect(find.text('Drop PDF files here'), findsOneWidget);
  });
}
