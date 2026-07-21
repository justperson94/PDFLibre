import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/dialogs/convert_dialog.dart';
import 'package:pdflibre/l10n/strings.dart';
import 'package:pdflibre/providers/settings_provider.dart';

import 'test_harness.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapWithApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showConvertDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('ConvertDialog', () {
    testWidgets('WebP는 포맷 목록에 없다', (tester) async {
      await openDialog(tester);
      expect(find.text('PNG'), findsOneWidget);
      expect(find.text('JPEG'), findsOneWidget);
      expect(find.text('WebP'), findsNothing);
    });

    testWidgets('품질 슬라이더는 JPEG 선택 시에만 보인다', (tester) async {
      final s = S(AppLanguage.en);
      await openDialog(tester);

      // 기본 선택은 PNG — 품질 슬라이더 없음 (PNG 인코더는 품질 값을 무시).
      expect(find.text(s.quality), findsNothing);
      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.text('JPEG'));
      await tester.pumpAndSettle();
      expect(find.text(s.quality), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.text('PNG'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('커스텀 DPI 필드는 숫자만 받는다', (tester) async {
      final s = S(AppLanguage.en);
      await openDialog(tester);

      // '직접 입력' 칩 선택 → DPI 입력 필드 노출
      await tester.tap(find.text(s.customInput));
      await tester.pumpAndSettle();

      final dpiField = find.byType(TextField).last;
      await tester.enterText(dpiField, 'abc12x');
      await tester.pump();
      expect(
        tester.widget<TextField>(dpiField).controller!.text,
        '12',
        reason: '숫자 이외의 입력은 필터링되어야 한다',
      );
    });
  });
}
