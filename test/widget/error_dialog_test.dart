import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdflibre/dialogs/error_dialog.dart';
import 'package:pdflibre/l10n/strings.dart';
import 'package:pdflibre/providers/settings_provider.dart';
import 'package:pdflibre/theme/app_theme.dart';

import 'test_harness.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showErrorDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('ErrorDialog', () {
    testWidgets('제목/본문/버튼이 표시된다', (tester) async {
      final s = S(AppLanguage.en);
      await openDialog(tester);
      expect(find.text(s.errorDialogTitle), findsOneWidget);
      expect(find.text(s.errorDialogBody), findsOneWidget);
      expect(find.text(s.pickAnotherFile), findsOneWidget);
      expect(find.text(s.confirm), findsOneWidget);
    });

    testWidgets('경고 아이콘은 danger 시맨틱 색을 쓴다', (tester) async {
      await openDialog(tester);
      final icon = tester.widget<Icon>(find.byIcon(LucideIcons.alertTriangle));
      expect(icon.color, AppColors.light.danger);
    });

    testWidgets('확인 버튼으로 닫힌다', (tester) async {
      final s = S(AppLanguage.en);
      await openDialog(tester);
      await tester.tap(find.text(s.confirm));
      await tester.pumpAndSettle();
      expect(find.text(s.errorDialogTitle), findsNothing);
    });
  });
}
