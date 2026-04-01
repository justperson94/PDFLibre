import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pdflibre/app.dart';
import 'package:pdflibre/providers/pdf_provider.dart';

void main() {
  testWidgets('PDFLibre 앱 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PdfProvider(),
        child: const PDFLibreApp(),
      ),
    );
    await tester.pumpAndSettle();

    // EmptyStateScreen이 렌더링되는지 확인
    expect(find.text('PDF 파일을 열어보세요'), findsOneWidget);
  });
}
