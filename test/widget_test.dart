import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pdflibre/app.dart';
import 'package:pdflibre/providers/pdf_provider.dart';

void main() {
  testWidgets('PDFLibre app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PdfProvider(),
        child: const PDFLibreApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify EmptyStateScreen is rendered
    expect(find.text('PDF 파일을 열어보세요'), findsOneWidget);
  });
}
