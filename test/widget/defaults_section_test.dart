import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/dialogs/settings/defaults_section.dart';
import 'package:pdflibre/l10n/strings.dart';
import 'package:pdflibre/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DefaultsSection — {페이지} 토큰 경고', () {
    testWidgets('기본 규칙(토큰 포함)에서는 경고가 없다', (tester) async {
      final s = S(AppLanguage.en);
      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: DefaultsSection())),
      );
      expect(find.text(s.ruleMissingPageToken), findsNothing);
    });

    testWidgets('분할 규칙에서 {페이지}를 지우면 경고가 나타난다', (tester) async {
      final s = S(AppLanguage.en);
      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: DefaultsSection())),
      );

      // 규칙 필드 순서: 저장 / 분할 / 변환
      await tester.enterText(find.byType(TextField).at(1), '{원본}');
      await tester.pump();
      expect(find.text(s.ruleMissingPageToken), findsOneWidget);
    });

    testWidgets('{페이지}를 다시 넣으면 경고가 사라진다', (tester) async {
      final s = S(AppLanguage.en);
      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: DefaultsSection())),
      );

      await tester.enterText(find.byType(TextField).at(1), '{원본}');
      await tester.pump();
      expect(find.text(s.ruleMissingPageToken), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '{원본}_{페이지}');
      await tester.pump();
      expect(find.text(s.ruleMissingPageToken), findsNothing);
    });

    testWidgets('저장 규칙은 페이지 단위가 아니므로 경고를 띄우지 않는다', (tester) async {
      final s = S(AppLanguage.en);
      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: DefaultsSection())),
      );

      await tester.enterText(find.byType(TextField).at(0), '{원본}만');
      await tester.pump();
      expect(find.text(s.ruleMissingPageToken), findsNothing);
    });
  });
}
